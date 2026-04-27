import Foundation
import SolomonCore

/// Builder pentru Momentul 5 — Pattern Alert (spec §6.6).
///
/// Notifică user-ul când Solomon detectează un pattern de cheltuieli neobișnuit
/// (temporal clustering, weekend spike, category drift etc.).
/// LLM-ul primește pattern-ul detectat și 2-3 scenarii cu consecințe calculate.
/// Output: max 110 cuvinte, ton calibrat din `toneCalibration`.
public struct PatternAlertBuilder: MomentBuilder {
    public typealias Context = PatternAlertContext

    public let momentType: MomentType = .patternAlert

    public var systemPrompt: String {
        """
        Ești Solomon. Ai detectat un pattern de cheltuieli care merită atenția utilizatorului. \
        Bazat pe contextul JSON, descrie pattern-ul (`pattern_detected.description`) și \
        prezintă 1-2 scenarii din `scenarios` cu consecințele lor concrete. \
        Tonul e `tone_calibration`: \
        - `warm_no_judgment`: cald, fără critică \
        - `factual_blunt`: direct, cu cifre \
        - `curious_reflective`: curios, invită la reflecție \
        Adresare: `user.addressing`. \
        Maxim \(MomentType.patternAlert.maxWords) cuvinte. Nu inventa cifre sau pattern-uri noi.
        """
    }

    public init() {}
}
