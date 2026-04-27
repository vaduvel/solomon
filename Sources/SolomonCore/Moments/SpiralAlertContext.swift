import Foundation

public enum RecoveryComplexity: String, Codable, Sendable, Hashable {
    case easy
    case medium
    case hard
    case behavioral
}

public enum RecoveryTool: String, Codable, Sendable, Hashable {
    case csalb         = "CSALB"
    case bankNegotiate = "bank_negotiate"
    case anpc          = "ANPC"
    case selfService   = "self_service"
}

public struct RecoveryStep: Codable, Sendable, Hashable {
    public var action: String
    public var monthlySaving: Money?
    public var potentialSaving: String?
    public var complexity: RecoveryComplexity
    public var tool: RecoveryTool?

    public init(action: String, monthlySaving: Money? = nil, potentialSaving: String? = nil,
                complexity: RecoveryComplexity, tool: RecoveryTool? = nil) {
        self.action = action
        self.monthlySaving = monthlySaving
        self.potentialSaving = potentialSaving
        self.complexity = complexity
        self.tool = tool
    }
}

public struct RecoveryPlan: Codable, Sendable, Hashable {
    public var step1: RecoveryStep
    public var step2: RecoveryStep
    public var step3: RecoveryStep

    public init(step1: RecoveryStep, step2: RecoveryStep, step3: RecoveryStep) {
        self.step1 = step1
        self.step2 = step2
        self.step3 = step3
    }
}

// MARK: - Context principal (spec §6.8)

public struct SpiralAlertContext: Codable, Sendable, Hashable {
    public let momentType: MomentType
    public var user: MomentUser
    public var spiralScore: Int
    public var severity: SpiralSeverity
    public var factorsDetected: [SpiralFactor]
    public var narrativeSummary: String
    public var interventionNeeded: Bool
    public var csalbRelevant: Bool
    public var recoveryPlan: RecoveryPlan

    public init(user: MomentUser, spiralScore: Int, severity: SpiralSeverity,
                factorsDetected: [SpiralFactor], narrativeSummary: String,
                interventionNeeded: Bool, csalbRelevant: Bool,
                recoveryPlan: RecoveryPlan) {
        precondition((0...4).contains(spiralScore))
        self.momentType = .spiralAlert
        self.user = user
        self.spiralScore = spiralScore
        self.severity = severity
        self.factorsDetected = factorsDetected
        self.narrativeSummary = narrativeSummary
        self.interventionNeeded = interventionNeeded
        self.csalbRelevant = csalbRelevant
        self.recoveryPlan = recoveryPlan
    }
}
