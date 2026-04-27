import Foundation

// MARK: - Sub-types specifice acestui moment

public enum CanIAffordVerdict: String, Codable, Sendable, Hashable {
    case yes
    case yesWithCaution = "yes_with_caution"
    case no
}

public enum CanIAffordVerdictReason: String, Codable, Sendable, Hashable {
    case comfortableMargin    = "comfortable_margin"
    case tightButWorkable     = "tight_but_workable"
    case wouldCreateOverdraft = "would_create_overdraft"
    case wouldBreakObligation = "would_break_obligation"
    case categoryAlreadyOver  = "category_already_over"
}

public enum CanIAffordAlternative: String, Codable, Sendable, Hashable {
    case waitUntilPayday      = "wait_until_payday"
    case waitDays2            = "wait_2_days"
    case waitDays3            = "wait_3_days"
    case smallerAmount        = "smaller_amount"
    case waitTwoDaysAfterEnel = "wait_2_days_until_after_enel"
    case skipThisCategoryWeek = "skip_this_category_this_week"
    case none
}

public struct AffordObligationRef: Codable, Sendable, Hashable {
    public var name: String
    public var amount: Money
    public var dueDate: Date

    public init(name: String, amount: Money, dueDate: Date) {
        self.name = name
        self.amount = amount
        self.dueDate = dueDate
    }
}

public struct CanIAffordQuery: Codable, Sendable, Hashable {
    public var rawText: String
    public var amountRequested: Money
    public var categoryInferred: TransactionCategory
    public var merchantInferred: String?
    public var isRecurring: Bool

    public init(rawText: String, amountRequested: Money, categoryInferred: TransactionCategory,
                merchantInferred: String? = nil, isRecurring: Bool = false) {
        self.rawText = rawText
        self.amountRequested = amountRequested
        self.categoryInferred = categoryInferred
        self.merchantInferred = merchantInferred
        self.isRecurring = isRecurring
    }
}

public struct CanIAffordContextBlock: Codable, Sendable, Hashable {
    public var today: Date
    public var daysUntilPayday: Int
    public var currentBalance: Money
    public var obligationsRemainingThisPeriod: [AffordObligationRef]
    public var obligationsTotalRemaining: Money
    public var availableAfterObligations: Money
    public var availablePerDayAfter: Money
    public var availablePerDayAfterPurchase: Money

    public init(today: Date, daysUntilPayday: Int, currentBalance: Money,
                obligationsRemainingThisPeriod: [AffordObligationRef],
                obligationsTotalRemaining: Money, availableAfterObligations: Money,
                availablePerDayAfter: Money, availablePerDayAfterPurchase: Money) {
        self.today = today
        self.daysUntilPayday = daysUntilPayday
        self.currentBalance = currentBalance
        self.obligationsRemainingThisPeriod = obligationsRemainingThisPeriod
        self.obligationsTotalRemaining = obligationsTotalRemaining
        self.availableAfterObligations = availableAfterObligations
        self.availablePerDayAfter = availablePerDayAfter
        self.availablePerDayAfterPurchase = availablePerDayAfterPurchase
    }
}

public struct CanIAffordDecision: Codable, Sendable, Hashable {
    public var verdict: CanIAffordVerdict
    public var verdictReason: CanIAffordVerdictReason
    /// Fraza pre-construită cu cifre („după pizza, ai 33 RON/zi pentru 9 zile")
    /// pe care LLM-ul o poate cita literal.
    public var mathVisible: String
    public var alternativeToSuggest: CanIAffordAlternative

    public init(verdict: CanIAffordVerdict, verdictReason: CanIAffordVerdictReason,
                mathVisible: String, alternativeToSuggest: CanIAffordAlternative = .none) {
        self.verdict = verdict
        self.verdictReason = verdictReason
        self.mathVisible = mathVisible
        self.alternativeToSuggest = alternativeToSuggest
    }
}

public struct CanIAffordHistoryContext: Codable, Sendable, Hashable {
    public var thisCategoryThisMonth: Money
    public var thisCategoryAvgMonthly: Money
    public var isAboveAverageToday: Bool

    public init(thisCategoryThisMonth: Money, thisCategoryAvgMonthly: Money, isAboveAverageToday: Bool) {
        self.thisCategoryThisMonth = thisCategoryThisMonth
        self.thisCategoryAvgMonthly = thisCategoryAvgMonthly
        self.isAboveAverageToday = isAboveAverageToday
    }
}

// MARK: - Context principal (spec §6.3)

public struct CanIAffordContext: Codable, Sendable, Hashable {
    public let momentType: MomentType
    public var user: MomentUser
    public var query: CanIAffordQuery
    public var context: CanIAffordContextBlock
    public var decision: CanIAffordDecision
    public var userHistoryContext: CanIAffordHistoryContext

    public init(user: MomentUser, query: CanIAffordQuery, context: CanIAffordContextBlock,
                decision: CanIAffordDecision, userHistoryContext: CanIAffordHistoryContext) {
        self.momentType = .canIAfford
        self.user = user
        self.query = query
        self.context = context
        self.decision = decision
        self.userHistoryContext = userHistoryContext
    }
}
