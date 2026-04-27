import Foundation

// MARK: - HTTP abstraction (pentru testabilitate)

/// Protocol minim pentru request HTTP — permite mock-uri în teste.
public protocol HTTPClient: Sendable {
    func data(from url: URL) async throws -> (Data, URLResponse)
}

extension URLSession: HTTPClient {
    public func data(from url: URL) async throws -> (Data, URLResponse) {
        try await data(from: url, delegate: nil)
    }
}

// MARK: - Errors

public enum DDGClientError: Error, Sendable {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case httpError(statusCode: Int)
}

// MARK: - Client

/// Client pentru DuckDuckGo Instant Answer API.
///
/// API gratuit, fără API key, cu suport pentru RO.
/// URL: `https://api.duckduckgo.com/?q=<query>&format=json&no_html=1&skip_disambig=1&kl=ro-ro`
///
/// Spec §3.1: maxim ~5.000 queries/lună la 10k useri — cost neglijabil.
public struct DDGInstantAnswerClient: Sendable {

    private let http: HTTPClient

    public init(http: HTTPClient = URLSession.shared) {
        self.http = http
    }

    // MARK: - Fetch

    public func fetch(_ query: WebSearchQuery) async throws -> WebSearchResult {
        guard let url = query.ddgURL else { throw DDGClientError.invalidURL }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await http.data(from: url)
        } catch {
            throw DDGClientError.networkError(error)
        }

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw DDGClientError.httpError(statusCode: http.statusCode)
        }

        let ddg: DDGResponse
        do {
            ddg = try JSONDecoder().decode(DDGResponse.self, from: data)
        } catch {
            throw DDGClientError.decodingError(error)
        }

        return buildResult(from: ddg, query: query)
    }

    // MARK: - Parsing

    private func buildResult(from ddg: DDGResponse, query: WebSearchQuery) -> WebSearchResult {
        let answerText = nilIfEmpty(ddg.answer)
        let abstractText = nilIfEmpty(ddg.abstractText)
        let sourceURL = URL(string: ddg.abstractURL)
        let topics = ddg.relatedTopics.compactMap { $0.text }.filter { !$0.isEmpty }

        return WebSearchResult(
            query: query.text,
            queryType: query.queryType,
            answer: answerText,
            abstractText: abstractText,
            sourceURL: sourceURL,
            relatedTopics: Array(topics.prefix(5)),
            fetchedAt: Date()
        )
    }

    private func nilIfEmpty(_ s: String?) -> String? {
        guard let s, !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return s
    }
}
