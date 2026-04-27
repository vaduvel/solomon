import Foundation
import SolomonCore

public struct SubscriptionAuditReport: Sendable, Hashable, Codable {
    public var ghostSubscriptions: [Subscription]
    public var activeSubscriptions: [Subscription]
    public var monthlyRecoverable: Money
    public var annualRecoverable: Money
    public var monthlyKeptTotal: Money
    public var annualKeptTotal: Money

    public var ghostCount: Int { ghostSubscriptions.count }

    public init(ghostSubscriptions: [Subscription], activeSubscriptions: [Subscription],
                monthlyRecoverable: Money, annualRecoverable: Money,
                monthlyKeptTotal: Money, annualKeptTotal: Money) {
        self.ghostSubscriptions = ghostSubscriptions
        self.activeSubscriptions = activeSubscriptions
        self.monthlyRecoverable = monthlyRecoverable
        self.annualRecoverable = annualRecoverable
        self.monthlyKeptTotal = monthlyKeptTotal
        self.annualKeptTotal = annualKeptTotal
    }
}

/// Auditează abonamentele pentru a găsi „ghost-uri" (>30 zile fără utilizare).
/// Spec §7.2 modul 7, §6.7 (Subscription Auditor moment).
public struct SubscriptionAuditor: Sendable {

    public init() {}

    public func audit(subscriptions: [Subscription]) -> SubscriptionAuditReport {
        let ghosts = subscriptions.filter(\.isGhost)
        let active = subscriptions.filter { !$0.isGhost }

        let monthlyRecoverable = ghosts.reduce(Money(0)) { $0 + $1.amountMonthly }
        let annualRecoverable = ghosts.reduce(Money(0)) { $0 + $1.amountAnnual }
        let monthlyKept = active.reduce(Money(0)) { $0 + $1.amountMonthly }
        let annualKept = active.reduce(Money(0)) { $0 + $1.amountAnnual }

        // Sortăm ghost-urile descrescător după impact lunar — primele să fie atacate primele.
        let sortedGhosts = ghosts.sorted {
            if $0.amountMonthly == $1.amountMonthly {
                return ($0.lastUsedDaysAgo ?? 0) > ($1.lastUsedDaysAgo ?? 0)
            }
            return $0.amountMonthly > $1.amountMonthly
        }

        return SubscriptionAuditReport(
            ghostSubscriptions: sortedGhosts,
            activeSubscriptions: active,
            monthlyRecoverable: monthlyRecoverable,
            annualRecoverable: annualRecoverable,
            monthlyKeptTotal: monthlyKept,
            annualKeptTotal: annualKept
        )
    }
}
