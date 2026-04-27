import Foundation

/// Direcția fluxului de bani.
public enum FlowDirection: String, Codable, Sendable, Hashable {
    /// Bani care intră (salariu, refund, transfer primit).
    case incoming
    /// Bani care ies (cheltuială, transfer trimis).
    case outgoing
}

/// Sursa din care a fost obținută o tranzacție.
public enum TransactionSource: String, Codable, Sendable, Hashable {
    case emailParsed   = "email_parsed"
    case csvImport     = "csv_import"
    case manualEntry   = "manual_entry"
    case derivedFromObligation = "derived_from_obligation"
}

/// O tranzacție financiară individuală — cărămida pe care toată analiza Solomon o folosește.
///
/// Este intenționat un value type imuabil: tranzacțiile nu se editează după creare,
/// se înlocuiesc complet (id-ul rămâne, restul se schimbă).
public struct Transaction: Codable, Sendable, Hashable, Identifiable {
    public let id: UUID
    public let date: Date
    public let amount: Money
    public let direction: FlowDirection
    public let category: TransactionCategory
    public let merchant: String?
    public let description: String?
    public let source: TransactionSource
    /// Confidență 0...1 a categorizării — relevant când vine din parser.
    public let categorizationConfidence: Double

    public init(
        id: UUID = UUID(),
        date: Date,
        amount: Money,
        direction: FlowDirection,
        category: TransactionCategory,
        merchant: String? = nil,
        description: String? = nil,
        source: TransactionSource,
        categorizationConfidence: Double = 1.0
    ) {
        self.id = id
        self.date = date
        self.amount = amount
        self.direction = direction
        self.category = category
        self.merchant = merchant
        self.description = description
        self.source = source
        self.categorizationConfidence = max(0, min(1, categorizationConfidence))
    }

    /// Suma cu semn: negativă pentru `outgoing`, pozitivă pentru `incoming`.
    public var signedAmount: Money {
        switch direction {
        case .incoming: return amount
        case .outgoing: return -amount
        }
    }

    public var isIncoming: Bool { direction == .incoming }
    public var isOutgoing: Bool { direction == .outgoing }
}
