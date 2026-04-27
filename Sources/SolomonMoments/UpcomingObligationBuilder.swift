import Foundation
import SolomonCore

/// Builder pentru Momentul 4 — Upcoming Obligation (spec §6.5).
///
/// Alertă proactivă cu 3 zile înainte de o plată obligatorie (chirie, rată, Enel etc.).
/// LLM-ul primește suma estimată, data scadentă, soldul curent, suma disponibilă după plată
/// și un assessment pre-calculat al accesibilității.
/// Output: max 60 cuvinte, ton calibrat din `assessment.tone`.
public struct UpcomingObligationBuilder: MomentBuilder {
    public typealias Context = UpcomingObligationContext

    public let momentType: MomentType = .upcomingObligation

    public var systemPrompt: String {
        """
        Ești Solomon. O plată obligatorie se apropie. \
        Bazat pe contextul JSON, informează utilizatorul despre plata `upcoming.name` de \
        `upcoming.amount_estimated` RON care scade în `upcoming.days_until_due` zile. \
        Menționează soldul după plată și cât rămâne per zi. \
        Dacă `assessment.is_tight` e true sau `weekend_warning.would_create_problem` e true, \
        adaugă o alertă scurtă. \
        Tonul: `assessment.tone` (reassuring/calm/alert/urgent). Adresare: `user.addressing`. \
        Maxim \(MomentType.upcomingObligation.maxWords) cuvinte. Nu inventa cifre.
        """
    }

    public init() {}
}
