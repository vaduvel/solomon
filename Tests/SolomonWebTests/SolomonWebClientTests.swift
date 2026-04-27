import Testing
import Foundation
@testable import SolomonWeb

// MARK: - Mock HTTP client (identical structure to DDGClientTests mock)

private final class MockHTTPClient: HTTPClient, @unchecked Sendable {
    var responseData: Data = Data()
    var statusCode: Int = 200
    var shouldThrow: Error? = nil
    private(set) var fetchCallCount = 0

    func data(from url: URL) async throws -> (Data, URLResponse) {
        fetchCallCount += 1
        if let err = shouldThrow { throw err }
        let response = HTTPURLResponse(url: url, statusCode: statusCode,
                                       httpVersion: nil, headerFields: nil)!
        return (responseData, response)
    }
}

private func ddgJSON(answer: String = "test_answer", abstractText: String = "",
                     abstractURL: String = "") -> Data {
    let json = """
    {
      "Answer": "\(answer)",
      "AbstractText": "\(abstractText)",
      "AbstractURL": "\(abstractURL)",
      "RelatedTopics": []
    }
    """
    return json.data(using: .utf8)!
}

// MARK: - Tests

@Suite struct SolomonWebClientTests {

    // MARK: - Basic search

    @Test func searchReturnsResultOnSuccess() async throws {
        let mock = MockHTTPClient()
        mock.responseData = ddgJSON(answer: "1 EUR = 4.97 RON")
        let client = SolomonWebClient(http: mock)
        let query = WebSearchQuery(text: "curs eur ron", queryType: .currencyRate)
        let result = try await client.search(query)
        #expect(result.answer == "1 EUR = 4.97 RON")
    }

    @Test func searchThrowsForEmptyQuery() async throws {
        let mock = MockHTTPClient()
        mock.responseData = ddgJSON()
        let client = SolomonWebClient(http: mock)
        let query = WebSearchQuery(text: "   ", queryType: .generalFinance)
        do {
            _ = try await client.search(query)
            Issue.record("Should have thrown emptyQuery")
        } catch SolomonWebError.emptyQuery {
            // OK
        }
    }

    // MARK: - Cache behavior

    @Test func secondSearchHitsCache() async throws {
        let mock = MockHTTPClient()
        mock.responseData = ddgJSON(answer: "cached_answer")
        let client = SolomonWebClient(http: mock)
        let query = WebSearchQuery(text: "curs eur", queryType: .currencyRate)
        _ = try await client.search(query)
        let result2 = try await client.search(query)
        // Al doilea apel trebuie să fie din cache
        #expect(result2.isFromCache == true)
        // HTTP client apelat o singură dată
        #expect(mock.fetchCallCount == 1)
    }

    @Test func cacheHitRateIncreasesAfterSecondCall() async throws {
        let mock = MockHTTPClient()
        mock.responseData = ddgJSON()
        let client = SolomonWebClient(http: mock)
        let query = WebSearchQuery(text: "curs eur", queryType: .currencyRate)
        _ = try await client.search(query)
        _ = try await client.search(query)
        let hits = await client.cacheHits
        let misses = await client.cacheMisses
        let total = await client.totalSearches
        #expect(hits == 1)
        #expect(misses == 1)
        #expect(total == 2)
    }

    @Test func invalidateForcesRefetch() async throws {
        let mock = MockHTTPClient()
        mock.responseData = ddgJSON()
        let client = SolomonWebClient(http: mock)
        let query = WebSearchQuery(text: "test", queryType: .generalFinance)
        _ = try await client.search(query)       // fetch #1
        await client.invalidate(query: query)
        _ = try await client.search(query)       // fetch #2 — cache invalidat
        #expect(mock.fetchCallCount == 2)
    }

    @Test func purgeCacheClearsAll() async throws {
        let mock = MockHTTPClient()
        mock.responseData = ddgJSON()
        let client = SolomonWebClient(http: mock)
        let q1 = WebSearchQuery(text: "test1", queryType: .currencyRate)
        let q2 = WebSearchQuery(text: "test2", queryType: .interestRate)
        _ = try await client.search(q1)
        _ = try await client.search(q2)
        await client.purgeCache()
        let count = await client.cacheCount
        #expect(count == 0)
    }

    // MARK: - Network error propagation

    @Test func searchPropagatesNetworkError() async throws {
        let mock = MockHTTPClient()
        mock.shouldThrow = URLError(.notConnectedToInternet)
        let client = SolomonWebClient(http: mock)
        do {
            _ = try await client.search(WebSearchQuery(text: "test", queryType: .generalFinance))
            Issue.record("Should have thrown")
        } catch SolomonWebError.networkError {
            // OK
        }
    }

    @Test func searchPropagatesHTTPError() async throws {
        let mock = MockHTTPClient()
        mock.responseData = Data()
        mock.statusCode = 429
        let client = SolomonWebClient(http: mock)
        do {
            _ = try await client.search(WebSearchQuery(text: "test", queryType: .generalFinance))
            Issue.record("Should have thrown")
        } catch SolomonWebError.httpError(let code) {
            #expect(code == 429)
        }
    }

    // MARK: - Scam check (nonisolated)

    @Test func scamCheckDetectsDefiniteScam() async {
        let client = SolomonWebClient()
        let result = client.scamCheck(text: "Garantat 2% pe luna fara risc investitie sigura.")
        #expect(result != nil)
        #expect(result?.pattern.severity == .definiteScam)
    }

    @Test func scamCheckReturnsNilForCleanText() async {
        let client = SolomonWebClient()
        let result = client.scamCheck(text: "Extras de cont: 1200 RON cheltuieli luna aceasta.")
        #expect(result == nil)
    }

    // MARK: - Whitelist (nonisolated)

    @Test func isAllowedTrueForBNR() async {
        let client = SolomonWebClient()
        let url = URL(string: "https://bnr.ro/")!
        #expect(client.isAllowed(url: url) == true)
    }

    @Test func isAllowedFalseForGoogle() async {
        let client = SolomonWebClient()
        let url = URL(string: "https://google.com/search?q=test")!
        #expect(client.isAllowed(url: url) == false)
    }

    // MARK: - hitRate

    @Test func hitRateZeroWithNoSearches() async {
        let client = SolomonWebClient()
        let rate = await client.hitRate
        #expect(rate == 0.0)
    }

    @Test func hitRateCalculatedCorrectly() async throws {
        let mock = MockHTTPClient()
        mock.responseData = ddgJSON()
        let client = SolomonWebClient(http: mock)
        let query = WebSearchQuery(text: "robor", queryType: .interestRate)
        _ = try await client.search(query)   // miss
        _ = try await client.search(query)   // hit
        _ = try await client.search(query)   // hit
        let rate = await client.hitRate
        // 2 hits / 3 total = 0.666...
        #expect(abs(rate - (2.0/3.0)) < 0.001)
    }

    // MARK: - validCacheCount

    @Test func validCacheCountReflectsActiveEntries() async throws {
        let mock = MockHTTPClient()
        mock.responseData = ddgJSON()
        let client = SolomonWebClient(http: mock)
        let q1 = WebSearchQuery(text: "a", queryType: .generalFinance)
        let q2 = WebSearchQuery(text: "b", queryType: .generalFinance)
        _ = try await client.search(q1)
        _ = try await client.search(q2)
        let valid = await client.validCacheCount
        #expect(valid == 2)
    }

    // MARK: - totalSearches counter

    @Test func totalSearchesIncrementsPerCall() async throws {
        let mock = MockHTTPClient()
        mock.responseData = ddgJSON()
        let client = SolomonWebClient(http: mock)
        for i in 0..<4 {
            let q = WebSearchQuery(text: "query\(i)", queryType: .generalFinance)
            _ = try await client.search(q)
        }
        let total = await client.totalSearches
        #expect(total == 4)
    }

    // MARK: - purgeExpiredCache

    @Test func purgeExpiredCacheDoesNotRemoveValidEntries() async throws {
        let mock = MockHTTPClient()
        mock.responseData = ddgJSON()
        let client = SolomonWebClient(http: mock)
        let q = WebSearchQuery(text: "test", queryType: .generalFinance)
        _ = try await client.search(q)
        await client.purgeExpiredCache()
        let count = await client.cacheCount
        #expect(count == 1)
    }
}
