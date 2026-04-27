import Foundation
import SolomonCore

// MARK: - Scam match result

/// Rezultatul unui scan de scam pattern pe un text dat.
public struct ScamMatchResult: Sendable {
    /// Pattern-ul găsit.
    public var pattern: ScamPattern
    /// Scorul de risc normalizat [0, 1]: suspicious=0.4, likelyScam=0.7, definiteScam=1.0.
    public var riskScore: Double
    /// True dacă utilizatorul ar trebui avertizat imediat.
    public var shouldAlert: Bool { riskScore >= 0.7 }

    public init(pattern: ScamPattern) {
        self.pattern = pattern
        switch pattern.severity {
        case .suspicious:   riskScore = 0.4
        case .likelyScam:   riskScore = 0.7
        case .definiteScam: riskScore = 1.0
        }
    }
}

// MARK: - Matcher

/// Wrapper peste `ScamPatterns` din SolomonCore — detectează pattern-uri de scam în texte libere.
///
/// Implementare fără stare, thread-safe, injectabil în teste.
public struct ScamPatternMatcher: Sendable {

    public init() {}

    // MARK: - Single text

    /// Scanează textul și returnează cel mai sever pattern găsit, sau `nil` dacă nu se găsește nimic.
    ///
    /// Match-ul e case-insensitive + diacritic-insensitive (românesc).
    public func match(in text: String) -> ScamMatchResult? {
        guard let pattern = ScamPatterns.match(in: text) else { return nil }
        return ScamMatchResult(pattern: pattern)
    }

    /// Returnează *toate* pattern-urile care se regăsesc în text, sortate descrescător după severitate.
    public func allMatches(in text: String) -> [ScamMatchResult] {
        let lowered = text.lowercased().folding(options: .diacriticInsensitive, locale: nil)
        var results: [ScamMatchResult] = []
        for pattern in ScamPatterns.all {
            let hit = pattern.keywords.contains { lowered.contains($0) }
            if hit {
                results.append(ScamMatchResult(pattern: pattern))
            }
        }
        return results.sorted { $0.pattern.severity > $1.pattern.severity }
    }

    // MARK: - Multi-field scan (subiect + body)

    /// Scanează subiect + corp email împreună (concatenate cu spațiu).
    public func matchEmail(subject: String, body: String) -> ScamMatchResult? {
        match(in: subject + " " + body)
    }

    /// Scanează un URL (host + path + query) pentru pattern-uri de tip phishing.
    public func matchURL(_ url: URL) -> ScamMatchResult? {
        let text = [url.host, url.path, url.query]
            .compactMap { $0 }
            .joined(separator: " ")
        return match(in: text)
    }

    // MARK: - Category helpers

    /// Toate pattern-urile dintr-o categorie.
    public func patterns(for category: ScamCategory) -> [ScamPattern] {
        ScamPatterns.patterns(in: category)
    }

    /// True dacă textul conține ORICE semnal de risc.
    public func hasAnyRisk(in text: String) -> Bool {
        match(in: text) != nil
    }

    /// True dacă textul conține un scam definit (certitudine maximă).
    public func isDefiniteScam(_ text: String) -> Bool {
        match(in: text)?.pattern.severity == .definiteScam
    }
}
