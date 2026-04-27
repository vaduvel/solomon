import Foundation
import SolomonCore

// MARK: - Errors

public enum SolomonWebError: Error, Sendable {
    /// URL-ul nu se află pe niciun domeniu din whitelist.
    case domainNotWhitelisted(URL)
    /// Query gol sau compus din spații.
    case emptyQuery
    /// Eroare rețea transmisă direct din DDG client.
    case networkError(Error)
    /// Eroare de decodare transmisă direct din DDG client.
    case decodingError(Error)
    /// Răspuns HTTP non-2xx.
    case httpError(statusCode: Int)
}

// MARK: - Web client protocol (pentru testabilitate)

public protocol WebSearchClientProtocol: Sendable {
    func search(_ query: WebSearchQuery) async throws -> WebSearchResult
    func scamCheck(text: String) -> ScamMatchResult?
    func isAllowed(url: URL) -> Bool
}

// MARK: - Actor orchestrator

/// Orchestrează DDG Instant Answer + cache în memorie + whitelist + scam checker (spec §3.1, §9, §10.4).
///
/// Fluxul unui `search(_:)`:
/// 1. Validare query
/// 2. Verificare cache → hit: returnează cached
/// 3. `DDGInstantAnswerClient.fetch` → rețea
/// 4. Stochează în cache cu TTL din `WebQueryType`
/// 5. Returnează rezultatul
public actor SolomonWebClient: WebSearchClientProtocol {

    // MARK: - Dependencies

    private let ddg: DDGInstantAnswerClient
    private let cache: WebSearchCache
    private let whitelist: WebWhitelistFilter
    private let scamMatcher: ScamPatternMatcher

    // MARK: - Stats (diagnostics)

    private(set) public var cacheHits: Int = 0
    private(set) public var cacheMisses: Int = 0
    private(set) public var totalSearches: Int = 0

    // MARK: - Init

    public init(
        http: HTTPClient = URLSession.shared,
        cache: WebSearchCache = WebSearchCache(),
        whitelist: WebWhitelistFilter = WebWhitelistFilter(),
        scamMatcher: ScamPatternMatcher = ScamPatternMatcher()
    ) {
        self.ddg = DDGInstantAnswerClient(http: http)
        self.cache = cache
        self.whitelist = whitelist
        self.scamMatcher = scamMatcher
    }

    // MARK: - Main search API

    /// Caută pe DDG cu cache automat. Aruncă `SolomonWebError` în caz de eroare.
    public func search(_ query: WebSearchQuery) async throws -> WebSearchResult {
        let trimmed = query.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw SolomonWebError.emptyQuery }

        totalSearches += 1
        let key = query.cacheKey

        // 1. Cache hit
        if let cached = await cache.get(key: key) {
            cacheHits += 1
            return cached
        }
        cacheMisses += 1

        // 2. Fetch DDG
        let result: WebSearchResult
        do {
            result = try await ddg.fetch(query)
        } catch let e as DDGClientError {
            switch e {
            case .networkError(let underlying): throw SolomonWebError.networkError(underlying)
            case .decodingError(let underlying): throw SolomonWebError.decodingError(underlying)
            case .httpError(let code): throw SolomonWebError.httpError(statusCode: code)
            case .invalidURL: throw SolomonWebError.emptyQuery
            }
        }

        // 3. Cache cu TTL per query type
        await cache.set(key: key, result: result, ttl: query.queryType.cacheTTL)
        return result
    }

    // MARK: - Scam check (nonisolated — nu modifică stare)

    /// Detectează scam pattern-uri în text. Wrapper direct peste `ScamPatternMatcher`.
    public nonisolated func scamCheck(text: String) -> ScamMatchResult? {
        scamMatcher.match(in: text)
    }

    // MARK: - Whitelist (nonisolated)

    /// True dacă URL-ul este pe un domeniu din whitelist.
    public nonisolated func isAllowed(url: URL) -> Bool {
        whitelist.isAllowed(url: url)
    }

    // MARK: - Cache management

    /// Invalidează un query specific din cache (forțează re-fetch).
    public func invalidate(query: WebSearchQuery) async {
        await cache.invalidate(key: query.cacheKey)
    }

    /// Curăță tot cache-ul.
    public func purgeCache() async {
        await cache.purgeAll()
    }

    /// Curăță intrările expirate.
    public func purgeExpiredCache() async {
        await cache.purgeExpired()
    }

    // MARK: - Diagnostics

    public var cacheCount: Int {
        get async { await cache.count }
    }

    public var validCacheCount: Int {
        get async { await cache.validCount }
    }

    public var hitRate: Double {
        guard totalSearches > 0 else { return 0 }
        return Double(cacheHits) / Double(totalSearches)
    }
}
