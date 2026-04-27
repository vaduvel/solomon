import Foundation

// MARK: - BankNotificationParser
//
// Parseaza textul brut al notificărilor push de la băncile românești
// și returnează un `Transaction` gata de stocat în SolomonStorage.
//
// Flux: iOS Shortcuts → solomon://transaction?raw=TEXT → parser → Transaction
//
// Bănci suportate: BT, ING, Raiffeisen, BCR, Revolut, CEC, Alpha, Garanti BBVA
// Valute: RON, EUR, USD, GBP, CHF, HUF
//
// Utilizare:
//   let tx = BankNotificationParser.parse(raw: "Plată 65,00 RON la Glovo")
//   // → Transaction(amount: 65.00 RON, merchant: "Glovo", direction: .outgoing, ...)

public enum BankNotificationParser {

    // MARK: - Public API

    /// Parseaza textul brut al unei notificări bancare.
    /// - Returns: `Transaction` gata de stocat, sau `nil` dacă textul nu e recunoscut.
    public static func parse(raw: String, date: Date = Date()) -> Transaction? {
        let normalized = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\u{00A0}", with: " ") // non-breaking space

        guard let extracted = extractAmountAndMerchant(from: normalized) else { return nil }

        let category = MerchantCategoryMatcher.category(for: extracted.merchant ?? "")
        let direction = determineDirection(from: normalized, amount: extracted.amount)

        // Money stochează sume ca Int RON (spec §6.1).
        // Valutele non-RON sunt stocate la valoarea nominală (fără conversie) — v1 limitation.
        let moneyAmount = Money.fromRON(NSDecimalNumber(decimal: extracted.amount).doubleValue)

        return Transaction(
            id: UUID(),
            date: date,
            amount: moneyAmount,
            direction: direction,
            category: category,
            merchant: extracted.merchant.map { cleanMerchant($0) },
            description: "[\(extracted.currency)] \(String(normalized.prefix(180)))",
            source: .notificationParsed,
            categorizationConfidence: category == .unknown ? 0.4 : 0.75
        )
    }

    /// Detectează dacă textul arată ca o notificare bancară (nu neapărat parsabilă complet).
    public static func looksLikeBankNotification(_ raw: String) -> Bool {
        let lower = raw.lowercased()
        let hasMoney = amountPattern.firstMatch(in: raw, range: NSRange(raw.startIndex..., in: raw)) != nil
        let hasKeyword = bankKeywords.contains { lower.contains($0) }
        return hasMoney && hasKeyword
    }

    // MARK: - Internal Types

    struct Extracted {
        let amount: Decimal
        let currency: String
        let merchant: String?
    }

    // MARK: - Patterns

    /// Capturează suma și valuta: `65,00 RON`, `65.00 EUR`, `1.234,56 RON`
    static let amountPattern: NSRegularExpression = {
        // Grup 1: suma (cu punct mii + virgulă/punct zecimal)
        // Grup 2: valuta
        let pattern = #"(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{1,2})?|\d+(?:[.,]\d{1,2})?)\s*(RON|EUR|USD|GBP|CHF|HUF)"#
        return try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
    }()

    static let bankKeywords = [
        "plată", "plata", "platit", "plătit", "plătit",
        "tranzacție", "tranzactie", "debitare", "credit",
        "card", "transfer", "retragere", "retras",
        "ai plătit", "ai platit", "ai efectuat",
        "payment", "purchase"
    ]

    // MARK: - Amount + Merchant Extraction

    static func extractAmountAndMerchant(from text: String) -> Extracted? {
        let range = NSRange(text.startIndex..., in: text)
        guard let match = amountPattern.firstMatch(in: text, range: range) else { return nil }

        guard
            let amountRange = Range(match.range(at: 1), in: text),
            let currencyRange = Range(match.range(at: 2), in: text)
        else { return nil }

        let amountStr = String(text[amountRange])
        let currency = String(text[currencyRange]).uppercased()

        guard let amount = parseDecimal(amountStr) else { return nil }

        // Extrage merchantul din textul de după suma+valuta
        let afterMatch: String
        if let matchEnd = Range(match.range, in: text).map({ $0.upperBound }) {
            afterMatch = String(text[matchEnd...]).trimmingCharacters(in: .whitespaces)
        } else {
            afterMatch = ""
        }

        let merchant = extractMerchant(from: afterMatch, fullText: text)

        return Extracted(amount: amount, currency: currency, merchant: merchant)
    }

    // MARK: - Merchant Extraction

    /// Extrage merchantul din restul textului după sumă.
    static func extractMerchant(from afterAmount: String, fullText: String) -> String? {
        // Prefixe care precedă merchantul
        let prefixes = [
            "la ", "lui ", "at ", "la: ", "- ", "@ ",
            "catre ", "către ", "beneficiar: "
        ]

        var source = afterAmount

        // Elimina prefixe comune
        for prefix in prefixes {
            if source.lowercased().hasPrefix(prefix) {
                source = String(source.dropFirst(prefix.count))
                    .trimmingCharacters(in: .whitespaces)
                break
            }
        }

        // Elimina sufixe tip dată/ora
        let datePatterns = [
            #"\s+\d{2}[./]\d{2}[./]\d{4}.*$"#,   // 27/04/2026
            #"\s+\d{2}[./]\d{2}[./]\d{2}.*$"#,   // 27/04/26
            #"\s+\d{2}:\d{2}.*$"#,                 // 14:30
            #"\s+la ora.*$"#,
        ]
        var result = source
        for dp in datePatterns {
            if let r = try? NSRegularExpression(pattern: dp, options: .caseInsensitive) {
                let cleaned = r.stringByReplacingMatches(
                    in: result,
                    range: NSRange(result.startIndex..., in: result),
                    withTemplate: ""
                )
                result = cleaned.trimmingCharacters(in: .whitespaces)
            }
        }

        // Elimina codul de referință (alfanumeric lung)
        if let refPattern = try? NSRegularExpression(
            pattern: #"\s+[A-Z0-9]{8,}$"#,
            options: []
        ) {
            let cleaned = refPattern.stringByReplacingMatches(
                in: result,
                range: NSRange(result.startIndex..., in: result),
                withTemplate: ""
            ).trimmingCharacters(in: .whitespaces)
            result = cleaned
        }

        let trimmed = result.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    // MARK: - Direction Detection

    static func determineDirection(from text: String, amount: Decimal) -> FlowDirection {
        let lower = text.lowercased()
        let incomingKeywords = [
            "salariu", "salary", "transfer primit", "primit",
            "alimentare cont", "depunere", "virament primit",
            "credit", "reîncărcare", "cashback", "refund",
            "rambursare", "retras din atm" // ATM withdrawal still outgoing — handled below
        ]
        let outgoingKeywords = [
            "plată", "platit", "plătit", "debitare", "retragere",
            "transfer trimis", "payment", "purchase", "cumparat"
        ]

        let hasIncoming = incomingKeywords.contains { lower.contains($0) }
        let hasOutgoing = outgoingKeywords.contains { lower.contains($0) }

        // ATM withdrawal e outgoing chiar dacă conține "retras"
        if lower.contains("retragere") || lower.contains("atm") { return .outgoing }

        if hasIncoming && !hasOutgoing { return .incoming }
        return .outgoing // default: cheltuială
    }

    // MARK: - Decimal Parsing

    /// Convertește `"65,00"`, `"65.00"`, `"1.234,56"`, `"1,234.56"` → Decimal
    ///
    /// Strategie: ultimul separator determină formatul.
    /// - Ultimul separator e `,` → format european (`.` = mii, `,` = zecimal)
    /// - Ultimul separator e `.` → format standard (`,` = mii, `.` = zecimal)
    static func parseDecimal(_ s: String) -> Decimal? {
        let cleaned = s.trimmingCharacters(in: .whitespaces)

        // Găsim ultimul separator (virgulă sau punct)
        let lastComma = cleaned.lastIndex(of: ",")
        let lastDot   = cleaned.lastIndex(of: ".")

        let normalized: String

        switch (lastComma, lastDot) {
        case (nil, nil):
            // "250" — fără separator
            normalized = cleaned

        case (let c?, nil):
            // "65,00" sau "1.234" cu virgulă la final
            // Singura virgulă → separator zecimal
            normalized = cleaned.replacingOccurrences(of: ",", with: ".")

        case (nil, let d?):
            // "65.00" — deja în format standard
            // Dar "1,234" (fără punct) nu ajunge aici
            _ = d
            normalized = cleaned

        case (let c?, let d?):
            if c > d {
                // Ultima e virgulă → European: "1.234,56"
                // Scoatem punctele (mii), înlocuim virgula cu punct
                normalized = cleaned
                    .replacingOccurrences(of: ".", with: "")
                    .replacingOccurrences(of: ",", with: ".")
            } else {
                // Ultimul e punct → American: "1,234.56"
                // Scoatem virgulele (mii)
                normalized = cleaned.replacingOccurrences(of: ",", with: "")
            }
        }

        return Decimal(string: normalized)
    }

    // MARK: - Merchant Cleanup

    /// Normalizează merchantul: title case, elimina SCREAMING CAPS.
    static func cleanMerchant(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        // Dacă e ALL CAPS și mai lung de 3 caractere, facem title case
        if trimmed == trimmed.uppercased() && trimmed.count > 3 {
            return trimmed.capitalized
        }
        return trimmed
    }
}
