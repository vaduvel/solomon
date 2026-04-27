import Foundation
import SolomonCore

/// Mapează adresa de sender a unui email la un `EmailSender` din registru.
///
/// Strategii de match (spec §8.11):
/// 1. **Exact**: `from` == `sender` (case-insensitive) → `high` confidence
/// 2. **Domeniu**: domeniu din `from` coincide cu domeniu din sender → `medium`
/// 3. **Parent-domain**: domeniu din `from` e subdomain al domeniului din sender → `medium`
public struct SenderMapper: Sendable {

    public init() {}

    // MARK: - Public API

    /// Lookup principal — returnează cel mai bun match și nivelul de încredere.
    public func map(from: String) -> SenderMatchResult? {
        let normalized = from.lowercased().trimmingCharacters(in: .whitespaces)

        // Pass 1: match exact (case-insensitive)
        if let exact = EmailSenderRegistry.all.first(where: { $0.sender.lowercased() == normalized }) {
            return SenderMatchResult(sender: exact, confidence: .exact)
        }

        // Pass 2: domeniu exact
        let fromDomain = domainOf(normalized)
        if let domainMatch = EmailSenderRegistry.all.first(where: { domainOf($0.sender) == fromDomain }) {
            return SenderMatchResult(sender: domainMatch, confidence: .domain)
        }

        // Pass 3: parent-domain match (ex: mail.emag.ro → emag.ro)
        if let parentMatch = EmailSenderRegistry.all.first(where: { isSubdomain(of: fromDomain, parent: domainOf($0.sender)) }) {
            return SenderMatchResult(sender: parentMatch, confidence: .domain)
        }

        return nil
    }

    // MARK: - Helpers

    private func domainOf(_ address: String) -> String {
        address.split(separator: "@").last.map(String.init) ?? address
    }

    /// True dacă `subdomain` e un subdomain al `parent`.
    /// Ex: `mail.emag.ro` este subdomain al `emag.ro`.
    private func isSubdomain(of sub: String, parent: String) -> Bool {
        guard !parent.isEmpty, parent.count < sub.count else { return false }
        return sub.hasSuffix("." + parent)
    }
}

// MARK: - Result

public struct SenderMatchResult: Sendable {
    public var sender: EmailSender
    public var confidence: SenderMatchConfidence

    /// Scor numeric al confidenței pentru compositing cu alte semnale.
    public var confidenceScore: Double {
        switch confidence {
        case .exact:   return 0.90
        case .domain:  return 0.70
        case .keyword: return 0.35
        }
    }
}
