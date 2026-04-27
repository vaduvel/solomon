import Foundation
import SolomonCore

/// Output al `ObligationMapper`.
public struct ObligationMap: Sendable, Hashable, Codable {
    public var allObligations: [Obligation]
    public var monthlyTotalFixed: Money
    public var obligationsToIncomeRatio: Double
    /// Obligații grupate după ziua lunii la care vin (1...31 → listă).
    public var calendarByDay: [Int: [Obligation]]
    /// Obligații detectate dar nedeclarate de utilizator („silent").
    public var detectedSilent: [Obligation]
    /// Suma obligațiilor de tip „datorie" (IFN, BNPL, credite bancare).
    public var debtMonthlyTotal: Money

    public init(allObligations: [Obligation], monthlyTotalFixed: Money,
                obligationsToIncomeRatio: Double, calendarByDay: [Int: [Obligation]],
                detectedSilent: [Obligation], debtMonthlyTotal: Money) {
        self.allObligations = allObligations
        self.monthlyTotalFixed = monthlyTotalFixed
        self.obligationsToIncomeRatio = obligationsToIncomeRatio
        self.calendarByDay = calendarByDay
        self.detectedSilent = detectedSilent
        self.debtMonthlyTotal = debtMonthlyTotal
    }

    /// Obligațiile care vin într-un anumit interval de zile ale lunii.
    public func obligations(betweenDays start: Int, and end: Int) -> [Obligation] {
        allObligations.filter { (start...end).contains($0.dayOfMonth) }
    }

    /// Obligațiile rămase între ziua curentă și sfârșitul perioadei (uzual până la următorul payday).
    public func obligationsRemainingFrom(day: Int, untilDay end: Int = 31) -> [Obligation] {
        allObligations
            .filter { $0.dayOfMonth >= day && $0.dayOfMonth <= end }
            .sorted { $0.dayOfMonth < $1.dayOfMonth }
    }
}

/// Calculează panoul lunar de obligații recurente (spec §7.2 modul 2).
public struct ObligationMapper: Sendable {

    public init() {}

    /// - Parameters:
    ///   - declared: obligații declarate explicit de utilizator la onboarding.
    ///   - detected: obligații detectate de email parser / pattern detector.
    ///   - monthlyIncomeAvg: pentru ratio calculation (din `CashFlowAnalysis`).
    public func map(
        declared: [Obligation],
        detected: [Obligation] = [],
        monthlyIncomeAvg: Money
    ) -> ObligationMap {
        // Declared sunt sursă de adevăr; detected adaugă doar dacă nu există overlap pe nume.
        let declaredNames = Set(declared.map { $0.name.lowercased() })
        let dedupedDetected = detected.filter { !declaredNames.contains($0.name.lowercased()) }
        let all = declared + dedupedDetected

        let total = all.reduce(Money(0)) { $0 + $1.amount }
        let ratio = monthlyIncomeAvg.amount > 0
            ? Double(total.amount) / Double(monthlyIncomeAvg.amount)
            : 0

        var calendar: [Int: [Obligation]] = [:]
        for obligation in all {
            calendar[obligation.dayOfMonth, default: []].append(obligation)
        }
        for day in calendar.keys {
            calendar[day]?.sort { $0.amount > $1.amount }
        }

        let debtTotal = all
            .filter { $0.isDebt }
            .reduce(Money(0)) { $0 + $1.amount }

        return ObligationMap(
            allObligations: all,
            monthlyTotalFixed: total,
            obligationsToIncomeRatio: ratio,
            calendarByDay: calendar,
            detectedSilent: dedupedDetected,
            debtMonthlyTotal: debtTotal
        )
    }
}
