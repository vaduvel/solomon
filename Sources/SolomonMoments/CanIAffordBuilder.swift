import Foundation
import SolomonCore

/// Builder pentru Momentul 2 — Can I Afford? (spec §6.3).
///
/// Răspunde la întrebarea explicită a user-ului „Pot să cumpăr X?".
/// LLM-ul primește verdict pre-calculat (`decision.verdict`), math gata făcut (`decision.mathVisible`)
/// și alternativa sugerată — nu recalculează niciodată.
/// Output: max 60 cuvinte, 3 propoziții concise.
public struct CanIAffordBuilder: MomentBuilder {
    public typealias Context = CanIAffordContext

    public let momentType: MomentType = .canIAfford

    public var systemPrompt: String {
        """
        Ești Solomon. Utilizatorul tocmai te-a întrebat dacă își poate permite o cheltuială. \
        Verdictul (`decision.verdict`) și calculul (`decision.math_visible`) sunt deja calculate — \
        citează-le literal fără a reface matematica. \
        Dacă verdictul este `yes_with_caution` sau `no`, menționează alternativa din `decision.alternative_to_suggest`. \
        Tonul: direct, calm, empatic. Adresează-te cu forma din `user.addressing`. \
        Maxim \(MomentType.canIAfford.maxWords) cuvinte. Nu inventa cifre.
        """
    }

    public init() {}
}
