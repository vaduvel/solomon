import Foundation
import SolomonCore

/// Filtrează URL-uri și queries pe baza whitelist-ului de domenii Solomon (spec §9).
///
/// Solomon caută NUMAI pe domenii aprobate (BNR, ANAF, conso.ro etc.) —
/// nu face scraping aleator pe internet.
public struct WebWhitelistFilter: Sendable {

    public init() {}

    // MARK: - URL filtering

    /// True dacă URL-ul e pe un domeniu din whitelist.
    public func isAllowed(url: URL) -> Bool {
        domain(for: url) != nil
    }

    /// Returnează înregistrarea domeniului dacă URL-ul e pe whitelist.
    public func domain(for url: URL) -> WhitelistedDomain? {
        guard let host = url.host?.lowercased() else { return nil }
        return WebSearchWhitelist.all.first { whitelisted in
            host == whitelisted.host || host.hasSuffix("." + whitelisted.host)
        }
    }

    // MARK: - Trust level

    /// Returnează nivelul de trust pentru un URL (nil dacă nu e în whitelist).
    public func trustLevel(for url: URL) -> WebTrustLevel? {
        domain(for: url)?.trustLevel
    }

    // MARK: - Topic-based domain lookup

    /// Returnează domeniile relevante pentru un subiect dat (tag match).
    public func domains(matchingTag tag: String) -> [WhitelistedDomain] {
        let lowTag = tag.lowercased()
        return WebSearchWhitelist.all.filter { $0.topicTags.contains { $0.lowercased() == lowTag } }
    }

    /// Returnează domeniile oficiale (trustLevel == .high).
    public var officialDomains: [WhitelistedDomain] {
        WebSearchWhitelist.all.filter { $0.trustLevel == .high }
    }

    /// TTL cache recomandat pentru un URL (din politica domeniului).
    public func cacheTTL(for url: URL) -> TimeInterval? {
        domain(for: url).map { TimeInterval($0.defaultCachePolicy.seconds) }
    }
}
