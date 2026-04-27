import Foundation

/// Cât de greu e de anulat un abonament (spec §6.7).
public enum CancellationDifficulty: String, Codable, Sendable, Hashable, CaseIterable {
    /// 1-2 click-uri pe site / setări iOS.
    case easy
    /// Mai multe pași sau App Store flow.
    case medium
    /// Penalități, suport telefonic, contract activ.
    case hard

    public var displayNameRO: String {
        switch self {
        case .easy:   return "ușor"
        case .medium: return "moderat"
        case .hard:   return "dificil"
        }
    }
}

/// Confidență că un abonament e „ghost" (nefolosit). Spec §6.7 / §6.2 secțiunea ghost_subscriptions.
public enum GhostConfidence: String, Codable, Sendable, Hashable {
    case low
    case medium
    case high
    case veryHigh = "very_high"
}

/// Un abonament activ — fie folosit, fie ghost (nefolosit).
public struct Subscription: Codable, Sendable, Hashable, Identifiable {
    public let id: UUID
    public var name: String
    public var amountMonthly: Money
    /// Câte zile au trecut de la ultima utilizare detectată. `nil` = nu avem semnal.
    public var lastUsedDaysAgo: Int?
    public var cancellationDifficulty: CancellationDifficulty
    public var cancellationURL: URL?
    public var cancellationStepsSummary: String?
    public var alternativeSuggestion: String?
    /// Atenționare specifică (ex: „are penalty pentru anulare anticipată").
    public var cancellationWarning: String?

    public init(
        id: UUID = UUID(),
        name: String,
        amountMonthly: Money,
        lastUsedDaysAgo: Int? = nil,
        cancellationDifficulty: CancellationDifficulty = .medium,
        cancellationURL: URL? = nil,
        cancellationStepsSummary: String? = nil,
        alternativeSuggestion: String? = nil,
        cancellationWarning: String? = nil
    ) {
        self.id = id
        self.name = name
        self.amountMonthly = amountMonthly
        self.lastUsedDaysAgo = lastUsedDaysAgo
        self.cancellationDifficulty = cancellationDifficulty
        self.cancellationURL = cancellationURL
        self.cancellationStepsSummary = cancellationStepsSummary
        self.alternativeSuggestion = alternativeSuggestion
        self.cancellationWarning = cancellationWarning
    }

    public var amountAnnual: Money { amountMonthly * 12 }

    /// Pragul de „ghost" e definit în spec §4.2: > 30 zile fără utilizare.
    public var isGhost: Bool {
        guard let days = lastUsedDaysAgo else { return false }
        return days > 30
    }

    /// Confidență că e ghost — combinație între cât de demult și calitatea semnalului.
    public var ghostConfidence: GhostConfidence {
        guard let days = lastUsedDaysAgo else { return .low }
        switch days {
        case ..<31:    return .low
        case 31..<60:  return .medium
        case 60..<120: return .high
        default:       return .veryHigh
        }
    }
}
