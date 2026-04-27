import Foundation

public enum PaydayReserveStatus: String, Codable, Sendable, Hashable {
    case rezervat
    case estimat
}

public struct PaydayObligationReserve: Codable, Sendable, Hashable {
    public var name: String
    public var amount: Money
    public var status: PaydayReserveStatus

    public init(name: String, amount: Money, status: PaydayReserveStatus) {
        self.name = name
        self.amount = amount
        self.status = status
    }
}

public struct PaydaySubscriptionReserve: Codable, Sendable, Hashable {
    public var name: String
    public var amount: Money

    public init(name: String, amount: Money) {
        self.name = name
        self.amount = amount
    }
}

public struct PaydaySavingsAuto: Codable, Sendable, Hashable {
    public var enabled: Bool
    public var amount: Money?
    public var destination: String?

    public init(enabled: Bool, amount: Money? = nil, destination: String? = nil) {
        self.enabled = enabled
        self.amount = amount
        self.destination = destination
    }
}

public struct PaydaySalary: Codable, Sendable, Hashable {
    public var amountReceived: Money
    public var receivedDate: Date
    public var source: String
    public var isHigherThanAverage: Bool
    public var isLowerThanAverage: Bool

    public init(amountReceived: Money, receivedDate: Date, source: String,
                isHigherThanAverage: Bool, isLowerThanAverage: Bool) {
        self.amountReceived = amountReceived
        self.receivedDate = receivedDate
        self.source = source
        self.isHigherThanAverage = isHigherThanAverage
        self.isLowerThanAverage = isLowerThanAverage
    }
}

public struct PaydayAllocation: Codable, Sendable, Hashable {
    public var obligationsReserved: [PaydayObligationReserve]
    public var subscriptionsReserved: [PaydaySubscriptionReserve]
    public var obligationsTotal: Money
    public var subscriptionsTotal: Money
    public var savingsAuto: PaydaySavingsAuto
    public var availableToSpend: Money
    public var daysUntilNextPayday: Int
    public var availablePerDay: Money

    public init(obligationsReserved: [PaydayObligationReserve],
                subscriptionsReserved: [PaydaySubscriptionReserve],
                obligationsTotal: Money, subscriptionsTotal: Money,
                savingsAuto: PaydaySavingsAuto,
                availableToSpend: Money, daysUntilNextPayday: Int, availablePerDay: Money) {
        self.obligationsReserved = obligationsReserved
        self.subscriptionsReserved = subscriptionsReserved
        self.obligationsTotal = obligationsTotal
        self.subscriptionsTotal = subscriptionsTotal
        self.savingsAuto = savingsAuto
        self.availableToSpend = availableToSpend
        self.daysUntilNextPayday = daysUntilNextPayday
        self.availablePerDay = availablePerDay
    }
}

public enum ComparisonDirection: String, Codable, Sendable, Hashable {
    case better, worse, same
}

public struct PaydayComparisons: Codable, Sendable, Hashable {
    public var vsLastMonthAvailable: Money
    public var vsLastMonthDiff: Money
    public var vsLastMonthDirection: ComparisonDirection

    public init(vsLastMonthAvailable: Money, vsLastMonthDiff: Money, vsLastMonthDirection: ComparisonDirection) {
        self.vsLastMonthAvailable = vsLastMonthAvailable
        self.vsLastMonthDiff = vsLastMonthDiff
        self.vsLastMonthDirection = vsLastMonthDirection
    }
}

public enum BudgetBasis: String, Codable, Sendable, Hashable {
    case average
    case reducedTarget = "reduced_target"
    case tenPercent    = "10_percent"
    case lastMonth     = "last_month"
}

public struct CategoryBudgetSuggestion: Codable, Sendable, Hashable {
    public var category: TransactionCategory
    public var amount: Money
    public var basedOn: BudgetBasis

    public init(category: TransactionCategory, amount: Money, basedOn: BudgetBasis) {
        self.category = category
        self.amount = amount
        self.basedOn = basedOn
    }
}

public enum PaydayWarningType: String, Codable, Sendable, Hashable {
    case upcomingEvent       = "upcoming_event"
    case lowAvailable        = "low_available"
    case obligationsTooHigh  = "obligations_too_high"
    case savingsRateLow      = "savings_rate_low"
}

public struct PaydayWarning: Codable, Sendable, Hashable {
    public var type: PaydayWarningType
    public var description: String
    public var impact: String?

    public init(type: PaydayWarningType, description: String, impact: String? = nil) {
        self.type = type
        self.description = description
        self.impact = impact
    }
}

// MARK: - Context principal (spec §6.4)

public struct PaydayContext: Codable, Sendable, Hashable {
    public let momentType: MomentType
    public var user: MomentUser
    public var salary: PaydaySalary
    public var autoAllocation: PaydayAllocation
    public var comparisons: PaydayComparisons
    public var categoryBudgetsSuggested: [CategoryBudgetSuggestion]
    public var warnings: [PaydayWarning]

    public init(user: MomentUser, salary: PaydaySalary, autoAllocation: PaydayAllocation,
                comparisons: PaydayComparisons, categoryBudgetsSuggested: [CategoryBudgetSuggestion],
                warnings: [PaydayWarning] = []) {
        self.momentType = .payday
        self.user = user
        self.salary = salary
        self.autoAllocation = autoAllocation
        self.comparisons = comparisons
        self.categoryBudgetsSuggested = categoryBudgetsSuggested
        self.warnings = warnings
    }
}
