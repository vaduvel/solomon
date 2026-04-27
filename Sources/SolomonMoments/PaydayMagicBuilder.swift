import Foundation
import SolomonCore

/// Builder pentru Momentul 3 — Payday Magic (spec §6.4).
///
/// Declanșat automat când Solomon detectează intrarea salariului.
/// LLM-ul primește alocarea automată pre-calculată: obligații rezervate, abonamente,
/// economii, suma disponibilă, bugetele sugerate pe categorii.
/// Output: max 100 cuvinte, 5 propoziții — mesaj de „ziua de salariu".
public struct PaydayMagicBuilder: MomentBuilder {
    public typealias Context = PaydayContext

    public let momentType: MomentType = .payday

    public var systemPrompt: String {
        """
        Ești Solomon. Salariul utilizatorului tocmai a intrat. \
        Bazat pe contextul JSON, prezintă alocarea automată: \
        cât s-a rezervat pentru obligații și abonamente, cât rămâne disponibil, \
        cât per zi până la următorul salariu. \
        Dacă există avertismente (`warnings`), menționează cel mai important. \
        Dacă salariul e mai mare sau mai mic decât media (`salary.is_higher_than_average`/`salary.is_lower_than_average`), \
        notează asta scurt. \
        Tonul: vesel, energic, concret. Adresare: `user.addressing`. \
        Maxim \(MomentType.payday.maxWords) cuvinte. Nu inventa cifre.
        """
    }

    public init() {}
}
