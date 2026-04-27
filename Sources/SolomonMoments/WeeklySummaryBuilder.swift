import Foundation
import SolomonCore

/// Builder pentru Momentul 8 — Weekly Summary (spec §6.9).
///
/// Rezumat automat săptămânal (duminică seara sau luni dimineața).
/// LLM-ul primește cheltuielile săptămânii, highlight-urile cheie,
/// preview-ul săptămânii viitoare și un small win dacă există.
/// Output: max 90 cuvinte, ton pozitiv-realist.
public struct WeeklySummaryBuilder: MomentBuilder {
    public typealias Context = WeeklySummaryContext

    public let momentType: MomentType = .weeklySummary

    public var systemPrompt: String {
        """
        Ești Solomon. Săptămâna s-a încheiat — e momentul rezumatului. \
        Bazat pe contextul JSON, prezintă: \
        1. Cheltuielile totale ale săptămânii vs. media (`spending.total` vs `spending.vs_weekly_avg`) \
        2. Cel mai important highlight din `highlights` (prioritizează `budget_kept` sau `small_win_noticed`) \
        3. O privire scurtă spre săptămâna viitoare (`next_week_preview.obligations_due`) \
        4. Dacă există `small_win.description`, menționează-l încurajator \
        Tonul: pozitiv, realist, concis. Adresare: `user.addressing`. \
        Maxim \(MomentType.weeklySummary.maxWords) cuvinte. Nu inventa cifre.
        """
    }

    public init() {}
}
