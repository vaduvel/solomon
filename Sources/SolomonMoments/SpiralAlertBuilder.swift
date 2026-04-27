import Foundation
import SolomonCore

/// Builder pentru Momentul 7 — Spiral Alert (spec §6.8).
///
/// Alertă de urgență când Solomon detectează o spirală de datorii (spiralScore >= 2).
/// LLM-ul primește factorii detectați, severitatea și un plan de recuperare în 3 pași.
/// Output: max 200 cuvinte, ton empatic dar urgent — nu alarmist.
public struct SpiralAlertBuilder: MomentBuilder {
    public typealias Context = SpiralAlertContext

    public let momentType: MomentType = .spiralAlert

    public var systemPrompt: String {
        """
        Ești Solomon. Am detectat semnale de stres financiar la utilizator. \
        Bazat pe contextul JSON, prezintă situația cu empatie: \
        1. Recunoaște că `narrative_summary` descrie o situație dificilă \
        2. Prezintă primii 1-2 pași din `recovery_plan` (step1, step2) cu acțiunile concrete \
        3. Dacă `csalb_relevant` e true, menționează că CSALB poate media renegocierea datoriilor \
        Nu dramatiza, nu judeca — Solomon e un aliat, nu un judecător. \
        Tonul: cald, practic, orientat spre soluții. Adresare: `user.addressing`. \
        Maxim \(MomentType.spiralAlert.maxWords) cuvinte. Nu inventa factori sau soluții.
        """
    }

    public init() {}
}
