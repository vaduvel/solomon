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

    // MARK: - Decimal format hint

    /// Sugerează formatul zecimal al sumei din notificare.
    ///
    /// - `auto`: heuristic bazat pe ultimul separator (comportament default)
    /// - `european`: punct = mii, virgulă = zecimale (BT, BCR, Raiffeisen, ING RO, CEC)
    /// - `us`:      virgulă = mii, punct = zecimale (Revolut UK/US locale)
    public enum DecimalFormatHint: Sendable {
        case auto
        case european
        case us

        /// Inferă formatul din banca primară a userului.
        public static func from(bank: Bank) -> DecimalFormatHint {
            switch bank {
            case .revolut: return .us   // Revolut afișează US format în notificări
            default: return .european   // Toate băncile RO: punct=mii, virgulă=zecimal
            }
        }
    }

    // MARK: - Public API

    /// Parseaza textul brut al unei notificări bancare.
    ///
    /// - Parameters:
    ///   - raw: Textul notificării push.
    ///   - date: Data tranzacției (default: acum).
    ///   - decimalHint: Formatul zecimal așteptat (default `.auto` — heuristic).
    ///                  Trimite `.european` pentru băncile RO clasice sau `.us` pentru Revolut.
    /// - Returns: `Transaction` gata de stocat, sau `nil` dacă textul nu e recunoscut.
    public static func parse(
        raw: String,
        date: Date = Date(),
        decimalHint: DecimalFormatHint = .auto
    ) -> Transaction? {
        let normalized = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\u{00A0}", with: " ") // non-breaking space

        guard let extracted = extractAmountAndMerchant(from: normalized, decimalHint: decimalHint) else { return nil }

        // IFN check first — dacă merchant matches IFN registry, override la loansIFN
        let merchantClean = extracted.merchant ?? ""
        let ifnRecord = IFNDatabase.all.first { ifn in
            merchantClean.lowercased().contains(ifn.name.lowercased())
        }
        let category: TransactionCategory = ifnRecord != nil
            ? .loansIFN
            : MerchantCategoryMatcher.category(for: merchantClean)
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

    /// Returnează IFNRecord dacă tranzacția e debit din IFN, altfel nil.
    /// Folosit pentru a declanșa push alert imediat după ingestie.
    public static func detectIFNRecord(in text: String) -> IFNRecord? {
        let lower = text.lowercased()
        return IFNDatabase.all.first { ifn in
            lower.contains(ifn.name.lowercased())
        }
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

    static func extractAmountAndMerchant(
        from text: String,
        decimalHint: DecimalFormatHint = .auto
    ) -> Extracted? {
        let range = NSRange(text.startIndex..., in: text)
        guard let match = amountPattern.firstMatch(in: text, range: range) else { return nil }

        guard
            let amountRange = Range(match.range(at: 1), in: text),
            let currencyRange = Range(match.range(at: 2), in: text)
        else { return nil }

        let amountStr = String(text[amountRange])
        let currency = String(text[currencyRange]).uppercased()

        guard let amount = parseDecimal(amountStr, hint: decimalHint) else { return nil }

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
    /// - Parameter hint: `.european` forțează virgula=decimal; `.us` forțează punct=decimal;
    ///                   `.auto` folosește heuristic bazat pe ultimul separator.
    static func parseDecimal(_ s: String, hint: DecimalFormatHint = .auto) -> Decimal? {
        let cleaned = s.trimmingCharacters(in: .whitespaces)

        // Hint explicit — rezolvă ambiguitatea "1.234" / "1,234"
        if hint == .european {
            let normalized = cleaned
                .replacingOccurrences(of: ".", with: "")   // punct = mii separator
                .replacingOccurrences(of: ",", with: ".")  // virgulă = zecimal
            return Decimal(string: normalized)
        }
        if hint == .us {
            let normalized = cleaned
                .replacingOccurrences(of: ",", with: "")  // virgulă = mii separator
            return Decimal(string: normalized)
        }

        // .auto — heuristic bazat pe ultimul separator (comportament vechi)
        let lastComma = cleaned.lastIndex(of: ",")
        let lastDot   = cleaned.lastIndex(of: ".")

        let normalized: String

        switch (lastComma, lastDot) {
        case (nil, nil):
            // "250" — fără separator
            normalized = cleaned

        case (_?, nil):
            // "65,00" sau "1.234" cu virgulă finală → separator zecimal
            normalized = cleaned.replacingOccurrences(of: ",", with: ".")

        case (nil, _?):
            // "65.00" — format standard
            normalized = cleaned

        case (let c?, let d?) where c > d:
            // Ultima e virgulă → European: "1.234,56"
            normalized = cleaned
                .replacingOccurrences(of: ".", with: "")
                .replacingOccurrences(of: ",", with: ".")

        case (_?, _?):
            // Ultimul e punct → American: "1,234.56"
            normalized = cleaned.replacingOccurrences(of: ",", with: "")
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
