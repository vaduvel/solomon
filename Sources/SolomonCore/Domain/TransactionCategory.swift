import Foundation

/// Categoriile standard de cheltuieli/venituri Solomon (spec §6.1).
public enum TransactionCategory: String, CaseIterable, Codable, Sendable, Hashable {
    case foodGrocery        = "food_grocery"
    case foodDelivery       = "food_delivery"
    case foodDining         = "food_dining"
    case transport          = "transport"
    case utilities          = "utilities"
    case rentMortgage       = "rent_mortgage"
    case subscriptions      = "subscriptions"
    case shoppingOnline     = "shopping_online"
    case shoppingOffline    = "shopping_offline"
    case entertainment      = "entertainment"
    case health             = "health"
    case loansIFN           = "loans_ifn"
    case loansBank          = "loans_bank"
    case bnpl               = "bnpl"
    case travel             = "travel"
    case savings            = "savings"
    case unknown            = "unknown"

    /// Etichetă în română pentru afișare.
    public var displayNameRO: String {
        switch self {
        case .foodGrocery:     return "Cumpărături alimentare"
        case .foodDelivery:    return "Livrări mâncare"
        case .foodDining:      return "Restaurante"
        case .transport:       return "Transport"
        case .utilities:       return "Utilități"
        case .rentMortgage:    return "Chirie / rată"
        case .subscriptions:   return "Abonamente"
        case .shoppingOnline:  return "Cumpărături online"
        case .shoppingOffline: return "Cumpărături magazine"
        case .entertainment:   return "Distracție"
        case .health:          return "Sănătate"
        case .loansIFN:        return "Credite IFN"
        case .loansBank:       return "Credite bancare"
        case .bnpl:            return "BNPL"
        case .travel:          return "Călătorii"
        case .savings:         return "Economii"
        case .unknown:         return "Necategorizat"
        }
    }

    /// Grupare semantică pentru priorități și apărare (spec §10).
    public enum Group: String, Sendable {
        case essentials       // chirie, utilități, mâncare-bază, transport
        case lifestyle        // delivery, dining, entertainment, shopping
        case debt             // IFN, BNPL, credite
        case savings          // economii, vacanță
        case other
    }

    public var group: Group {
        switch self {
        case .rentMortgage, .utilities, .foodGrocery, .transport, .health:
            return .essentials
        case .foodDelivery, .foodDining, .subscriptions, .shoppingOnline,
             .shoppingOffline, .entertainment, .travel:
            return .lifestyle
        case .loansIFN, .loansBank, .bnpl:
            return .debt
        case .savings:
            return .savings
        case .unknown:
            return .other
        }
    }

    /// Categoriile considerate „risc" pentru spiral detection.
    public static let debtCategories: Set<TransactionCategory> = [.loansIFN, .loansBank, .bnpl]
}
