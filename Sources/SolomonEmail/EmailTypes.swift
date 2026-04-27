import Foundation
import SolomonCore

// MARK: - Input

/// Un email primit — input brut al parser-ului.
/// Email-ul original NU se stochează; doar datele extrase sunt persistate.
public struct EmailMessage: Sendable {
    /// Adresa completă de sender (e.g. "no-reply@glovoapp.com").
    public var from: String
    public var subject: String
    /// Textul plain al body-ului (HTML deja strip-uit de caller).
    public var bodyText: String
    public var date: Date

    public init(from: String, subject: String, bodyText: String, date: Date = Date()) {
        self.from = from.lowercased().trimmingCharacters(in: .whitespaces)
        self.subject = subject
        self.bodyText = bodyText
        self.date = date
    }

    /// Domeniu sender (e.g. "glovoapp.com").
    public var senderDomain: String {
        from.split(separator: "@").last.map(String.init) ?? ""
    }
}

// MARK: - Extracted amount

/// Suma extrasă din text + moneda ei.
public struct ExtractedAmount: Sendable, Equatable {
    public var value: Int           // Valoare în moneda originală (întreg, RON arrotondat)
    public var currency: AmountCurrency
    public var rawString: String    // Textul original, pentru debug

    /// Conversia în `Money` (RON) — nil pentru EUR (lipsă curs valutar în acest modul).
    public var moneyRON: Money? {
        guard currency == .ron else { return nil }
        return Money(value)
    }
}

public enum AmountCurrency: String, Sendable, Equatable {
    case ron = "RON"
    case eur = "EUR"
}

// MARK: - Parsed result

/// Rezultatul parsării unui email — poate genera un `Transaction` dacă
/// confidența e suficient de mare.
public struct ParsedEmailTransaction: Sendable {
    public var from: String
    public var subject: String
    public var date: Date

    /// Suma extrasă (cea mai mare/relevantă din email).
    public var amount: ExtractedAmount?

    /// Merchant-ul identificat (din sender registry).
    public var merchant: String?

    /// Categoria de tranzacție sugerată.
    public var suggestedCategory: TransactionCategory

    /// Direcția dedusă (outgoing = cheltuială, incoming = încasare).
    public var direction: FlowDirection

    /// Confidence 0...1 a parsării.
    public var confidence: Double

    /// Sursa confidenței.
    public var confidenceSource: ConfidenceSource

    // MARK: - Derived

    /// True dacă confidența e suficient de mare pentru import automat (fără confirmare user).
    public var isAutoImportReady: Bool { confidence >= 0.80 }

    /// True dacă necesită confirmare manuală din partea utilizatorului.
    public var requiresManualReview: Bool { confidence < 0.50 || amount == nil }

    /// Convertit la `Transaction` value type (pentru stocare).
    public func toTransaction() -> Transaction? {
        guard let amt = amount, let ron = amt.moneyRON else { return nil }
        return Transaction(
            date: date,
            amount: ron,
            direction: direction,
            category: suggestedCategory,
            merchant: merchant,
            source: .emailParsed,
            categorizationConfidence: confidence
        )
    }
}

// MARK: - Confidence source

public enum ConfidenceSource: String, Sendable, Codable {
    /// Sender a fost găsit exact pe whitelist.
    case senderExactMatch = "sender_exact"
    /// Sender a fost găsit prin domeniu (subdomain match).
    case senderDomainMatch = "sender_domain"
    /// Sender necunoscut; clasificare prin keywords din subject/body.
    case keywordMatch = "keyword_only"
    /// Nicio potrivire.
    case noMatch = "no_match"
}
