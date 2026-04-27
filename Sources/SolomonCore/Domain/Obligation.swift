import Foundation

/// Tipul de obligație recurentă (spec §4.1, §6.2).
public enum ObligationKind: String, Codable, Sendable, Hashable, CaseIterable {
    case rentMortgage = "rent_mortgage"
    case utility
    case subscription
    case loanBank      = "loan_bank"
    case loanIFN       = "loan_ifn"
    case bnpl
    case insurance
    case other

    public var displayNameRO: String {
        switch self {
        case .rentMortgage: return "Chirie / rată"
        case .utility:      return "Utilitate"
        case .subscription: return "Abonament"
        case .loanBank:     return "Credit bancar"
        case .loanIFN:      return "Credit IFN"
        case .bnpl:         return "BNPL"
        case .insurance:    return "Asigurare"
        case .other:        return "Alte plăți"
        }
    }
}

/// Cât de sigur este Solomon că obligația e reală și suma e corectă.
public enum ObligationConfidence: String, Codable, Sendable, Hashable, CaseIterable {
    /// Declarată explicit de user la onboarding sau editată manual.
    case declared
    /// Detectată automat din email (sender match + sumă recurentă).
    case detected
    /// Estimată pe baza istoricului (ex: factura Enel variază lunar).
    case estimated
}

/// O obligație recurentă (chirie, factură, abonament, rată).
public struct Obligation: Codable, Sendable, Hashable, Identifiable {
    public let id: UUID
    public var name: String
    public var amount: Money
    /// Ziua lunii la care vine plata (1–31). Pentru obligații care variază
    /// (ex: data exactă a facturii), folosim media lunară observată.
    public var dayOfMonth: Int
    public var kind: ObligationKind
    public var confidence: ObligationConfidence
    /// Data primei observații / declarării.
    public var since: Date?
    /// Data viitoarei plăți așteptate (calculată).
    public var nextDueDate: Date?

    public init(
        id: UUID = UUID(),
        name: String,
        amount: Money,
        dayOfMonth: Int,
        kind: ObligationKind,
        confidence: ObligationConfidence,
        since: Date? = nil,
        nextDueDate: Date? = nil
    ) {
        precondition((1...31).contains(dayOfMonth), "dayOfMonth trebuie 1–31, primit \(dayOfMonth)")
        self.id = id
        self.name = name
        self.amount = amount
        self.dayOfMonth = dayOfMonth
        self.kind = kind
        self.confidence = confidence
        self.since = since
        self.nextDueDate = nextDueDate
    }

    /// True dacă obligația e categoria de „datorie" pentru Spiral Detector.
    public var isDebt: Bool {
        switch kind {
        case .loanBank, .loanIFN, .bnpl: return true
        default: return false
        }
    }

    /// True dacă obligația e considerată „esențială" (chirie, utilități, asigurări).
    public var isEssential: Bool {
        switch kind {
        case .rentMortgage, .utility, .insurance: return true
        default: return false
        }
    }
}
