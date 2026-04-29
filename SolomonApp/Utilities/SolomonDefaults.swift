import Foundation

// MARK: - SolomonDefaults
//
// FAZA C3: Centralizează constantele de fallback financiare folosite când
// userul nu a completat încă un câmp în profil.  Înainte erau hardcoded
// `5000` în 4 locuri diferite — modificarea unui prag impunea sync manual.

public enum SolomonDefaults {
    /// Salariu mid-point fallback (RON) — folosit DOAR când profilul lipsește,
    /// pentru a putea afișa procentaje de obligații / Safe-to-Spend cu un
    /// estimate în loc de "—".
    public static let salaryMidpointFallbackRON: Int = 5000

    /// Buffer financiar minim recomandat (RON) păstrat în Safe-to-Spend.
    public static let minimumBufferRON: Int = 50

    /// Threshold "buget strâns" — RON/zi sub care declanșăm warning-ul UI.
    /// Notă: în SafeToSpendCalculator ar trebui să devină relativ la venit (FAZA C5).
    public static let tightBudgetPerDayRON: Int = 30
}
