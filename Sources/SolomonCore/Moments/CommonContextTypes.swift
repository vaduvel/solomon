import Foundation

// Tipuri partajate între contextele momentelor — exact structurile din spec §6.

// MARK: - User reference (folosit în toate momentele)

/// Forma „user" embeddată în fiecare context de moment (spec §6.2 ș.urm.).
public struct MomentUser: Codable, Sendable, Hashable {
    public var name: String
    public var addressing: Addressing
    /// Prezent în Wow Moment, opțional în restul.
    public var ageRange: AgeRange?

    public init(name: String, addressing: Addressing, ageRange: AgeRange? = nil) {
        self.name = name
        self.addressing = addressing
        self.ageRange = ageRange
    }
}

// MARK: - Income / Spending profile (Wow Moment §6.2)

public enum IncomeStability: String, Codable, Sendable, Hashable {
    case stable
    case slightlyVariable = "slightly_variable"
    case variable
    case unstable
}

public struct LowestMonth: Codable, Sendable, Hashable {
    public var amount: Money
    /// Numele lunii în română („februarie", „august").
    public var month: String

    public init(amount: Money, month: String) {
        self.amount = amount
        self.month = month
    }
}

public struct WowIncome: Codable, Sendable, Hashable {
    public var monthlyAvg: Money
    public var stability: IncomeStability
    public var lowestMonth: LowestMonth
    public var extraIncomeDetected: Bool
    public var extraIncomeAvg: Money?

    public init(monthlyAvg: Money, stability: IncomeStability, lowestMonth: LowestMonth,
                extraIncomeDetected: Bool, extraIncomeAvg: Money? = nil) {
        self.monthlyAvg = monthlyAvg
        self.stability = stability
        self.lowestMonth = lowestMonth
        self.extraIncomeDetected = extraIncomeDetected
        self.extraIncomeAvg = extraIncomeAvg
    }
}

public enum BalanceTrend: String, Codable, Sendable, Hashable {
    case healthy
    case barelyBreakeven   = "barely_breakeven"
    case breakingEven      = "breaking_even"
    case slidingNegative   = "sliding_negative"
    case negative
}

public struct WowSpending: Codable, Sendable, Hashable {
    public var monthlyAvg: Money
    public var incomeConsumptionRatio: Double
    public var monthlyBalanceTrend: BalanceTrend
    public var cardCreditUsed: Bool
    public var overdraftUsedCount180d: Int

    public init(monthlyAvg: Money, incomeConsumptionRatio: Double, monthlyBalanceTrend: BalanceTrend,
                cardCreditUsed: Bool, overdraftUsedCount180d: Int) {
        self.monthlyAvg = monthlyAvg
        self.incomeConsumptionRatio = incomeConsumptionRatio
        self.monthlyBalanceTrend = monthlyBalanceTrend
        self.cardCreditUsed = cardCreditUsed
        self.overdraftUsedCount180d = overdraftUsedCount180d
    }
}

// MARK: - Outliers (Wow Moment §6.2)

public enum OutlierType: String, Codable, Sendable, Hashable {
    case singleLargePurchase   = "single_large_purchase"
    case categoryConcentration = "category_concentration"
    case unusualFrequency      = "unusual_frequency"
    case unusualMerchant       = "unusual_merchant"
}

public struct OutlierItem: Codable, Sendable, Hashable {
    public var rank: Int
    public var type: OutlierType
    public var category: TransactionCategory
    public var merchant: String?
    /// Pentru `singleLargePurchase` — suma tranzacției în sine.
    public var amount: Money?
    public var date: Date?
    /// Pentru `categoryConcentration` — totalul cumulat pe perioadă.
    public var amountTotal180d: Money?
    public var amountMonthlyAvg: Money?
    /// Construită de codul Swift, livrată LLM-ului ca text gata făcut.
    public var contextPhrase: String
    /// Comparația vie: „echivalent cu 5 luni de Netflix anual".
    public var contextComparison: String

    public init(rank: Int, type: OutlierType, category: TransactionCategory,
                merchant: String? = nil, amount: Money? = nil, date: Date? = nil,
                amountTotal180d: Money? = nil, amountMonthlyAvg: Money? = nil,
                contextPhrase: String, contextComparison: String) {
        self.rank = rank
        self.type = type
        self.category = category
        self.merchant = merchant
        self.amount = amount
        self.date = date
        self.amountTotal180d = amountTotal180d
        self.amountMonthlyAvg = amountMonthlyAvg
        self.contextPhrase = contextPhrase
        self.contextComparison = contextComparison
    }
}

// MARK: - Patterns (Wow Moment §6.2, Pattern Alert §6.6)

public enum PatternType: String, Codable, Sendable, Hashable {
    case temporalClustering = "temporal_clustering"
    case weekendSpike       = "weekend_spike"
    case frequencySpike     = "frequency_spike"
    case categoryDrift      = "category_drift"
    case merchantLoyalty    = "merchant_loyalty"
}

public struct PatternItem: Codable, Sendable, Hashable {
    public var type: PatternType
    public var category: TransactionCategory?
    public var description: String
    public var interpretation: String?
    public var averageWeekendSpend: Money?
    public var averageWeekdaySpend: Money?
    public var ratio: Double?

    public init(type: PatternType, category: TransactionCategory? = nil,
                description: String, interpretation: String? = nil,
                averageWeekendSpend: Money? = nil, averageWeekdaySpend: Money? = nil,
                ratio: Double? = nil) {
        self.type = type
        self.category = category
        self.description = description
        self.interpretation = interpretation
        self.averageWeekendSpend = averageWeekendSpend
        self.averageWeekdaySpend = averageWeekdaySpend
        self.ratio = ratio
    }
}

// MARK: - Obligations summary (Wow §6.2)

public struct ObligationSummaryItem: Codable, Sendable, Hashable {
    public var name: String
    public var amount: Money
    public var dayOfMonth: Int

    public init(name: String, amount: Money, dayOfMonth: Int) {
        self.name = name
        self.amount = amount
        self.dayOfMonth = dayOfMonth
    }
}

public struct ObligationsBlock: Codable, Sendable, Hashable {
    public var monthlyTotalFixed: Money
    public var items: [ObligationSummaryItem]
    public var obligationsToIncomeRatio: Double

    public init(monthlyTotalFixed: Money, items: [ObligationSummaryItem],
                obligationsToIncomeRatio: Double) {
        self.monthlyTotalFixed = monthlyTotalFixed
        self.items = items
        self.obligationsToIncomeRatio = obligationsToIncomeRatio
    }
}

// MARK: - Ghost subscriptions block (Wow §6.2, Subscription Audit §6.7)

public struct GhostSubscriptionItem: Codable, Sendable, Hashable {
    public var name: String
    public var amount: Money
    public var lastUsedDaysAgo: Int
    public var confidence: GhostConfidence

    public init(name: String, amount: Money, lastUsedDaysAgo: Int, confidence: GhostConfidence) {
        self.name = name
        self.amount = amount
        self.lastUsedDaysAgo = lastUsedDaysAgo
        self.confidence = confidence
    }
}

public struct GhostSubscriptionsBlock: Codable, Sendable, Hashable {
    public var count: Int
    public var monthlyTotal: Money
    public var annualTotal: Money
    public var items: [GhostSubscriptionItem]

    public init(count: Int, monthlyTotal: Money, annualTotal: Money, items: [GhostSubscriptionItem]) {
        self.count = count
        self.monthlyTotal = monthlyTotal
        self.annualTotal = annualTotal
        self.items = items
    }
}

// MARK: - Positives (Wow §6.2)

public enum PositiveType: String, Codable, Sendable, Hashable {
    case noIFN              = "no_ifn"
    case noLatePayments     = "no_late_payments"
    case rentToIncomeHealthy = "rent_to_income_healthy"
    case savingsConsistent  = "savings_consistent"
    case lowSubscriptions   = "low_subscriptions"
    case incomeGrowth       = "income_growth"
}

public struct PositiveItem: Codable, Sendable, Hashable {
    public var type: PositiveType
    public var description: String
    public var rarityContext: String?
    public var durationMonths: Int?
    public var ratio: Double?

    public init(type: PositiveType, description: String, rarityContext: String? = nil,
                durationMonths: Int? = nil, ratio: Double? = nil) {
        self.type = type
        self.description = description
        self.rarityContext = rarityContext
        self.durationMonths = durationMonths
        self.ratio = ratio
    }
}

// MARK: - Goal block (Wow §6.2)

public struct GoalBlock: Codable, Sendable, Hashable {
    public var declared: Bool
    public var type: GoalKind?
    public var destination: String?
    public var amountTarget: Money?
    public var amountSaved: Money?
    public var deadline: Date?
    public var monthsRemaining: Int?
    public var monthlyRequired: Money?
    public var feasibility: GoalFeasibility?
    public var currentPaceWillReach: Bool?
    public var shortfallPerMonth: Money?

    public init(declared: Bool, type: GoalKind? = nil, destination: String? = nil,
                amountTarget: Money? = nil, amountSaved: Money? = nil, deadline: Date? = nil,
                monthsRemaining: Int? = nil, monthlyRequired: Money? = nil,
                feasibility: GoalFeasibility? = nil, currentPaceWillReach: Bool? = nil,
                shortfallPerMonth: Money? = nil) {
        self.declared = declared
        self.type = type
        self.destination = destination
        self.amountTarget = amountTarget
        self.amountSaved = amountSaved
        self.deadline = deadline
        self.monthsRemaining = monthsRemaining
        self.monthlyRequired = monthlyRequired
        self.feasibility = feasibility
        self.currentPaceWillReach = currentPaceWillReach
        self.shortfallPerMonth = shortfallPerMonth
    }
}

// MARK: - Spiral block (Wow §6.2 + Spiral Alert §6.8)

public enum SpiralSeverity: String, Codable, Sendable, Hashable, CaseIterable, Comparable {
    case none, low, medium, high, critical

    private var rank: Int {
        switch self {
        case .none:     return 0
        case .low:      return 1
        case .medium:   return 2
        case .high:     return 3
        case .critical: return 4
        }
    }

    public static func < (lhs: SpiralSeverity, rhs: SpiralSeverity) -> Bool {
        lhs.rank < rhs.rank
    }
}

public enum SpiralFactorKind: String, Codable, Sendable, Hashable, CaseIterable {
    case balanceDeclining        = "balance_declining"
    case cardCreditIncreasing    = "card_credit_increasing"
    case ifnActive               = "ifn_active"
    case obligationsExceedIncome = "obligations_exceed_income"
    case bnplStacking            = "bnpl_stacking"
    case overdraftFrequent       = "overdraft_frequent"
}

public struct SpiralFactor: Codable, Sendable, Hashable {
    public var factor: SpiralFactorKind
    public var evidence: String
    public var values: [Int]?
    public var monthlyIncreaseAvg: Money?
    public var amount: Money?
    public var estimatedTotalRepayment: Money?
    public var monthlyGap: Money?

    public init(factor: SpiralFactorKind, evidence: String,
                values: [Int]? = nil, monthlyIncreaseAvg: Money? = nil,
                amount: Money? = nil, estimatedTotalRepayment: Money? = nil,
                monthlyGap: Money? = nil) {
        self.factor = factor
        self.evidence = evidence
        self.values = values
        self.monthlyIncreaseAvg = monthlyIncreaseAvg
        self.amount = amount
        self.estimatedTotalRepayment = estimatedTotalRepayment
        self.monthlyGap = monthlyGap
    }
}

public struct SpiralBlock: Codable, Sendable, Hashable {
    public var score: Int
    public var severity: SpiralSeverity
    public var factors: [SpiralFactor]

    public init(score: Int, severity: SpiralSeverity, factors: [SpiralFactor]) {
        precondition((0...4).contains(score), "spiral score trebuie 0…4, primit \(score)")
        self.score = score
        self.severity = severity
        self.factors = factors
    }
}

// MARK: - Next action suggested (Wow §6.2)

public enum NextActionType: String, Codable, Sendable, Hashable {
    case cancelGhostSubscriptions = "cancel_ghost_subscriptions"
    case reduceCategorySpending   = "reduce_category_spending"
    case startEmergencyFund       = "start_emergency_fund"
    case refinanceDebt            = "refinance_debt"
    case talkToCSALB              = "talk_to_csalb"
    case noActionNeeded           = "no_action_needed"
}

public struct NextActionSuggestion: Codable, Sendable, Hashable {
    public var type: NextActionType
    public var rationale: String
    public var monthlySaving: Money?
    public var annualSaving: Money?
    /// Ex: „8% din vacanța Grecia".
    public var goalProgressImpact: String?

    public init(type: NextActionType, rationale: String,
                monthlySaving: Money? = nil, annualSaving: Money? = nil,
                goalProgressImpact: String? = nil) {
        self.type = type
        self.rationale = rationale
        self.monthlySaving = monthlySaving
        self.annualSaving = annualSaving
        self.goalProgressImpact = goalProgressImpact
    }
}
