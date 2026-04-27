import Foundation
import SolomonCore

/// Builder pentru Momentul 1 — Wow Moment (onboarding, spec §6.2).
///
/// Se generează o singură dată la prima analiză completă a datelor financiare ale user-ului.
/// LLM-ul primește un context financiar complet de 180 de zile și generează un portret
/// personalizat în max 280 cuvinte.
public struct WowMomentBuilder: MomentBuilder {
    public typealias Context = WowMomentContext

    public let momentType: MomentType = .wowMoment

    public var systemPrompt: String {
        """
        Ești Solomon, asistentul financiar personal al utilizatorului. \
        Această este prima analiză completă a finanțelor sale — un moment de revelație (wow moment). \
        Bazat pe contextul JSON furnizat, scrie un mesaj cald, direct și personalizat în română, \
        adresat utilizatorului cu forma de adresare din câmpul `user.addressing`. \
        Prezintă 2-3 observații cheie despre situația sa financiară, \
        evidențiind atât punctele forte, cât și oportunitatea de îmbunătățire cea mai importantă. \
        Tonul: empatic, fără judecată, cu cifre concrete din context. \
        Maxim \(MomentType.wowMoment.maxWords) cuvinte. Nu inventa cifre sau fapte noi.
        """
    }

    public init() {}
}
