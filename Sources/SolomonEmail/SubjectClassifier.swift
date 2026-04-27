import Foundation
import SolomonCore

/// Clasifică subiectul unui email ca relevant financiar și deduce direcția.
///
/// Spec §8.11: Subject keywords (în RO și EN):
/// "factura", "plată", "comandă", "tranzacție", "abonament", "extras", "rambursare"
public struct SubjectClassifier: Sendable {

    public init() {}

    // MARK: - Financial relevance

    /// True dacă subiectul conține cel puțin un cuvânt-cheie financiar.
    public func isFinanciallyRelevant(_ subject: String) -> Bool {
        let s = subject.lowercased().folded()
        return Self.relevanceKeywords.contains { s.contains($0) }
    }

    // MARK: - Direction inference

    /// Deduce direcția predominantă (outgoing/incoming) pe baza subiectului.
    /// Returnează `nil` dacă nu se poate determina cu certitudine.
    public func inferDirection(_ subject: String) -> FlowDirection? {
        let s = subject.lowercased().folded()
        let incomingScore = Self.incomingKeywords.filter { s.contains($0) }.count
        let outgoingScore = Self.outgoingKeywords.filter { s.contains($0) }.count
        if incomingScore > outgoingScore { return .incoming }
        if outgoingScore > incomingScore { return .outgoing }
        return nil
    }

    // MARK: - Category hints

    /// Returnează o categorie sugerată pe baza subiectului, dacă se poate.
    public func suggestCategory(_ subject: String) -> TransactionCategory? {
        let s = subject.lowercased().folded()
        for (keywords, cat) in Self.categoryHints {
            if keywords.contains(where: { s.contains($0) }) {
                return cat
            }
        }
        return nil
    }

    // MARK: - Static keyword tables

    /// Cuvinte-cheie care indică relevanță financiară (RO + EN, diacritice stripped).
    static let relevanceKeywords: [String] = [
        // RO
        "factura", "factura", "plata", "plată", "comanda", "comanda",
        "tranzactie", "tranzacție", "abonament", "extras", "rambursare",
        "transfer", "achitat", "achitare", "debit", "credit", "suma",
        "total", "rata", "imprumut", "imprumut", "valoare",
        "confirmare", "confirma", "rezervare", "bilet", "chitanta",
        "invoice", "bon",
        // EN
        "invoice", "payment", "order", "transaction", "subscription",
        "statement", "refund", "transfer", "charge", "receipt",
        "booking", "reservation", "ticket", "receipt"
    ]

    /// Cuvinte-cheie care sugerează bani INTRAȚI (incoming).
    static let incomingKeywords: [String] = [
        "primit", "intrat", "incasat", "incasat", "rambursare",
        "refund", "restituire", "credit aprobat", "credit virat",
        "salariu", "bonus", "transfer primit", "suma virata",
        "received", "credited", "deposited"
    ]

    /// Cuvinte-cheie care sugerează bani IEȘIȚI (outgoing).
    static let outgoingKeywords: [String] = [
        "factura", "factura", "plata", "platit", "comanda", "comanda",
        "achitat", "debit", "retras", "scadent", "rata", "abonament",
        "cumparatura", "cumparatura", "invoice", "payment due",
        "charged", "debited", "withdrawn", "order confirmed"
    ]

    /// Hints per categorie.
    static let categoryHints: [([String], TransactionCategory)] = [
        (["glovo", "wolt", "tazz", "foodpanda", "bolt food"], .foodDelivery),
        (["netflix", "hbo", "spotify", "apple music", "youtube premium", "disney"], .subscriptions),
        (["enel", "digi", "rcs", "orange", "vodafone", "telekom", "engie", "eon", "gaz", "curent", "apa"], .utilities),
        (["emag", "altex", "flanco", "zalando", "h&m", "ikea"], .shoppingOnline),
        (["mokka", "tbi", "paypo", "klarna", "bnpl", "rate"], .bnpl),
        (["credius", "provident", "iute", "viva credit", "ifn"], .loansIFN),
        (["booking", "airbnb", "tarom", "wizz", "ryanair", "vola", "esky"], .travel),
        (["uber", "bolt", "stb", "cfr", "blablacar"], .transport),
        (["allianz", "groupama", "nn asigurari", "omniasig", "uniqa", "asirom"], .health),
        (["eventim", "bilet"], .entertainment)
    ]
}

// MARK: - String helper

private extension String {
    /// Normalizare fără diacritice pentru matching case/accent insensitiv.
    func folded() -> String {
        applyingTransform(.stripDiacritics, reverse: false) ?? self
    }
}
