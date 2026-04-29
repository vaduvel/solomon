import Foundation

/// Extrage sume financiare din text plain (corpul unui email).
///
/// Formate suportate (spec §8.11):
/// - `1.234,56 RON`   — standard RO (punct = mii, virgulă = zecimal)
/// - `1234,56 lei`    — fără separator de mii
/// - `1234.56 RON`    — format englezesc
/// - `1234 RON`       — fără zecimale
/// - `100 EUR`        — euro
/// - `€100,50`        — simbol înainte de sumă
/// - Variante cu „lei" și case-insensitive
public struct AmountExtractor: Sendable {

    public init() {}

    // MARK: - Public API

    /// Returnează toate sumele găsite în text, ordonate descrescător după valoare.
    public func extractAll(from text: String) -> [ExtractedAmount] {
        var results: [ExtractedAmount] = []
        for match in Self.amountRegex.matches(in: text, range: NSRange(text.startIndex..., in: text)) {
            if let amt = parseMatch(match, in: text) {
                results.append(amt)
            }
        }
        // Deduplicare pe valoare (aceeași sumă poate apărea de mai multe ori în email)
        var seen = Set<Int>()
        return results
            .sorted { $0.value > $1.value }
            .filter { seen.insert($0.value).inserted }
    }

    /// Returnează suma principală (cea mai mare) — în general suma tranzacției.
    public func extractPrimary(from text: String) -> ExtractedAmount? {
        extractAll(from: text).first
    }

    /// Returnează suma cel mai probabil legată de tranzacție, folosind cuvinte-cheie
    /// contextuale (total, suma, de plata, platit etc.).
    public func extractTransactionAmount(from text: String) -> ExtractedAmount? {
        // Caută suma precedată de un label financiar
        for match in Self.labeledAmountRegex.matches(in: text, range: NSRange(text.startIndex..., in: text)) {
            let rangeGroup = match.range(at: 1)
            if rangeGroup.location != NSNotFound,
               let r = Range(rangeGroup, in: text) {
                let numberStr = String(text[r])
                if let amt = parseNumberString(numberStr, fullMatch: String(text[Range(match.range, in: text)!])) {
                    return amt
                }
            }
        }
        // Fallback: suma principală
        return extractPrimary(from: text)
    }

    // MARK: - Regex patterns

    /// Pattern principal: număr în format RO/EN + monedă (RON/lei/EUR/€).
    static let amountRegex: NSRegularExpression = {
        let pattern = #"(?<![,.\d])(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{1,2})?|\d+(?:[.,]\d{1,2})?)\s*(?:RON|lei|EUR|€)"#
        guard let re = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            preconditionFailure("AmountExtractor.amountRegex: invalid pattern — fix the regex string literal")
        }
        return re
    }()

    /// Pattern secundar: label financiar urmat de sumă (captează suma în grup 1).
    static let labeledAmountRegex: NSRegularExpression = {
        let labels = "(?:total|suma|de plata|de plată|platit|plătit|valoare|cost|comanda|comandă|achitat|rambursare|transfer)"
        let number = #"(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{1,2})?|\d+(?:[.,]\d{1,2})?)"#
        let currency = #"(?:RON|lei|EUR|€)"#
        let pattern = "\(labels)[:\\s]+\(number)\\s*\(currency)"
        guard let re = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            preconditionFailure("AmountExtractor.labeledAmountRegex: invalid pattern — fix the regex string literal")
        }
        return re
    }()

    /// Pattern pentru euro cu simbol înainte (€100,50).
    static let eurPrefixRegex: NSRegularExpression = {
        let pattern = #"€\s*(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{1,2})?|\d+(?:[.,]\d{1,2})?)"#
        guard let re = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            preconditionFailure("AmountExtractor.eurPrefixRegex: invalid pattern — fix the regex string literal")
        }
        return re
    }()

    // MARK: - Private parsing

    private func parseMatch(_ match: NSTextCheckingResult, in text: String) -> ExtractedAmount? {
        guard let fullRange = Range(match.range, in: text) else { return nil }
        let fullString = String(text[fullRange]).trimmingCharacters(in: .whitespaces)

        // Detectează moneda
        let upper = fullString.uppercased()
        let currency: AmountCurrency = upper.contains("EUR") || upper.contains("€") ? .eur : .ron

        // Extrage numărul (tot ce nu e monedă/spații)
        let numberPart = fullString
            .replacingOccurrences(of: "RON", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "lei", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "EUR", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "€", with: "")
            .trimmingCharacters(in: .whitespaces)

        return parseNumberString(numberPart, currency: currency, fullMatch: fullString)
    }

    private func parseNumberString(
        _ raw: String,
        currency: AmountCurrency = .ron,
        fullMatch: String = ""
    ) -> ExtractedAmount? {
        let cleaned = raw.trimmingCharacters(in: .whitespaces)
        guard !cleaned.isEmpty else { return nil }

        let value = parseRomanianNumber(cleaned)
        guard value > 0 else { return nil }

        return ExtractedAmount(value: value, currency: currency, rawString: fullMatch.isEmpty ? raw : fullMatch)
    }

    /// Parsează un număr în format RO sau EN, returnează valoarea rotunjită ca Int.
    func parseRomanianNumber(_ s: String) -> Int {
        // Cazuri speciale: dacă avem ambele tipuri de separatori
        let hasDot = s.contains(".")
        let hasComma = s.contains(",")

        var normalized = s

        if hasDot && hasComma {
            // Ambii separatori: determină care e mii și care e zecimal
            let dotPos = s.lastIndex(of: ".")!
            let commaPos = s.lastIndex(of: ",")!

            if commaPos > dotPos {
                // Ultimul separator e virgula → virgula = zecimal, punct = mii
                // Ex: "1.234,56" → "1234.56"
                normalized = s
                    .replacingOccurrences(of: ".", with: "")
                    .replacingOccurrences(of: ",", with: ".")
            } else {
                // Ultimul separator e punctul → punct = zecimal, virgulă = mii
                // Ex: "1,234.56" → "1234.56"
                normalized = s.replacingOccurrences(of: ",", with: "")
            }
        } else if hasComma {
            // Doar virgulă — determină dacă e zecimal sau mii
            let parts = s.components(separatedBy: ",")
            if parts.count == 2, parts[1].count == 3 {
                // "1,234" → mii separator → "1234"
                normalized = s.replacingOccurrences(of: ",", with: "")
            } else {
                // "1,56" sau "1234,56" → zecimal → "1.56" sau "1234.56"
                normalized = s.replacingOccurrences(of: ",", with: ".")
            }
        } else if hasDot {
            // Doar punct — similar logicii cu virgulă
            let parts = s.components(separatedBy: ".")
            if parts.count == 2, parts[1].count == 3 {
                // "1.234" → mii separator → "1234"
                normalized = s.replacingOccurrences(of: ".", with: "")
            }
            // altfel lasă ca atare (e format englezesc "1234.56")
        }

        guard let dbl = Double(normalized) else { return 0 }
        return Int(dbl.rounded())
    }
}
