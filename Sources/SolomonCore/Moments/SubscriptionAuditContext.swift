import Foundation

public struct GhostSubscriptionDetail: Codable, Sendable, Hashable {
    public var name: String
    public var amountMonthly: Money
    public var amountAnnual: Money
    public var lastUsedDaysAgo: Int
    public var cancellationDifficulty: CancellationDifficulty
    public var cancellationUrl: URL?
    public var cancellationStepsSummary: String?
    public var cancellationWarning: String?
    public var alternativeSuggestion: String?

    public init(name: String, amountMonthly: Money, amountAnnual: Money, lastUsedDaysAgo: Int,
                cancellationDifficulty: CancellationDifficulty,
                cancellationUrl: URL? = nil, cancellationStepsSummary: String? = nil,
                cancellationWarning: String? = nil, alternativeSuggestion: String? = nil) {
        self.name = name
        self.amountMonthly = amountMonthly
        self.amountAnnual = amountAnnual
        self.lastUsedDaysAgo = lastUsedDaysAgo
        self.cancellationDifficulty = cancellationDifficulty
        self.cancellationUrl = cancellationUrl
        self.cancellationStepsSummary = cancellationStepsSummary
        self.cancellationWarning = cancellationWarning
        self.alternativeSuggestion = alternativeSuggestion
    }
}

public struct SubscriptionAuditTotals: Codable, Sendable, Hashable {
    public var monthlyRecoverable: Money
    public var annualRecoverable: Money
    public var contextComparison: String

    public init(monthlyRecoverable: Money, annualRecoverable: Money, contextComparison: String) {
        self.monthlyRecoverable = monthlyRecoverable
        self.annualRecoverable = annualRecoverable
        self.contextComparison = contextComparison
    }
}

public struct ActiveSubscriptionsKept: Codable, Sendable, Hashable {
    public var count: Int
    public var monthlyTotal: Money
    public var examples: [String]

    public init(count: Int, monthlyTotal: Money, examples: [String]) {
        self.count = count
        self.monthlyTotal = monthlyTotal
        self.examples = examples
    }
}

// MARK: - Context principal (spec §6.7)

public struct SubscriptionAuditContext: Codable, Sendable, Hashable {
    public let momentType: MomentType
    public var user: MomentUser
    public var auditPeriodDays: Int
    public var ghostSubscriptions: [GhostSubscriptionDetail]
    public var totals: SubscriptionAuditTotals
    public var activeSubscriptionsKept: ActiveSubscriptionsKept

    public init(user: MomentUser, auditPeriodDays: Int = 30,
                ghostSubscriptions: [GhostSubscriptionDetail],
                totals: SubscriptionAuditTotals,
                activeSubscriptionsKept: ActiveSubscriptionsKept) {
        self.momentType = .subscriptionAudit
        self.user = user
        self.auditPeriodDays = auditPeriodDays
        self.ghostSubscriptions = ghostSubscriptions
        self.totals = totals
        self.activeSubscriptionsKept = activeSubscriptionsKept
    }
}
