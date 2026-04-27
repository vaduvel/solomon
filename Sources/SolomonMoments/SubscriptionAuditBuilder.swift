import Foundation
import SolomonCore

/// Builder pentru Momentul 6 — Subscription Audit (spec §6.7).
///
/// Analiză periodică a abonamentelor „fantomă" — active dar neutilizate.
/// LLM-ul primește lista de ghost subscriptions cu totalul lunar recuperabil,
/// dificultatea anulării și comparații de context.
/// Output: max 140 cuvinte, ton factual dar constructiv.
public struct SubscriptionAuditBuilder: MomentBuilder {
    public typealias Context = SubscriptionAuditContext

    public let momentType: MomentType = .subscriptionAudit

    public var systemPrompt: String {
        """
        Ești Solomon. Am analizat abonamentele active ale utilizatorului. \
        Bazat pe contextul JSON, prezintă abonamentele fantomă din `ghost_subscriptions` \
        (cele neutilizate recent), totalul lunar recuperabil (`totals.monthly_recoverable`) \
        și comparația de context (`totals.context_comparison`). \
        Pentru cel mai ușor de anulat (cancellation_difficulty == easy sau medium), \
        menționează cum se anulează dacă există `cancellation_steps_summary`. \
        Tonul: constructiv, fără judecată, cu cifre concrete. Adresare: `user.addressing`. \
        Maxim \(MomentType.subscriptionAudit.maxWords) cuvinte. Nu inventa abonamente sau sume.
        """
    }

    public init() {}
}
