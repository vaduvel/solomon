import Foundation
import SolomonCore

/// Output al `SpiralDetector` — score 0…4 cu factori detectați (spec §6.8, §10.1).
public struct SpiralReport: Sendable, Hashable, Codable {
    public var score: Int                 // 0…4
    public var severity: SpiralSeverity
    public var factors: [SpiralFactor]
    public var monthlyBalanceHistory: [Int]
    public var requiresIntervention: Bool
    public var csalbRelevant: Bool

    public init(score: Int, severity: SpiralSeverity, factors: [SpiralFactor],
                monthlyBalanceHistory: [Int], requiresIntervention: Bool, csalbRelevant: Bool) {
        self.score = score
        self.severity = severity
        self.factors = factors
        self.monthlyBalanceHistory = monthlyBalanceHistory
        self.requiresIntervention = requiresIntervention
        self.csalbRelevant = csalbRelevant
    }
}

/// Detectează semnale de spirală financiară (spec §7.2 modul 5 + §10.1).
///
/// Score:
/// - 0 = niciun factor (severity .none)
/// - 1 = un factor (severity .low)
/// - 2 = doi factori (severity .medium)
/// - 3 = trei factori (severity .high)
/// - 4 = patru sau mai mulți factori (severity .critical)
///
/// Critic la score ≥ 3: declanșează Spiral Alert + CSALB Bridge.
public struct SpiralDetector: Sendable {

    public init() {}

    /// - Parameters:
    ///   - transactions: tranzacții pe ultimele 60 de zile (sau mai multe).
    ///   - obligations: obligații recurente cunoscute.
    ///   - monthlyIncomeAvg: din `CashFlowAnalysis`.
    ///   - monthlyBalanceHistory: balansa la sfârșit de lună pentru ultimele 4-6 luni.
    public func detect(
        transactions: [Transaction],
        obligations: [Obligation],
        monthlyIncomeAvg: Money,
        monthlySpendingAvg: Money,
        monthlyBalanceHistory: [Money],
        referenceDate: Date = Date(),
        calendar: Calendar = .gregorianRO
    ) -> SpiralReport {
        var factors: [SpiralFactor] = []

        // 1. Balance declining peste 3+ luni
        if let balanceFactor = balanceDecliningFactor(history: monthlyBalanceHistory) {
            factors.append(balanceFactor)
        }

        // 2. Card credit usage increasing — heuristic: mărirea cumulativă a cheltuielilor
        // în categoria credite bancare/BNPL pe luni consecutive.
        if let creditFactor = cardCreditIncreasingFactor(transactions: transactions, calendar: calendar) {
            factors.append(creditFactor)
        }

        // 3. IFN active — orice IFN incoming în ultimele 30 zile
        if let ifnFactor = ifnActiveFactor(transactions: transactions, referenceDate: referenceDate, calendar: calendar) {
            factors.append(ifnFactor)
        }

        // 4. BNPL stacking — 2+ obligații BNPL distincte
        if let bnplFactor = bnplStackingFactor(obligations: obligations) {
            factors.append(bnplFactor)
        }

        // 5. Obligations + spending > income
        if let gapFactor = obligationsExceedIncomeFactor(
            obligations: obligations,
            monthlyIncome: monthlyIncomeAvg,
            monthlySpending: monthlySpendingAvg
        ) {
            factors.append(gapFactor)
        }

        // Score ponderat: IFN și obligations>income sunt semnale critice (2 pts),
        // celelalte (balance declining, card credit, BNPL stacking) = 1 pt fiecare.
        // FAZA B5: ifnActive primește weight 1 (nu 2) — un singur IFN istoric plătit
        // la timp NU e spirală reală. Spirala reală se manifestă DOAR când ifnActive
        // se combină cu alți factori toxici (balance declining, BNPL stacking, etc.).
        // obligationsExceedIncome rămâne weight 2 — e blocant matematic indiferent.
        let weightedScore = factors.reduce(0) { acc, factor in
            switch factor.factor {
            case .obligationsExceedIncome: return acc + 2
            case .ifnActive: return acc + 1
            default: return acc + 1
            }
        }
        let score = min(weightedScore, 4)
        let severity = Self.severity(forScore: score)

        return SpiralReport(
            score: score,
            severity: severity,
            factors: factors,
            monthlyBalanceHistory: monthlyBalanceHistory.map { $0.amount },
            requiresIntervention: score >= 2,
            csalbRelevant: factors.contains { $0.factor == .ifnActive } || score >= 3
        )
    }

    // MARK: - Factor detectors

    func balanceDecliningFactor(history: [Money]) -> SpiralFactor? {
        guard history.count >= 3 else { return nil }
        let last4 = history.suffix(4)
        let amounts = last4.map(\.amount)
        // Strict descrescător + ultima e negativă sau aproape de zero.
        guard amounts.count >= 3 else { return nil }
        var declining = true
        for i in 1..<amounts.count where amounts[i] >= amounts[i - 1] {
            declining = false
            break
        }
        if !declining { return nil }
        return SpiralFactor(
            factor: .balanceDeclining,
            evidence: "balanță finală scade \(amounts.count) luni la rând",
            values: amounts
        )
    }

    func cardCreditIncreasingFactor(transactions: [Transaction], calendar: Calendar) -> SpiralFactor? {
        // Group outgoing tx category .loansBank by month, look for increasing month-over-month sum.
        var monthly: [MonthKey: Int] = [:]
        for tx in transactions where tx.direction == .outgoing && tx.category == .loansBank {
            let key = MonthKey(from: tx.date, calendar: calendar)
            monthly[key, default: 0] += tx.amount.amount
        }
        guard monthly.count >= 3 else { return nil }
        let sorted = monthly.sorted { $0.key < $1.key }
        let amounts = sorted.map(\.value)
        var increasing = true
        for i in 1..<amounts.count where amounts[i] < amounts[i - 1] {
            increasing = false
            break
        }
        guard increasing, let last = amounts.last, last > 0 else { return nil }
        let avgIncrease = Double(amounts.last! - amounts.first!) / Double(amounts.count - 1)
        return SpiralFactor(
            factor: .cardCreditIncreasing,
            evidence: "cheltuieli pe credit cresc lunar consecutiv \(amounts.count) luni",
            monthlyIncreaseAvg: Money(Int(avgIncrease.rounded()))
        )
    }

    func ifnActiveFactor(transactions: [Transaction], referenceDate: Date, calendar: Calendar) -> SpiralFactor? {
        guard let cutoff = calendar.date(byAdding: .day, value: -30, to: referenceDate) else { return nil }
        let recentIFN = transactions.filter {
            $0.direction == .incoming &&
            $0.category == .loansIFN &&
            $0.date >= cutoff
        }
        guard let largest = recentIFN.max(by: { $0.amount < $1.amount }) else { return nil }
        // Estimate total repayment via IFNDatabase if merchant matches.
        var estimatedTotal: Money? = nil
        if let merchant = largest.merchant?.lowercased() {
            if let ifnRecord = IFNDatabase.all.first(where: { merchant.contains($0.name.lowercased()) }) {
                let multiplier = ifnRecord.estimatedRepaymentMultiplier()
                estimatedTotal = Money(Int((Double(largest.amount.amount) * multiplier).rounded()))
            }
        }
        return SpiralFactor(
            factor: .ifnActive,
            evidence: "IFN incoming detectat în ultimele 30 zile",
            amount: largest.amount,
            estimatedTotalRepayment: estimatedTotal
        )
    }

    func bnplStackingFactor(obligations: [Obligation]) -> SpiralFactor? {
        let bnpls = obligations.filter { $0.kind == .bnpl }
        guard bnplsAreStacked(bnpls) else { return nil }
        let total = bnpls.reduce(Money(0)) { $0 + $1.amount }
        let names = bnpls.map(\.name).joined(separator: ", ")
        return SpiralFactor(
            factor: .bnplStacking,
            evidence: "\(bnpls.count) BNPL active concomitent: \(names)",
            amount: total
        )
    }

    func bnplsAreStacked(_ bnpls: [Obligation]) -> Bool {
        // Stacking definition din spec §10.2: 2+ BNPL active în paralel.
        bnpls.count >= 2
    }

    func obligationsExceedIncomeFactor(
        obligations: [Obligation],
        monthlyIncome: Money,
        monthlySpending: Money
    ) -> SpiralFactor? {
        let obligationsTotal = obligations.reduce(Money(0)) { $0 + $1.amount }
        let combinedOutflow = obligationsTotal + monthlySpending
        let gap = combinedOutflow - monthlyIncome
        guard gap.isPositive, monthlyIncome.amount > 0 else { return nil }
        return SpiralFactor(
            factor: .obligationsExceedIncome,
            evidence: "obligații + cheltuieli medii depășesc venitul cu \(gap.amount) RON/lună",
            monthlyGap: gap
        )
    }

    // MARK: - Severity mapping

    static func severity(forScore score: Int) -> SpiralSeverity {
        switch score {
        case 0: return .none
        case 1: return .low
        case 2: return .medium
        case 3: return .high
        default: return .critical
        }
    }
}
