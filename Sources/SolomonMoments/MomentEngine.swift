import Foundation
import SolomonCore
import SolomonAnalytics
import SolomonLLM
// LLMOutputValidator e în SolomonLLM

// MARK: - MomentEngine
//
// Service principal care leagă analytics + orchestrator + LLM provider.
// Primește un snapshot din repos → rulează analytics → construiește MomentCandidates
// → folosește MomentOrchestrator pentru selecție prioritară → returnează MomentOutput.

@MainActor
public final class MomentEngine {

    // MARK: - Dependencies

    private let llm: any LLMProvider
    private let orchestrator = MomentOrchestrator()
    private let cashFlowAnalyzer = CashFlowAnalyzer()
    private let subscriptionAuditor = SubscriptionAuditor()
    private let spiralDetector = SpiralDetector()
    private let patternDetector = PatternDetector()
    private let validator = LLMOutputValidator()

    public init(llm: any LLMProvider = MomentEngine.defaultLLMProvider()) {
        self.llm = llm
    }

    /// Provider default: MLX (Gemma 2B real on-device) cu fallback la Template
    /// dacă modelul nu e descărcat sau inferența eșuează.
    public static func defaultLLMProvider() -> any LLMProvider {
        let mlx = MLXLLMProvider(config: .gemmaE2B)
        return SmartLLMProvider(primary: mlx, fallback: TemplateLLMProvider())
    }

    // MARK: - Snapshot

    public struct Snapshot: Sendable {
        public let userProfile: UserProfile?
        public let transactions: [Transaction]
        public let obligations: [Obligation]
        public let subscriptions: [Subscription]
        public let goals: [Goal]
        public let referenceDate: Date

        public init(
            userProfile: UserProfile?,
            transactions: [Transaction],
            obligations: [Obligation],
            subscriptions: [Subscription],
            goals: [Goal],
            referenceDate: Date = Date()
        ) {
            self.userProfile = userProfile
            self.transactions = transactions
            self.obligations = obligations
            self.subscriptions = subscriptions
            self.goals = goals
            self.referenceDate = referenceDate
        }
    }

    // MARK: - Public API

    public func generateBestMoment(snapshot: Snapshot) async throws -> MomentOutput? {
        let candidates = buildCandidates(snapshot: snapshot)
        guard candidates.hasAnyCandidate else { return nil }

        // Prima încercare cu provider-ul curent
        let initial = try await orchestrator.generate(from: candidates, using: llm)

        // Validare §7.3 — dacă eșuează retry cu TemplateLLMProvider (fallback garantat valid)
        let validation = validator.validate(
            output: initial.llmResponse,
            criticalNumbers: [],    // orchestratorul nu expune numerele critice direct; validăm RO + length
            maxWords: 150
        )
        if !validation.passed {
            // Retry cu template safe — garantat RO, fără English bleed
            if let retried = try? await orchestrator.generate(from: candidates, using: TemplateLLMProvider()) {
                return retried
            }
        }

        return initial
    }

    public func selectedType(snapshot: Snapshot) -> MomentType? {
        orchestrator.selectedType(from: buildCandidates(snapshot: snapshot))
    }

    public func generateWowMoment(snapshot: Snapshot) async throws -> MomentOutput {
        let context = buildWowMomentContext(snapshot: snapshot)
        return try await WowMomentBuilder().build(context, using: llm)
    }

    public func generateSubscriptionAudit(snapshot: Snapshot) async throws -> MomentOutput? {
        let audit = subscriptionAuditor.audit(subscriptions: snapshot.subscriptions)
        guard audit.ghostCount > 0 else { return nil }
        let context = buildSubscriptionAuditContext(snapshot: snapshot, audit: audit)
        return try await SubscriptionAuditBuilder().build(context, using: llm)
    }

    public func generateSpiralAlert(snapshot: Snapshot) async throws -> MomentOutput? {
        let cashFlow = cashFlowAnalyzer.analyze(transactions: snapshot.transactions, referenceDate: snapshot.referenceDate)
        let history = computeMonthlyBalanceHistory(snapshot: snapshot, cashFlow: cashFlow)
        let report = spiralDetector.detect(
            transactions: snapshot.transactions,
            obligations: snapshot.obligations,
            monthlyIncomeAvg: cashFlow.monthlyIncomeAvg,
            monthlySpendingAvg: cashFlow.monthlySpendingAvg,
            monthlyBalanceHistory: history,
            referenceDate: snapshot.referenceDate
        )
        guard report.score >= 2 else { return nil }
        let context = buildSpiralAlertContext(snapshot: snapshot, report: report, cashFlow: cashFlow)
        return try await SpiralAlertBuilder().build(context, using: llm)
    }

    // MARK: - Candidate construction

    private func buildCandidates(snapshot: Snapshot) -> MomentCandidates {
        guard !snapshot.transactions.isEmpty else {
            return MomentCandidates(wowMoment: buildWowMomentContext(snapshot: snapshot))
        }

        let cashFlow = cashFlowAnalyzer.analyze(transactions: snapshot.transactions, referenceDate: snapshot.referenceDate)
        let history = computeMonthlyBalanceHistory(snapshot: snapshot, cashFlow: cashFlow)

        // 1. Spiral check
        let spiralReport = spiralDetector.detect(
            transactions: snapshot.transactions,
            obligations: snapshot.obligations,
            monthlyIncomeAvg: cashFlow.monthlyIncomeAvg,
            monthlySpendingAvg: cashFlow.monthlySpendingAvg,
            monthlyBalanceHistory: history,
            referenceDate: snapshot.referenceDate
        )
        let spiralCtx = spiralReport.score >= 2
            ? buildSpiralAlertContext(snapshot: snapshot, report: spiralReport, cashFlow: cashFlow)
            : nil

        // 2. Subscription audit
        let subAudit = subscriptionAuditor.audit(subscriptions: snapshot.subscriptions)
        let subCtx = subAudit.ghostCount > 0
            ? buildSubscriptionAuditContext(snapshot: snapshot, audit: subAudit)
            : nil

        // 3. Payday Magic — salariu mare primit în ultimele 48h
        let paydayCtx = buildPaydayContext(snapshot: snapshot, cashFlow: cashFlow)

        // 4. Upcoming Obligation — obligație care scade în ≤ 5 zile
        let upcomingCtx = buildUpcomingObligationContext(snapshot: snapshot, cashFlow: cashFlow)

        // 5. Pattern Alert — PatternDetector găsește ceva semnificativ
        let patternCtx = buildPatternAlertContext(snapshot: snapshot)

        // 6. Weekly Summary — duminică sau luni
        let weeklyCtx = buildWeeklySummaryContext(snapshot: snapshot, cashFlow: cashFlow)

        // 7. Wow Moment fallback (default)
        let wowCtx = buildWowMomentContext(snapshot: snapshot)

        return MomentCandidates(
            wowMoment: wowCtx,
            payday: paydayCtx,
            upcomingObligation: upcomingCtx,
            patternAlert: patternCtx,
            subscriptionAudit: subCtx,
            spiralAlert: spiralCtx,
            weeklySummary: weeklyCtx
        )
    }

    // MARK: - Payday context builder

    private func buildPaydayContext(snapshot: Snapshot, cashFlow: CashFlowAnalysis) -> PaydayContext? {
        let cal = Calendar.current
        let now = snapshot.referenceDate
        guard let cutoff = cal.date(byAdding: .hour, value: -48, to: now) else { return nil }

        // FAZA B6: prag relativ la venitul declarat în profil. Hardcoded "≥1000 RON"
        // declanșa Payday Magic la transferuri primite de la prieteni. Acum cerem
        // ≥ 70% din salariul mid-point declarat (sau ≥ 70% din avgIncome) — astfel
        // un transfer de 1.500 RON nu e confundat cu salariul de 8.000 RON.
        let avgIncomeAmount = cashFlow.monthlyIncomeAvg.amount
        let declaredMid = snapshot.userProfile?.financials.salaryRange.midpointRON ?? 0
        let referenceIncome = max(avgIncomeAmount, declaredMid)
        // Praguri:
        //   - dacă avem un reference income, cerem ≥70% din el
        //   - altfel fallback la 1500 RON (ridicat de la 1000 ca să taie zgomot mai bine)
        let minSalaryRON: Int = referenceIncome > 0 ? Int(Double(referenceIncome) * 0.70) : 1500

        let recentIncoming = snapshot.transactions
            .filter { $0.isIncoming && $0.date >= cutoff && $0.amount.amount >= minSalaryRON }
            .sorted { $0.amount.amount > $1.amount.amount }
            .first

        guard let salaryTx = recentIncoming else { return nil }

        let received = salaryTx.amount.amount
        let isHigher = avgIncomeAmount > 0 && Double(received) > Double(avgIncomeAmount) * 1.10
        let isLower  = avgIncomeAmount > 0 && Double(received) < Double(avgIncomeAmount) * 0.90

        let salary = PaydaySalary(
            amountReceived: salaryTx.amount,
            receivedDate: salaryTx.date,
            source: salaryTx.merchant ?? "Angajator",
            isHigherThanAverage: isHigher,
            isLowerThanAverage: isLower
        )

        let paydayDay = paydayDayOfMonth(snapshot: snapshot)
        let daysUntilNext = daysUntilDayOfMonth(paydayDay, from: now)

        let obligations = snapshot.obligations
        let obligReserves = obligations.map { o in
            PaydayObligationReserve(name: o.name, amount: o.amount, status: .rezervat)
        }
        let obligTotal = obligations.reduce(Money(0)) { $0 + $1.amount }

        let activeSubs = snapshot.subscriptions.filter { !$0.isGhost }
        let subReserves = activeSubs.prefix(5).map { s in
            PaydaySubscriptionReserve(name: s.name, amount: s.amountMonthly)
        }
        let subTotal = activeSubs.reduce(Money(0)) { $0 + $1.amountMonthly }

        let available = Money(max(0, received - obligTotal.amount - subTotal.amount))
        let perDay = daysUntilNext > 0 ? Money(available.amount / daysUntilNext) : Money(0)

        let allocation = PaydayAllocation(
            obligationsReserved: obligReserves,
            subscriptionsReserved: Array(subReserves),
            obligationsTotal: obligTotal,
            subscriptionsTotal: subTotal,
            savingsAuto: PaydaySavingsAuto(enabled: false),
            availableToSpend: available,
            daysUntilNextPayday: daysUntilNext,
            availablePerDay: perDay
        )

        // FAZA B7: comparație SIMETRICĂ — folosim DOAR tranzacțiile lunii precedente,
        // fără să mai scădem obligTotal/subTotal-urile CURENȚI (bug original) care
        // creau o comparație asimetrică artificială. Tranzacțiile recurente apar
        // deja în prevOutgoing dacă au fost într-adevăr plătite luna trecută.
        let lastMonthAvailable: Money = {
            let cal = Calendar.current
            let now = snapshot.referenceDate
            guard let prevMonthStart = cal.date(byAdding: .month, value: -1, to:
                    cal.date(from: cal.dateComponents([.year, .month], from: now)) ?? now),
                  let prevMonthEnd = cal.date(byAdding: .month, value: 1, to: prevMonthStart)
            else { return available }

            let prevIncoming = snapshot.transactions
                .filter { $0.isIncoming && $0.date >= prevMonthStart && $0.date < prevMonthEnd }
                .reduce(0) { $0 + $1.amount.amount }
            let prevOutgoing = snapshot.transactions
                .filter { $0.isOutgoing && $0.date >= prevMonthStart && $0.date < prevMonthEnd }
                .reduce(0) { $0 + $1.amount.amount }
            let prevBalance = prevIncoming - prevOutgoing
            return Money(max(0, prevBalance))
        }()

        let rawDiff = available.amount - lastMonthAvailable.amount
        let direction: ComparisonDirection
        switch rawDiff {
        case 100...:    direction = .better
        case ..<(-100): direction = .worse
        default:        direction = .same
        }

        let comparisons = PaydayComparisons(
            vsLastMonthAvailable: lastMonthAvailable,
            vsLastMonthDiff: Money(abs(rawDiff)),
            vsLastMonthDirection: direction
        )

        let budgets = cashFlow.spendingByCategory
            .sorted { $0.value.amount > $1.value.amount }
            .prefix(3)
            .map { (cat, amt) in CategoryBudgetSuggestion(category: cat, amount: amt, basedOn: .average) }

        var warnings: [PaydayWarning] = []
        let oblRatio = avgIncomeAmount > 0 ? Double(obligTotal.amount) / Double(avgIncomeAmount) : 0
        if oblRatio > 0.5 {
            warnings.append(PaydayWarning(
                type: .obligationsTooHigh,
                description: "Obligațiile reprezintă \(Int(oblRatio * 100))% din venit",
                impact: "Rămân \(available.amount) RON disponibil"
            ))
        }
        if available.amount < 500 {
            warnings.append(PaydayWarning(
                type: .lowAvailable,
                description: "Suma disponibilă după obligații: \(available.amount) RON",
                impact: "≈ \(perDay.amount) RON/zi"
            ))
        }

        return PaydayContext(
            user: buildMomentUser(snapshot: snapshot),
            salary: salary,
            autoAllocation: allocation,
            comparisons: comparisons,
            categoryBudgetsSuggested: Array(budgets),
            warnings: warnings
        )
    }

    // MARK: - Upcoming Obligation context builder

    private func buildUpcomingObligationContext(snapshot: Snapshot, cashFlow: CashFlowAnalysis) -> UpcomingObligationContext? {
        let cal = Calendar.current
        let now = snapshot.referenceDate
        let today = cal.component(.day, from: now)

        // Obligație care scade în 1–5 zile
        let candidate = snapshot.obligations.compactMap { o -> (Obligation, Int)? in
            var days = o.dayOfMonth - today
            if days <= 0 {
                let daysInMonth = cal.range(of: .day, in: .month, for: now)?.count ?? 30
                days = daysInMonth - today + o.dayOfMonth
            }
            return days >= 1 && days <= 5 ? (o, days) : nil
        }.sorted { $0.1 < $1.1 }.first

        guard let (obligation, daysUntil) = candidate else { return nil }

        let dueDate = cal.date(byAdding: .day, value: daysUntil, to: now) ?? now

        // Sold estimat curent: venit mediu – cheltuieli luna aceasta
        let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: now)) ?? now
        let spentThisMonth = snapshot.transactions
            .filter { $0.isOutgoing && $0.date >= monthStart }
            .reduce(0) { $0 + $1.amount.amount }
        let currentBalance = Money(max(0, cashFlow.monthlyIncomeAvg.amount - spentThisMonth))
        let afterPayment = Money(max(0, currentBalance.amount - obligation.amount.amount))

        let paydayDay = paydayDayOfMonth(snapshot: snapshot)
        let daysUntilPayday = daysUntilDayOfMonth(paydayDay, from: now)
        let perDayAfter = daysUntilPayday > 0 ? Money(afterPayment.amount / daysUntilPayday) : Money(0)

        let isTight = afterPayment.amount < 500
        let isAffordable = currentBalance.amount >= obligation.amount.amount
        let tone: AssessmentTone = !isAffordable ? .urgent : isTight ? .alert : daysUntil <= 1 ? .calm : .reassuring

        let upcomingItem = UpcomingObligationItem(
            name: obligation.name,
            amountEstimated: obligation.amount,
            dueDate: dueDate,
            daysUntilDue: daysUntil,
            amountEstimationConfidence: .high,
            basedOnHistory: "Obligație fixă lunară"
        )

        let cashCtx = UpcomingObligationCashContext(
            currentBalance: currentBalance,
            afterPayment: afterPayment,
            daysUntilNextPayday: daysUntilPayday,
            availablePerDayAfter: perDayAfter
        )

        let assessment = UpcomingObligationAssessment(isAffordable: isAffordable, isTight: isTight, tone: tone)

        let weekday = cal.component(.weekday, from: dueDate)
        let isWeekend = weekday == 1 || weekday == 7
        let weekendAvg = Money(cashFlow.monthlySpendingAvg.amount / 14) // rough 2-day estimate
        let weekendWarning = WeekendWarning(
            isWeekendComing: isWeekend,
            weekendAvgSpend: weekendAvg,
            wouldCreateProblem: isWeekend && isTight
        )

        return UpcomingObligationContext(
            user: buildMomentUser(snapshot: snapshot),
            upcoming: upcomingItem,
            context: cashCtx,
            assessment: assessment,
            weekendWarning: weekendWarning
        )
    }

    // MARK: - Pattern Alert context builder

    private func buildPatternAlertContext(snapshot: Snapshot) -> PatternAlertContext? {
        guard snapshot.transactions.count >= 10 else { return nil }

        let report = patternDetector.detect(
            transactions: snapshot.transactions,
            referenceDate: snapshot.referenceDate
        )

        // Priority: frequencySpike > weekendSpike > temporalCluster
        if let spike = report.frequencySpikes.first {
            let pattern = PatternDetected(
                category: spike.category,
                merchantDominant: spike.merchantDominant,
                type: .frequencySpike,
                description: spike.description,
                amountPeriod: spike.amountLast7Days,
                amountProjectedMonthly: spike.monthlyProjection,
                vsBudget: spike.monthlyProjection,
                vsBudgetPct: 0,
                temporalConcentration: TemporalConcentration(isTemporal: false, pattern: "", interpretation: "")
            )
            return PatternAlertContext(
                user: buildMomentUser(snapshot: snapshot),
                patternDetected: pattern,
                scenarios: buildPatternScenarios(for: pattern),
                toneCalibration: .warmNoJudgment
            )
        }

        if report.weekendSpike.isSignificant {
            let pct = Int((report.weekendSpike.ratio - 1.0) * 100)
            let pattern = PatternDetected(
                category: .entertainment,
                merchantDominant: nil,
                type: .weekendSpike,
                description: "Cheltuielile din weekend sunt de \(String(format: "%.1f", report.weekendSpike.ratio))x mai mari decât în zilele de lucru",
                amountPeriod: Money(report.weekendSpike.weekendAvgPerDay.amount * 8),
                amountProjectedMonthly: Money(report.weekendSpike.weekendAvgPerDay.amount * 8),
                vsBudget: report.weekendSpike.weekdayAvgPerDay,
                vsBudgetPct: pct,
                temporalConcentration: TemporalConcentration(
                    isTemporal: true,
                    pattern: "Weekend (sâmbătă–duminică)",
                    interpretation: "Cheltuielile se concentrează în weekend"
                )
            )
            return PatternAlertContext(
                user: buildMomentUser(snapshot: snapshot),
                patternDetected: pattern,
                scenarios: buildPatternScenarios(for: pattern),
                toneCalibration: .curiousReflective
            )
        }

        if let cluster = report.temporalClusters.first(where: { $0.isStrong }) {
            let catSpending = report.topCategories.first(where: { $0.category == cluster.category })
            let monthlyEstimate = catSpending.map { Money($0.totalAmount.amount / 3) } ?? Money(0)
            let pattern = PatternDetected(
                category: cluster.category,
                merchantDominant: catSpending?.dominantMerchant,
                type: .temporalClustering,
                description: cluster.description,
                amountPeriod: catSpending?.totalAmount ?? Money(0),
                amountProjectedMonthly: monthlyEstimate,
                vsBudget: Money(0),
                vsBudgetPct: 0,
                temporalConcentration: TemporalConcentration(
                    isTemporal: true,
                    pattern: cluster.description,
                    interpretation: "Pattern temporal consistent în ultimele 3 luni"
                )
            )
            return PatternAlertContext(
                user: buildMomentUser(snapshot: snapshot),
                patternDetected: pattern,
                scenarios: buildPatternScenarios(for: pattern),
                toneCalibration: .curiousReflective
            )
        }

        return nil
    }

    private func buildPatternScenarios(for pattern: PatternDetected) -> [PatternScenario] {
        let monthly = pattern.amountProjectedMonthly.amount
        let saving = max(0, monthly / 4)
        return [
            PatternScenario(
                scenarioId: .continueAsIs,
                description: "Continuă ca acum",
                monthEndOutcome: "Cheltuiești ~\(monthly) RON/lună pe \(pattern.category.displayNameRO)",
                goalImpact: "Impact neutru față de obiectivele actuale"
            ),
            PatternScenario(
                scenarioId: .reduce2PerWeek,
                description: "Reduce cu 2 vizite pe săptămână",
                monthEndOutcome: "Economisești ~\(saving) RON/lună",
                goalImpact: "Progres mai rapid spre obiective"
            )
        ]
    }

    // MARK: - Weekly Summary context builder

    private func buildWeeklySummaryContext(snapshot: Snapshot, cashFlow: CashFlowAnalysis) -> WeeklySummaryContext? {
        let cal = Calendar.current
        let now = snapshot.referenceDate
        let weekday = cal.component(.weekday, from: now) // 1=Sun, 2=Mon

        // Disponibil duminică (1) sau luni (2)
        guard weekday == 1 || weekday == 2 else { return nil }

        // Săptămâna curentă (luni–duminică)
        let weekAgo = cal.date(byAdding: .day, value: -7, to: now) ?? now
        let weekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: weekAgo)) ?? weekAgo
        let weekEnd = cal.date(byAdding: .day, value: 6, to: weekStart) ?? now

        let weekTxs = snapshot.transactions.filter { $0.isOutgoing && $0.date >= weekStart && $0.date <= weekEnd }
        let weekTotal = weekTxs.reduce(0) { $0 + $1.amount.amount }
        let weeklyAvg = cashFlow.monthlySpendingAvg.amount / 4
        let diff = weekTotal - weeklyAvg
        let diffPct = weeklyAvg > 0 ? Int(Double(abs(diff)) / Double(weeklyAvg) * 100) : 0
        let direction: SpendingTrendDirection
        switch diff {
        case ..<(-100):  direction = .below
        case (-100)..<(-20): direction = .slightlyBelow
        case (-20)...20: direction = .onAverage
        case 21...100:  direction = .slightlyAbove
        default:        direction = .above
        }

        let spending = WeeklySpendingBlock(
            total: Money(weekTotal),
            vsWeeklyAvg: Money(weeklyAvg),
            diffPct: diffPct,
            direction: direction
        )

        // Highlights
        var highlights: [WeeklyHighlight] = []
        if let biggestTx = weekTxs.max(by: { $0.amount.amount < $1.amount.amount }) {
            highlights.append(WeeklyHighlight(
                type: .biggestExpense,
                category: biggestTx.category,
                amount: biggestTx.amount,
                context: "Cea mai mare cheltuială: \(biggestTx.merchant ?? biggestTx.category.displayNameRO)"
            ))
        }
        if direction == .below || direction == .slightlyBelow {
            highlights.append(WeeklyHighlight(
                type: .budgetKept,
                context: "Ai cheltuit cu \(diffPct)% mai puțin decât media săptămânală"
            ))
        }
        let hasNoIFN = !snapshot.obligations.contains { $0.kind == .loanIFN }
        if hasNoIFN {
            highlights.append(WeeklyHighlight(
                type: .noIFNNoBNPLTemptation,
                context: "Nicio cheltuială IFN sau BNPL detectată"
            ))
        }

        // Preview săptămână viitoare
        let nextWeekStart = cal.date(byAdding: .day, value: 1, to: weekEnd) ?? now
        let nextWeekEnd = cal.date(byAdding: .day, value: 7, to: nextWeekStart) ?? now
        let nextWeekObligations: [UpcomingObligationRef] = snapshot.obligations.compactMap { o in
            var d = DateComponents()
            d.day = o.dayOfMonth
            d.month = cal.component(.month, from: nextWeekStart)
            d.year = cal.component(.year, from: nextWeekStart)
            guard let dueDate = cal.date(from: d),
                  dueDate >= nextWeekStart && dueDate <= nextWeekEnd else { return nil }
            let dayName = RomanianDateFormatter.weekdayName(cal.component(.weekday, from: dueDate))
            return UpcomingObligationRef(name: o.name, amount: o.amount, day: dayName)
        }

        let nextWeekPreview = NextWeekPreview(
            obligationsDue: nextWeekObligations,
            eventsInCalendar: []
        )

        // Small win
        let smallWin: SmallWin
        if direction == .below {
            smallWin = SmallWin(exists: true, description: "Ai economisit \(abs(diff)) RON față de media ta săptămânală!")
        } else if hasNoIFN && weekTotal < weeklyAvg {
            smallWin = SmallWin(exists: true, description: "Niciun credit scump și cheltuieli sub medie — bine gestionat!")
        } else {
            smallWin = SmallWin(exists: false)
        }

        let weekNumber = cal.component(.weekOfYear, from: weekAgo)
        let week = WeekRange(start: weekStart, end: weekEnd, weekNumber: weekNumber)

        return WeeklySummaryContext(
            user: buildMomentUser(snapshot: snapshot),
            week: week,
            spending: spending,
            highlights: highlights,
            nextWeekPreview: nextWeekPreview,
            smallWin: smallWin
        )
    }

    // MARK: - Payday day helper

    private func paydayDayOfMonth(snapshot: Snapshot) -> Int {
        guard let p = snapshot.userProfile else { return 28 }
        switch p.financials.salaryFrequency {
        case .monthly(let day): return day
        case .bimonthly(_, let secondDay): return secondDay
        case .variable: return 28
        }
    }

    private func daysUntilDayOfMonth(_ targetDay: Int, from date: Date) -> Int {
        let cal = Calendar.current
        let today = cal.component(.day, from: date)
        if targetDay > today {
            return targetDay - today
        } else {
            let daysInMonth = cal.range(of: .day, in: .month, for: date)?.count ?? 30
            return daysInMonth - today + targetDay
        }
    }

    // MARK: - Context builders

    private func buildMomentUser(snapshot: Snapshot) -> MomentUser {
        let p = snapshot.userProfile?.demographics
        return MomentUser(
            name: p?.name ?? "prietene",
            addressing: p?.addressing ?? .tu,
            ageRange: p?.ageRange
        )
    }

    private func buildSubscriptionAuditContext(snapshot: Snapshot, audit: SubscriptionAuditReport? = nil) -> SubscriptionAuditContext {
        let report = audit ?? subscriptionAuditor.audit(subscriptions: snapshot.subscriptions)

        let ghosts: [GhostSubscriptionDetail] = report.ghostSubscriptions.map { sub in
            GhostSubscriptionDetail(
                name: sub.name,
                amountMonthly: sub.amountMonthly,
                amountAnnual: sub.amountAnnual,
                lastUsedDaysAgo: sub.lastUsedDaysAgo ?? 0,
                cancellationDifficulty: sub.cancellationDifficulty,
                cancellationUrl: sub.cancellationUrl,
                cancellationStepsSummary: sub.cancellationStepsSummary,
                cancellationWarning: sub.cancellationWarning,
                alternativeSuggestion: sub.alternativeSuggestion
            )
        }

        let totals = SubscriptionAuditTotals(
            monthlyRecoverable: report.monthlyRecoverable,
            annualRecoverable: report.annualRecoverable,
            contextComparison: "≈ \(report.annualRecoverable.amount) RON pe an"
        )

        let kept = ActiveSubscriptionsKept(
            count: report.activeSubscriptions.count,
            monthlyTotal: report.monthlyKeptTotal,
            examples: Array(report.activeSubscriptions.prefix(3).map { $0.name })
        )

        return SubscriptionAuditContext(
            user: buildMomentUser(snapshot: snapshot),
            auditPeriodDays: 30,
            ghostSubscriptions: ghosts,
            totals: totals,
            activeSubscriptionsKept: kept
        )
    }

    private func buildSpiralAlertContext(snapshot: Snapshot, report: SpiralReport, cashFlow: CashFlowAnalysis) -> SpiralAlertContext {
        let audit = subscriptionAuditor.audit(subscriptions: snapshot.subscriptions)

        // Step 1: anulează cel mai mare ghost
        let step1: RecoveryStep
        if let firstGhost = audit.ghostSubscriptions.first {
            step1 = RecoveryStep(
                action: "Anulează \(firstGhost.name) (\(firstGhost.amountMonthly.amount) RON/lună)",
                monthlySaving: firstGhost.amountMonthly,
                potentialSaving: "\(firstGhost.amountAnnual.amount) RON/an",
                complexity: .easy,
                tool: nil
            )
        } else {
            step1 = RecoveryStep(
                action: "Identifică cel mai mare abonament nefolosit",
                complexity: .easy
            )
        }

        // Step 2: reducere top categorie cheltuieli
        let topCategory = cashFlow.spendingByCategory.max { $0.value < $1.value }
        let step2: RecoveryStep
        if let (cat, amount) = topCategory, amount.amount > 100 {
            let target = amount.amount / 3 // 33% reducere
            step2 = RecoveryStep(
                action: "Reduce cheltuielile pe \(cat.displayNameRO) cu 33% (~\(target) RON/lună)",
                monthlySaving: Money(target),
                complexity: .medium,
                tool: nil
            )
        } else {
            step2 = RecoveryStep(
                action: "Stabilește un buget zilnic clar pentru cheltuieli discreționare",
                complexity: .medium
            )
        }

        // Step 3: CSALB / consolidare dacă e cazul
        let csalbRelevant = report.severity >= .high &&
            (snapshot.obligations.contains { $0.kind == .loanIFN || $0.kind == .bnpl })
        let step3: RecoveryStep
        if csalbRelevant {
            step3 = RecoveryStep(
                action: "Trimite cazul la CSALB pentru mediere gratuită cu IFN/banca",
                complexity: .hard,
                tool: .csalb
            )
        } else {
            step3 = RecoveryStep(
                action: "Construiește un fond de urgență de 3 luni cheltuieli",
                complexity: .hard,
                tool: nil
            )
        }

        let plan = RecoveryPlan(step1: step1, step2: step2, step3: step3)

        return SpiralAlertContext(
            user: buildMomentUser(snapshot: snapshot),
            spiralScore: report.score,
            severity: report.severity,
            factorsDetected: report.factors,
            narrativeSummary: spiralNarrative(report: report, cashFlow: cashFlow),
            interventionNeeded: report.requiresIntervention,
            csalbRelevant: csalbRelevant,
            recoveryPlan: plan
        )
    }

    // MARK: - WowMomentContext — entry point

    private func buildWowMomentContext(snapshot: Snapshot) -> WowMomentContext {
        let cashFlow: CashFlowAnalysis = snapshot.transactions.isEmpty
            ? CashFlowAnalyzer.empty(windowDays: 180)
            : cashFlowAnalyzer.analyze(
                transactions: snapshot.transactions,
                referenceDate: snapshot.referenceDate
            )
        let history = computeMonthlyBalanceHistory(snapshot: snapshot, cashFlow: cashFlow)
        let audit = subscriptionAuditor.audit(subscriptions: snapshot.subscriptions)
        let spiralReport = spiralDetector.detect(
            transactions: snapshot.transactions,
            obligations: snapshot.obligations,
            monthlyIncomeAvg: cashFlow.monthlyIncomeAvg,
            monthlySpendingAvg: cashFlow.monthlySpendingAvg,
            monthlyBalanceHistory: history,
            referenceDate: snapshot.referenceDate
        )
        let obligationsRatio = cashFlow.monthlyIncomeAvg.amount > 0
            ? Double(snapshot.obligations.reduce(0) { $0 + $1.amount.amount }) / Double(cashFlow.monthlyIncomeAvg.amount)
            : 0

        return WowMomentContext(
            user: buildMomentUser(snapshot: snapshot),
            analysisPeriodDays: cashFlow.windowDays,
            income: wowIncomeBlock(snapshot: snapshot, cashFlow: cashFlow),
            spending: wowSpendingBlock(snapshot: snapshot, cashFlow: cashFlow, history: history),
            outliers: wowOutliersBlock(snapshot: snapshot, cashFlow: cashFlow),
            patterns: wowPatternsBlock(snapshot: snapshot),
            obligations: wowObligationsBlock(snapshot: snapshot, cashFlow: cashFlow, ratio: obligationsRatio),
            ghostSubscriptions: wowGhostSubscriptionsBlock(audit: audit),
            positives: wowPositiveItems(snapshot: snapshot, audit: audit, obligationsRatio: obligationsRatio),
            goal: wowGoalBlock(snapshot: snapshot),
            spiralRisk: SpiralBlock(score: spiralReport.score, severity: spiralReport.severity, factors: spiralReport.factors),
            nextActionSuggested: wowNextAction(audit: audit, spiralReport: spiralReport)
        )
    }

    // MARK: - WowMomentContext helpers

    private func wowIncomeBlock(snapshot: Snapshot, cashFlow: CashFlowAnalysis) -> WowIncome {
        let lowest: LowestMonth = cashFlow.monthlyIncomeLowest.map { mp in
            LowestMonth(amount: mp.amount, month: monthName(year: mp.key.year, month: mp.key.month))
        } ?? LowestMonth(amount: cashFlow.monthlyIncomeAvg, month: "necunoscută")
        return WowIncome(
            monthlyAvg: cashFlow.monthlyIncomeAvg,
            stability: incomeStabilityFromTrend(cashFlow.monthlyBalanceTrend),
            lowestMonth: lowest,
            extraIncomeDetected: snapshot.userProfile?.financials.hasSecondaryIncome ?? false,
            extraIncomeAvg: snapshot.userProfile?.financials.secondaryIncomeAvg
        )
    }

    private func wowSpendingBlock(snapshot: Snapshot, cashFlow: CashFlowAnalysis, history: [Money]) -> WowSpending {
        let cardCreditUsed: Bool = {
            let hasLoan = snapshot.obligations.contains { $0.kind == .loanBank }
            let hasCreditMerchant = snapshot.transactions.contains { tx in
                guard let m = tx.merchant?.lowercased() else { return false }
                return m.contains("credit") || m.contains("card")
            }
            return hasLoan || hasCreditMerchant
        }()
        let overdraftUsedCount180d: Int = {
            var running = 0
            var count = 0
            for monthly in history.suffix(6) {
                running += monthly.amount
                if running < 0 { count += 1 }
            }
            return count
        }()
        return WowSpending(
            monthlyAvg: cashFlow.monthlySpendingAvg,
            incomeConsumptionRatio: cashFlow.incomeConsumptionRatio,
            monthlyBalanceTrend: cashFlow.monthlyBalanceTrend,
            cardCreditUsed: cardCreditUsed,
            overdraftUsedCount180d: overdraftUsedCount180d
        )
    }

    private func wowOutliersBlock(snapshot: Snapshot, cashFlow: CashFlowAnalysis) -> [OutlierItem] {
        let cal = Calendar.current
        let cutoff = cal.date(byAdding: .day, value: -180, to: snapshot.referenceDate) ?? snapshot.referenceDate
        let threshold = cashFlow.monthlySpendingAvg.amount > 0 ? cashFlow.monthlySpendingAvg.amount / 3 : 500
        return snapshot.transactions
            .filter { $0.isOutgoing && $0.date >= cutoff && $0.amount.amount >= threshold }
            .sorted { $0.amount.amount > $1.amount.amount }
            .prefix(3)
            .enumerated()
            .map { idx, tx in
                OutlierItem(
                    rank: idx + 1,
                    type: .singleLargePurchase,
                    category: tx.category,
                    merchant: tx.merchant,
                    amount: tx.amount,
                    date: tx.date,
                    contextPhrase: "\(tx.merchant ?? tx.category.displayNameRO) — \(tx.amount.amount) RON",
                    contextComparison: ""
                )
            }
    }

    private func wowPatternsBlock(snapshot: Snapshot) -> [PatternItem] {
        guard snapshot.transactions.count >= 10 else { return [] }
        let report = patternDetector.detect(
            transactions: snapshot.transactions,
            referenceDate: snapshot.referenceDate
        )
        var items: [PatternItem] = []
        if report.weekendSpike.isSignificant {
            items.append(PatternItem(
                type: .weekendSpike,
                description: "Cheltuielile din weekend sunt de \(String(format: "%.1f", report.weekendSpike.ratio))x mai mari",
                interpretation: "Posibil stil de viață weekend intensiv",
                averageWeekendSpend: report.weekendSpike.weekendAvgPerDay,
                averageWeekdaySpend: report.weekendSpike.weekdayAvgPerDay,
                ratio: report.weekendSpike.ratio
            ))
        }
        for spike in report.frequencySpikes.prefix(2) {
            items.append(PatternItem(
                type: .frequencySpike,
                category: spike.category,
                description: spike.description,
                interpretation: "Frecvență crescută față de media personală"
            ))
        }
        if let cluster = report.temporalClusters.first(where: { $0.isStrong }) {
            items.append(PatternItem(
                type: .temporalClustering,
                category: cluster.category,
                description: cluster.description,
                interpretation: "Pattern temporal repetat în ultimele 3 luni"
            ))
        }
        return items
    }

    private func wowObligationsBlock(snapshot: Snapshot, cashFlow: CashFlowAnalysis, ratio: Double) -> ObligationsBlock {
        let total = snapshot.obligations.reduce(Money(0)) { $0 + $1.amount }
        let items = snapshot.obligations.prefix(8).map {
            ObligationSummaryItem(name: $0.name, amount: $0.amount, dayOfMonth: $0.dayOfMonth)
        }
        return ObligationsBlock(
            monthlyTotalFixed: total,
            items: Array(items),
            obligationsToIncomeRatio: ratio
        )
    }

    private func wowGhostSubscriptionsBlock(audit: SubscriptionAuditReport) -> GhostSubscriptionsBlock {
        GhostSubscriptionsBlock(
            count: audit.ghostCount,
            monthlyTotal: audit.monthlyRecoverable,
            annualTotal: audit.annualRecoverable,
            items: audit.ghostSubscriptions.prefix(5).map { sub in
                GhostSubscriptionItem(
                    name: sub.name,
                    amount: sub.amountMonthly,
                    lastUsedDaysAgo: sub.lastUsedDaysAgo ?? 0,
                    confidence: sub.ghostConfidence
                )
            }
        )
    }

    private func wowPositiveItems(snapshot: Snapshot, audit: SubscriptionAuditReport, obligationsRatio: Double) -> [PositiveItem] {
        var positives: [PositiveItem] = []
        if !snapshot.obligations.contains(where: { $0.kind == .loanIFN }) {
            positives.append(PositiveItem(type: .noIFN, description: "Niciun credit IFN activ"))
        }
        if obligationsRatio > 0 && obligationsRatio < 0.3 {
            positives.append(PositiveItem(type: .rentToIncomeHealthy, description: "Obligațiile sunt sub 30% din venit"))
        }
        if audit.monthlyKeptTotal.amount < 200 {
            positives.append(PositiveItem(type: .lowSubscriptions, description: "Abonamente sub 200 RON/lună"))
        }
        return positives
    }

    private func wowGoalBlock(snapshot: Snapshot) -> GoalBlock {
        let goal = snapshot.goals.first
        return GoalBlock(
            declared: goal != nil,
            type: goal?.kind,
            destination: goal?.destination,
            amountTarget: goal?.amountTarget,
            amountSaved: goal?.amountSaved
        )
    }

    private func wowNextAction(audit: SubscriptionAuditReport, spiralReport: SpiralReport) -> NextActionSuggestion {
        if audit.ghostCount > 0 {
            return NextActionSuggestion(
                type: .cancelGhostSubscriptions,
                rationale: "Anulând cele \(audit.ghostCount) abonamente fantomă recuperezi \(audit.monthlyRecoverable.amount) RON/lună",
                monthlySaving: audit.monthlyRecoverable,
                annualSaving: audit.annualRecoverable
            )
        }
        if spiralReport.severity >= .high {
            return NextActionSuggestion(
                type: .talkToCSALB,
                rationale: "Severitate spirală ridicată — CSALB poate media gratuit",
                monthlySaving: nil,
                annualSaving: nil
            )
        }
        return NextActionSuggestion(
            type: .noActionNeeded,
            rationale: "Totul arată bine pentru momentul curent",
            monthlySaving: nil,
            annualSaving: nil
        )
    }

    // MARK: - Helpers

    /// Calculează istoricul cumulat de sold lunar (pentru SpiralDetector).
    /// Aproximare: pentru fiecare lună, sumă incoming - sumă outgoing.
    private func computeMonthlyBalanceHistory(snapshot: Snapshot, cashFlow: CashFlowAnalysis) -> [Money] {
        let cal = Calendar.current
        var byMonth: [String: Int] = [:]
        for tx in snapshot.transactions {
            let key = "\(cal.component(.year, from: tx.date))-\(cal.component(.month, from: tx.date))"
            let signed = tx.isOutgoing ? -tx.amount.amount : tx.amount.amount
            byMonth[key, default: 0] += signed
        }
        // Sort cronologic
        let sortedKeys = byMonth.keys.sorted()
        return sortedKeys.map { Money(byMonth[$0] ?? 0) }
    }

    private func incomeStabilityFromTrend(_ trend: BalanceTrend) -> IncomeStability {
        switch trend {
        case .healthy:           return .stable
        case .breakingEven, .barelyBreakeven: return .slightlyVariable
        case .slidingNegative:   return .variable
        case .negative:          return .unstable
        }
    }

    private func monthName(year: Int, month: Int) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ro_RO")
        f.dateFormat = "LLLL"
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        if let date = Calendar.current.date(from: comps) {
            return f.string(from: date).lowercased()
        }
        return "necunoscută"
    }

    private func spiralNarrative(report: SpiralReport, cashFlow: CashFlowAnalysis) -> String {
        if report.factors.contains(where: { $0.factor == .balanceDeclining }) {
            return "Soldul tău scade lună de lună. Pierdere medie: \(abs(cashFlow.monthlySavingsAvg.amount)) RON/lună."
        }
        if report.factors.contains(where: { $0.factor == .ifnActive }) {
            return "Ai unul sau mai multe credite IFN active care îți afectează bugetul lunar."
        }
        if report.factors.contains(where: { $0.factor == .obligationsExceedIncome }) {
            return "Obligațiile lunare depășesc venitul. Bugetul nu se închide pe lună."
        }
        return "Solomon a detectat semne de presiune financiară."
    }
}
