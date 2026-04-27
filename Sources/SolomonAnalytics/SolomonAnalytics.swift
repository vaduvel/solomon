import Foundation

/// Namespace marker pentru modulul `SolomonAnalytics`.
///
/// Modulul expune 7 analizatori care produc fapte structurate consumate
/// de moment-builderii din `SolomonMoments`. Fiecare analizor e un struct
/// `Sendable` deterministic, fără side-effects:
///
/// - `CashFlowAnalyzer`        → spec §7.2 modul 1
/// - `ObligationMapper`        → spec §7.2 modul 2
/// - `SafeToSpendCalculator`   → spec §7.2 modul 3
/// - `PatternDetector`         → spec §7.2 modul 4
/// - `SpiralDetector`          → spec §7.2 modul 5 (CRITIC)
/// - `GoalProgress`            → spec §7.2 modul 6
/// - `SubscriptionAuditor`     → spec §7.2 modul 7
public enum SolomonAnalytics {
    public static let moduleVersion = "1.0.0"
}
