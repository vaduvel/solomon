import Foundation
import SolomonCore
import SolomonStorage

public enum SolomonAnalytics {
    public static let modules: [String] = [
        "CashFlowAnalyzer",
        "ObligationMapper",
        "SafeToSpendCalculator",
        "PatternDetector",
        "SpiralDetector",
        "GoalProgress",
        "SubscriptionAuditor"
    ]
}
