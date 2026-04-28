import Foundation
import SolomonCore
import SolomonAnalytics
import SolomonLLM

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

    public init(llm: any LLMProvider = TemplateLLMProvider()) {
        self.llm = llm
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
        return try await orchestrator.generate(from: candidates, using: llm)
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

        // 3. Wow Moment fallback (default)
        let wowCtx = buildWowMomentContext(snapshot: snapshot)

        return MomentCandidates(
            wowMoment: wowCtx,
            subscriptionAudit: subCtx,
            spiralAlert: spiralCtx
        )
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

    private func buildWowMomentContext(snapshot: Snapshot) -> WowMomentContext {
        let cashFlow: CashFlowAnalysis = !snapshot.transactions.isEmpty
            ? cashFlowAnalyzer.analyze(transactions: snapshot.transactions, referenceDate: snapshot.referenceDate)
            : CashFlowAnalyzer.empty(windowDays: 180)

        // WowIncome
        let lowest: LowestMonth = cashFlow.monthlyIncomeLowest.map { mp in
            LowestMonth(amount: mp.amount, month: monthName(year: mp.key.year, month: mp.key.month))
        } ?? LowestMonth(amount: cashFlow.monthlyIncomeAvg, month: "necunoscută")

        let income = WowIncome(
            monthlyAvg: cashFlow.monthlyIncomeAvg,
            stability: incomeStabilityFromTrend(cashFlow.monthlyBalanceTrend),
            lowestMonth: lowest,
            extraIncomeDetected: snapshot.userProfile?.financials.hasSecondaryIncome ?? false,
            extraIncomeAvg: snapshot.userProfile?.financials.secondaryIncomeAvg
        )

        let spending = WowSpending(
            monthlyAvg: cashFlow.monthlySpendingAvg,
            incomeConsumptionRatio: cashFlow.incomeConsumptionRatio,
            monthlyBalanceTrend: cashFlow.monthlyBalanceTrend,
            cardCreditUsed: false,
            overdraftUsedCount180d: 0
        )

        let obligationsTotal = snapshot.obligations.reduce(Money(0)) { $0 + $1.amount }
        let obligationsItems = snapshot.obligations.prefix(8).map { o in
            ObligationSummaryItem(name: o.name, amount: o.amount, dayOfMonth: o.dayOfMonth)
        }
        let obligationsRatio = cashFlow.monthlyIncomeAvg.amount > 0
            ? Double(obligationsTotal.amount) / Double(cashFlow.monthlyIncomeAvg.amount)
            : 0
        let obligationsBlock = ObligationsBlock(
            monthlyTotalFixed: obligationsTotal,
            items: Array(obligationsItems),
            obligationsToIncomeRatio: obligationsRatio
        )

        let audit = subscriptionAuditor.audit(subscriptions: snapshot.subscriptions)
        let ghostsBlock = GhostSubscriptionsBlock(
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

        var positives: [PositiveItem] = []
        if !snapshot.obligations.contains(where: { $0.kind == .loanIFN }) {
            positives.append(PositiveItem(type: .noIFN, description: "Niciun credit IFN activ"))
        }
        if obligationsRatio < 0.3 && obligationsRatio > 0 {
            positives.append(PositiveItem(type: .rentToIncomeHealthy, description: "Obligațiile sunt sub 30% din venit"))
        }
        if audit.monthlyKeptTotal.amount < 200 {
            positives.append(PositiveItem(type: .lowSubscriptions, description: "Abonamente sub 200 RON/lună"))
        }

        let firstGoal = snapshot.goals.first
        let goalBlock = GoalBlock(
            declared: firstGoal != nil,
            type: firstGoal?.kind,
            destination: firstGoal?.destination,
            amountTarget: firstGoal?.amountTarget,
            amountSaved: firstGoal?.amountSaved
        )

        let history = computeMonthlyBalanceHistory(snapshot: snapshot, cashFlow: cashFlow)
        let spiralReport = spiralDetector.detect(
            transactions: snapshot.transactions,
            obligations: snapshot.obligations,
            monthlyIncomeAvg: cashFlow.monthlyIncomeAvg,
            monthlySpendingAvg: cashFlow.monthlySpendingAvg,
            monthlyBalanceHistory: history,
            referenceDate: snapshot.referenceDate
        )
        let spiralBlock = SpiralBlock(
            score: spiralReport.score,
            severity: spiralReport.severity,
            factors: spiralReport.factors
        )

        let nextAction: NextActionSuggestion
        if audit.ghostCount > 0 {
            nextAction = NextActionSuggestion(
                type: .cancelGhostSubscriptions,
                rationale: "Anulând cele \(audit.ghostCount) abonamente fantomă recuperezi \(audit.monthlyRecoverable.amount) RON/lună",
                monthlySaving: audit.monthlyRecoverable,
                annualSaving: audit.annualRecoverable
            )
        } else if spiralReport.severity >= .high {
            nextAction = NextActionSuggestion(
                type: .talkToCSALB,
                rationale: "Severitate spiral ridicată — CSALB poate media gratuit",
                monthlySaving: nil,
                annualSaving: nil
            )
        } else {
            nextAction = NextActionSuggestion(
                type: .noActionNeeded,
                rationale: "Totul arată bine pentru momentul curent",
                monthlySaving: nil,
                annualSaving: nil
            )
        }

        return WowMomentContext(
            user: buildMomentUser(snapshot: snapshot),
            analysisPeriodDays: cashFlow.windowDays,
            income: income,
            spending: spending,
            outliers: [],
            patterns: [],
            obligations: obligationsBlock,
            ghostSubscriptions: ghostsBlock,
            positives: positives,
            goal: goalBlock,
            spiralRisk: spiralBlock,
            nextActionSuggested: nextAction
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
