import Foundation

/// Context complet pentru Wow Moment (spec §6.2).
///
/// Acesta este JSON-ul exact pe care prompt template-ul „Wow Moment" îl primește:
/// 1:1 cu spec-ul, fără câmpuri în plus. LLM-ul scrie text peste aceste fapte —
/// niciodată nu inventează observații noi.
public struct WowMomentContext: Codable, Sendable, Hashable {
    public let momentType: MomentType
    public var user: MomentUser
    public var analysisPeriodDays: Int
    public var income: WowIncome
    public var spending: WowSpending
    public var outliers: [OutlierItem]
    public var patterns: [PatternItem]
    public var obligations: ObligationsBlock
    public var ghostSubscriptions: GhostSubscriptionsBlock
    public var positives: [PositiveItem]
    public var goal: GoalBlock
    public var spiralRisk: SpiralBlock
    public var nextActionSuggested: NextActionSuggestion

    public init(
        user: MomentUser,
        analysisPeriodDays: Int = 180,
        income: WowIncome,
        spending: WowSpending,
        outliers: [OutlierItem],
        patterns: [PatternItem],
        obligations: ObligationsBlock,
        ghostSubscriptions: GhostSubscriptionsBlock,
        positives: [PositiveItem],
        goal: GoalBlock,
        spiralRisk: SpiralBlock,
        nextActionSuggested: NextActionSuggestion
    ) {
        self.momentType = .wowMoment
        self.user = user
        self.analysisPeriodDays = analysisPeriodDays
        self.income = income
        self.spending = spending
        self.outliers = outliers
        self.patterns = patterns
        self.obligations = obligations
        self.ghostSubscriptions = ghostSubscriptions
        self.positives = positives
        self.goal = goal
        self.spiralRisk = spiralRisk
        self.nextActionSuggested = nextActionSuggested
    }
}
