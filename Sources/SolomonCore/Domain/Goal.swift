import Foundation

/// Tipul de obiectiv (spec §6.2 secțiunea goal).
public enum GoalKind: String, Codable, Sendable, Hashable, CaseIterable {
    case vacation
    case car
    case house
    case emergencyFund = "emergency_fund"
    case debtPayoff    = "debt_payoff"
    case custom

    public var displayNameRO: String {
        switch self {
        case .vacation:      return "Vacanță"
        case .car:           return "Mașină"
        case .house:         return "Casă"
        case .emergencyFund: return "Fond de urgență"
        case .debtPayoff:    return "Achitare datorii"
        case .custom:        return "Obiectiv propriu"
        }
    }
}

/// Cât de fezabil e obiectivul la ritmul curent.
public enum GoalFeasibility: String, Codable, Sendable, Hashable, CaseIterable {
    /// La ritmul curent ești înainte de timp.
    case easy
    /// La ritmul curent ajungi exact la timp.
    case onTrack          = "on_track"
    /// La ritmul curent ajungi cu efort suplimentar.
    case challengingButPossible = "challenging_but_possible"
    /// Imposibil la ritmul curent — necesită schimbare structurală.
    case unrealistic

    public var displayNameRO: String {
        switch self {
        case .easy:                    return "ușor de atins"
        case .onTrack:                 return "pe drumul cel bun"
        case .challengingButPossible:  return "provocator dar posibil"
        case .unrealistic:             return "nerealist la ritmul curent"
        }
    }
}

/// Un obiectiv financiar al utilizatorului (vacanță, mașină, fond, etc.).
///
/// Câmpurile derivate (`monthsRemaining`, `monthlyRequired`, `feasibility`,
/// `currentPaceWillReach`, `shortfallPerMonth`) se calculează în
/// `SolomonAnalytics.GoalProgress`. Aici ținem doar starea declarată +
/// progresul cumulat; restul se reevaluează lunar.
public struct Goal: Codable, Sendable, Hashable, Identifiable {
    public let id: UUID
    public var kind: GoalKind
    /// Ex: „Grecia", „Tesla Model 3", „Apartament 2 camere Cluj".
    public var destination: String?
    public var amountTarget: Money
    public var amountSaved: Money
    public var deadline: Date

    public init(
        id: UUID = UUID(),
        kind: GoalKind,
        destination: String? = nil,
        amountTarget: Money,
        amountSaved: Money = 0,
        deadline: Date
    ) {
        precondition(amountTarget.isPositive, "Target trebuie să fie > 0")
        self.id = id
        self.kind = kind
        self.destination = destination
        self.amountTarget = amountTarget
        self.amountSaved = amountSaved
        self.deadline = deadline
    }

    public var progressFraction: Double {
        guard amountTarget.amount > 0 else { return 0 }
        return Double(amountSaved.amount) / Double(amountTarget.amount)
    }

    public var amountRemaining: Money {
        let remaining = amountTarget - amountSaved
        return remaining.isNegative ? Money(0) : remaining
    }

    public var isReached: Bool { amountSaved >= amountTarget }
}
