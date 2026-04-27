import Foundation
import SolomonCore

// MARK: - Month key (year + month)

/// Cheie pentru o lună calendaristică, comparabilă și hashable.
public struct MonthKey: Hashable, Sendable, Comparable, Codable {
    public let year: Int
    public let month: Int  // 1-12

    public init(year: Int, month: Int) {
        precondition((1...12).contains(month), "Lună invalidă: \(month)")
        self.year = year
        self.month = month
    }

    public init(from date: Date, calendar: Calendar = .gregorianRO) {
        let comps = calendar.dateComponents([.year, .month], from: date)
        self.init(year: comps.year ?? 0, month: comps.month ?? 1)
    }

    public static func < (lhs: MonthKey, rhs: MonthKey) -> Bool {
        if lhs.year != rhs.year { return lhs.year < rhs.year }
        return lhs.month < rhs.month
    }

    public var monthNameRO: String { RomanianDateFormatter.monthName(month) }

    /// MonthKey-ul de luni N în spate (negativ pentru viitor).
    public func monthsAgo(_ n: Int) -> MonthKey {
        // Lucrăm în „luni totale" zero-indexed (0 = ianuarie anul 0).
        let totalMonths = year * 12 + (month - 1) - n
        let resolvedYear = Int(floor(Double(totalMonths) / 12.0))
        let resolvedMonth = ((totalMonths % 12) + 12) % 12 + 1
        return MonthKey(year: resolvedYear, month: resolvedMonth)
    }
}

// MARK: - Monthly amount (cu nume de lună)

public struct MonthlyAmount: Hashable, Sendable, Codable {
    public let amount: Money
    public let key: MonthKey

    public init(amount: Money, key: MonthKey) {
        self.amount = amount
        self.key = key
    }

    public var monthNameRO: String { key.monthNameRO }
}

// MARK: - Cash flow output

/// Statusul net între venit și cheltuieli (similar `BalanceTrend`, dar punctual).
public enum BreakEvenStatus: String, Sendable, Hashable, Codable {
    /// Surplus > 15% din venit
    case wellAboveBreakEven    = "well_above_break_even"
    /// Surplus 0–15%
    case aboveBreakEven        = "above_break_even"
    /// Net ±5% din venit
    case atBreakEven           = "at_break_even"
    /// Deficit 0–15%
    case belowBreakEven        = "below_break_even"
    /// Deficit > 15%
    case wellBelowBreakEven    = "well_below_break_even"
}

/// Analiză cash flow pentru o fereastră de timp (uzual 180 zile).
public struct CashFlowAnalysis: Sendable, Hashable, Codable {
    public var windowDays: Int
    public var analyzedMonths: Int
    public var monthlyIncomeAvg: Money
    public var monthlyIncomeLowest: MonthlyAmount?
    public var monthlyIncomeHighest: MonthlyAmount?
    public var monthlySpendingAvg: Money
    public var spendingByCategory: [TransactionCategory: Money]
    public var monthlyBalanceTrend: BalanceTrend
    public var velocityRONPerDay: Money
    public var breakEvenStatus: BreakEvenStatus
    /// Suma economisită medie pe lună (income − spending). Negativ = deficit.
    public var monthlySavingsAvg: Money
    /// Procent salariu consumat lunar (0…1+).
    public var incomeConsumptionRatio: Double

    public init(
        windowDays: Int,
        analyzedMonths: Int,
        monthlyIncomeAvg: Money,
        monthlyIncomeLowest: MonthlyAmount?,
        monthlyIncomeHighest: MonthlyAmount?,
        monthlySpendingAvg: Money,
        spendingByCategory: [TransactionCategory: Money],
        monthlyBalanceTrend: BalanceTrend,
        velocityRONPerDay: Money,
        breakEvenStatus: BreakEvenStatus,
        monthlySavingsAvg: Money,
        incomeConsumptionRatio: Double
    ) {
        self.windowDays = windowDays
        self.analyzedMonths = analyzedMonths
        self.monthlyIncomeAvg = monthlyIncomeAvg
        self.monthlyIncomeLowest = monthlyIncomeLowest
        self.monthlyIncomeHighest = monthlyIncomeHighest
        self.monthlySpendingAvg = monthlySpendingAvg
        self.spendingByCategory = spendingByCategory
        self.monthlyBalanceTrend = monthlyBalanceTrend
        self.velocityRONPerDay = velocityRONPerDay
        self.breakEvenStatus = breakEvenStatus
        self.monthlySavingsAvg = monthlySavingsAvg
        self.incomeConsumptionRatio = incomeConsumptionRatio
    }

    /// Top N categorii după cheltuieli.
    public func topSpendingCategories(_ n: Int = 5) -> [(TransactionCategory, Money)] {
        spendingByCategory
            .sorted { $0.value.amount > $1.value.amount }
            .prefix(n)
            .map { ($0.key, $0.value) }
    }
}
