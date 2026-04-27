import Foundation
import SolomonCore

// MARK: - Query

/// Tipul de query determină TTL cache-ul și unde căutăm (spec §3.1, §9.5).
public enum WebQueryType: String, Sendable, Codable, CaseIterable {
    case currencyRate    = "currency_rate"   // 6h — curs BNR
    case interestRate    = "interest_rate"   // 24h — dobânzi bancare
    case scamAlert       = "scam_alert"      // 1h — alerte scam
    case generalFinance  = "general_finance" // 24h — concepte financiare
    case priceComparison = "price_comparison"// 6h — comparații preț

    public var cacheTTL: TimeInterval {
        switch self {
        case .currencyRate:    return 6 * 3_600
        case .scamAlert:       return 3_600
        case .priceComparison: return 6 * 3_600
        case .interestRate,
             .generalFinance:  return 24 * 3_600
        }
    }
}

public struct WebSearchQuery: Sendable {
    public var text: String
    public var queryType: WebQueryType
    /// Localizare DDG (ro-ro = rezultate în română).
    public var locale: String

    public init(text: String, queryType: WebQueryType, locale: String = "ro-ro") {
        self.text = text
        self.queryType = queryType
        self.locale = locale
    }

    /// Cheie de cache unică per query (tip + text normalizat).
    public var cacheKey: String {
        "\(queryType.rawValue):\(text.lowercased().trimmingCharacters(in: .whitespaces))"
    }

    /// URL DuckDuckGo Instant Answer API (gratuit, fără API key).
    public var ddgURL: URL? {
        var components = URLComponents(string: "https://api.duckduckgo.com/")!
        components.queryItems = [
            .init(name: "q",              value: text),
            .init(name: "format",         value: "json"),
            .init(name: "no_html",        value: "1"),
            .init(name: "skip_disambig",  value: "1"),
            .init(name: "kl",             value: locale)
        ]
        return components.url
    }
}

// MARK: - Result

public struct WebSearchResult: Sendable {
    public var query: String
    public var queryType: WebQueryType
    /// Răspuns direct (ex: „1 EUR = 4.98 RON").
    public var answer: String?
    /// Text rezumat (Wikipedia / Instant Answer).
    public var abstractText: String?
    /// Sursa abstractului.
    public var sourceURL: URL?
    /// Subiecte conexe.
    public var relatedTopics: [String]
    public var fetchedAt: Date
    public var isFromCache: Bool

    public init(
        query: String,
        queryType: WebQueryType,
        answer: String? = nil,
        abstractText: String? = nil,
        sourceURL: URL? = nil,
        relatedTopics: [String] = [],
        fetchedAt: Date = Date(),
        isFromCache: Bool = false
    ) {
        self.query = query
        self.queryType = queryType
        self.answer = answer
        self.abstractText = abstractText
        self.sourceURL = sourceURL
        self.relatedTopics = relatedTopics
        self.fetchedAt = fetchedAt
        self.isFromCache = isFromCache
    }

    /// True dacă avem cel puțin un răspuns util.
    public var hasContent: Bool {
        answer != nil || (abstractText != nil && !(abstractText!.isEmpty))
    }

    func cached() -> WebSearchResult {
        var copy = self
        copy.isFromCache = true
        return copy
    }
}

// MARK: - DDG JSON payload

/// Structura de răspuns DuckDuckGo Instant Answer API.
struct DDGResponse: Decodable {
    let answer: String?
    let abstractText: String
    let abstractURL: String
    let relatedTopics: [DDGRelatedTopic]

    enum CodingKeys: String, CodingKey {
        case answer       = "Answer"
        case abstractText = "AbstractText"
        case abstractURL  = "AbstractURL"
        case relatedTopics = "RelatedTopics"
    }
}

struct DDGRelatedTopic: Decodable {
    let text: String?
    let firstURL: String?

    enum CodingKeys: String, CodingKey {
        case text     = "Text"
        case firstURL = "FirstURL"
    }
}
