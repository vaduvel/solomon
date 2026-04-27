import Foundation

/// Tipul unui moment Solomon (spec §5.1).
///
/// Folosit ca discriminator în JSON-ul livrat către LLM. Toate context-urile
/// concrete (`WowMomentContext`, `CanIAffordContext`, etc.) îl expun ca prim câmp
/// (`moment_type`).
public enum MomentType: String, Codable, Sendable, Hashable, CaseIterable {
    case wowMoment            = "wow_moment"
    case canIAfford           = "can_i_afford"
    case payday
    case upcomingObligation   = "upcoming_obligation"
    case patternAlert         = "pattern_alert"
    case subscriptionAudit    = "subscription_audit"
    case spiralAlert          = "spiral_alert"
    case weeklySummary        = "weekly_summary"

    /// Lungime maximă recomandată pentru output-ul LLM (spec §6.X).
    public var maxWords: Int {
        switch self {
        case .wowMoment:           return 280
        case .canIAfford:          return 60   // 3 propoziții scurte
        case .payday:              return 100  // 5 propoziții
        case .upcomingObligation:  return 60   // 3 propoziții
        case .patternAlert:        return 110  // 5 propoziții
        case .subscriptionAudit:   return 140  // 6 propoziții
        case .spiralAlert:         return 200  // 8 propoziții
        case .weeklySummary:       return 90   // 4 propoziții
        }
    }
}
