import Foundation

public struct TemporalConcentration: Codable, Sendable, Hashable {
    public var isTemporal: Bool
    public var pattern: String
    public var interpretation: String

    public init(isTemporal: Bool, pattern: String, interpretation: String) {
        self.isTemporal = isTemporal
        self.pattern = pattern
        self.interpretation = interpretation
    }
}

public struct PatternDetected: Codable, Sendable, Hashable {
    public var category: TransactionCategory
    public var merchantDominant: String?
    public var type: PatternType
    public var description: String
    public var amountPeriod: Money
    public var amountProjectedMonthly: Money
    public var vsBudget: Money
    public var vsBudgetPct: Int
    public var temporalConcentration: TemporalConcentration

    public init(category: TransactionCategory, merchantDominant: String? = nil,
                type: PatternType, description: String,
                amountPeriod: Money, amountProjectedMonthly: Money,
                vsBudget: Money, vsBudgetPct: Int,
                temporalConcentration: TemporalConcentration) {
        self.category = category
        self.merchantDominant = merchantDominant
        self.type = type
        self.description = description
        self.amountPeriod = amountPeriod
        self.amountProjectedMonthly = amountProjectedMonthly
        self.vsBudget = vsBudget
        self.vsBudgetPct = vsBudgetPct
        self.temporalConcentration = temporalConcentration
    }
}

public enum PatternScenarioID: String, Codable, Sendable, Hashable {
    case continueAsIs   = "continue"
    case reduce2PerWeek = "reduce_2_per_week"
    case skipOneWeek    = "skip_one_week"
    case skipMonth      = "skip_month"
    case capCategory    = "cap_category"
}

public struct PatternScenario: Codable, Sendable, Hashable {
    public var scenarioId: PatternScenarioID
    public var description: String
    public var monthEndOutcome: String
    public var goalImpact: String

    public init(scenarioId: PatternScenarioID, description: String,
                monthEndOutcome: String, goalImpact: String) {
        self.scenarioId = scenarioId
        self.description = description
        self.monthEndOutcome = monthEndOutcome
        self.goalImpact = goalImpact
    }
}

public enum PatternToneCalibration: String, Codable, Sendable, Hashable {
    case warmNoJudgment   = "warm_no_judgment"
    case factualBlunt     = "factual_blunt"
    case curiousReflective = "curious_reflective"
}

// MARK: - Context principal (spec §6.6)

public struct PatternAlertContext: Codable, Sendable, Hashable {
    public let momentType: MomentType
    public var user: MomentUser
    public var patternDetected: PatternDetected
    public var scenarios: [PatternScenario]
    public var toneCalibration: PatternToneCalibration

    public init(user: MomentUser, patternDetected: PatternDetected,
                scenarios: [PatternScenario], toneCalibration: PatternToneCalibration = .warmNoJudgment) {
        self.momentType = .patternAlert
        self.user = user
        self.patternDetected = patternDetected
        self.scenarios = scenarios
        self.toneCalibration = toneCalibration
    }
}
