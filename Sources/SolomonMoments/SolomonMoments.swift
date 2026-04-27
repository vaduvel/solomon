import Foundation
import SolomonCore
import SolomonAnalytics
import SolomonLLM
import SolomonStorage

/// Modulul SolomonMoments — generatorul celor 8 momente financiare cu LLM local.
///
/// Componente principale:
/// - `LLMProvider` protocol + `MockLLMProvider` (teste fără LLM real)
/// - `MomentBuilder` protocol + `MomentOutput` — structura comună pentru toți builderii
/// - `JSONContextBuilder` — serializare context → JSON Solomon snake_case
/// - Builders: `WowMomentBuilder`, `CanIAffordBuilder`, `PaydayMagicBuilder`,
///   `UpcomingObligationBuilder`, `PatternAlertBuilder`, `SubscriptionAuditBuilder`,
///   `SpiralAlertBuilder`, `WeeklySummaryBuilder`
/// - `MomentOrchestrator` — selectează și generează momentul cu cea mai mare prioritate
///
/// Spec: §5.1 (momente), §6.X (contexte), §3.2 (LLM local Gemma).
public enum SolomonMoments {
    public static let version = "1.0.0"
    public static let momentCount = 8
    public static let momentTypes: [String] = MomentType.allCases.map { $0.rawValue }
}
