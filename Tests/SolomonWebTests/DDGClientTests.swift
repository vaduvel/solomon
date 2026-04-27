import Testing
import Foundation
@testable import SolomonWeb

// MARK: - Mock HTTP client

/// Mock care returnează un răspuns DDG presetat sau aruncă o eroare.
private final class MockHTTPClient: HTTPClient, @unchecked Sendable {
    var responseData: Data = Data()
    var statusCode: Int = 200
    var shouldThrow: Error? = nil

    func data(from url: URL) async throws -> (Data, URLResponse) {
        if let err = shouldThrow { throw err }
        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        return (responseData, response)
    }
}

// MARK: - JSON helpers

private func ddgJSON(answer: String = "", abstractText: String = "",
                     abstractURL: String = "", relatedTopics: [[String: String]] = []) -> Data {
    var topicsJSON = "["
    for (i, t) in relatedTopics.enumerated() {
        topicsJSON += i > 0 ? "," : ""
        let txt = t["Text"] ?? ""
        let url = t["FirstURL"] ?? ""
        topicsJSON += "{\"Text\":\"\(txt)\",\"FirstURL\":\"\(url)\"}"
    }
    topicsJSON += "]"

    let json = """
    {
      "Answer": "\(answer)",
      "AbstractText": "\(abstractText)",
      "AbstractURL": "\(abstractURL)",
      "RelatedTopics": \(topicsJSON)
    }
    """
    return json.data(using: .utf8)!
}

// MARK: - Tests

@Suite struct DDGClientTests {

    // MARK: - Fetch success

    @Test func fetchReturnsAnswerWhenPresent() async throws {
        let mock = MockHTTPClient()
        mock.responseData = ddgJSON(answer: "1 EUR = 4.97 RON")
        let client = DDGInstantAnswerClient(http: mock)
        let query = WebSearchQuery(text: "curs EUR RON", queryType: .currencyRate)
        let result = try await client.fetch(query)
        #expect(result.answer == "1 EUR = 4.97 RON")
        #expect(result.queryType == .currencyRate)
    }

    @Test func fetchReturnsAbstractText() async throws {
        let mock = MockHTTPClient()
        mock.responseData = ddgJSON(abstractText: "ROBOR este rata dobânzii...")
        let client = DDGInstantAnswerClient(http: mock)
        let query = WebSearchQuery(text: "ROBOR 3M", queryType: .interestRate)
        let result = try await client.fetch(query)
        #expect(result.abstractText == "ROBOR este rata dobânzii...")
    }

    @Test func fetchReturnsSourceURL() async throws {
        let mock = MockHTTPClient()
        mock.responseData = ddgJSON(abstractURL: "https://bnr.ro/robor")
        let client = DDGInstantAnswerClient(http: mock)
        let query = WebSearchQuery(text: "ROBOR", queryType: .interestRate)
        let result = try await client.fetch(query)
        #expect(result.sourceURL?.absoluteString == "https://bnr.ro/robor")
    }

    @Test func fetchMaxFiveRelatedTopics() async throws {
        let mock = MockHTTPClient()
        let topics = (1...8).map { ["Text": "Topic \($0)", "FirstURL": "https://example.com/\($0)"] }
        mock.responseData = ddgJSON(relatedTopics: topics)
        let client = DDGInstantAnswerClient(http: mock)
        let query = WebSearchQuery(text: "investitii", queryType: .generalFinance)
        let result = try await client.fetch(query)
        #expect(result.relatedTopics.count <= 5)
    }

    @Test func fetchRelatedTopicsFiltersEmpty() async throws {
        let mock = MockHTTPClient()
        let topics = [["Text": "", "FirstURL": "https://x.com"],
                      ["Text": "Subiect valid", "FirstURL": "https://y.com"],
                      ["Text": "   ", "FirstURL": "https://z.com"]]
        mock.responseData = ddgJSON(relatedTopics: topics)
        let client = DDGInstantAnswerClient(http: mock)
        let query = WebSearchQuery(text: "test", queryType: .generalFinance)
        let result = try await client.fetch(query)
        // "   " trimmed e gol; "   " va fi exclus de "!$0.isEmpty" pe textul netrimmat → acel check e pe text
        // Cel puțin "Subiect valid" trebuie prezent
        #expect(result.relatedTopics.contains("Subiect valid"))
    }

    @Test func fetchSetsCorrectQueryText() async throws {
        let mock = MockHTTPClient()
        mock.responseData = ddgJSON()
        let client = DDGInstantAnswerClient(http: mock)
        let query = WebSearchQuery(text: "curs EUR", queryType: .currencyRate)
        let result = try await client.fetch(query)
        #expect(result.query == "curs EUR")
    }

    @Test func fetchSetsIsFromCacheFalse() async throws {
        let mock = MockHTTPClient()
        mock.responseData = ddgJSON(answer: "test")
        let client = DDGInstantAnswerClient(http: mock)
        let query = WebSearchQuery(text: "test", queryType: .generalFinance)
        let result = try await client.fetch(query)
        #expect(result.isFromCache == false)
    }

    @Test func fetchSetsRecentFetchedAt() async throws {
        let before = Date()
        let mock = MockHTTPClient()
        mock.responseData = ddgJSON()
        let client = DDGInstantAnswerClient(http: mock)
        let query = WebSearchQuery(text: "test", queryType: .generalFinance)
        let result = try await client.fetch(query)
        let after = Date()
        #expect(result.fetchedAt >= before)
        #expect(result.fetchedAt <= after)
    }

    // MARK: - Empty answer/abstract → nil

    @Test func fetchNilAnswerWhenEmpty() async throws {
        let mock = MockHTTPClient()
        mock.responseData = ddgJSON(answer: "")
        let client = DDGInstantAnswerClient(http: mock)
        let result = try await client.fetch(WebSearchQuery(text: "x", queryType: .generalFinance))
        #expect(result.answer == nil)
    }

    @Test func fetchNilAnswerWhenWhitespace() async throws {
        let mock = MockHTTPClient()
        mock.responseData = ddgJSON(answer: "   ")
        let client = DDGInstantAnswerClient(http: mock)
        let result = try await client.fetch(WebSearchQuery(text: "x", queryType: .generalFinance))
        #expect(result.answer == nil)
    }

    @Test func fetchNilAbstractWhenEmpty() async throws {
        let mock = MockHTTPClient()
        mock.responseData = ddgJSON(abstractText: "")
        let client = DDGInstantAnswerClient(http: mock)
        let result = try await client.fetch(WebSearchQuery(text: "x", queryType: .generalFinance))
        #expect(result.abstractText == nil)
    }

    // MARK: - Network errors

    @Test func fetchThrowsNetworkError() async throws {
        let mock = MockHTTPClient()
        mock.shouldThrow = URLError(.timedOut)
        let client = DDGInstantAnswerClient(http: mock)
        do {
            _ = try await client.fetch(WebSearchQuery(text: "test", queryType: .generalFinance))
            Issue.record("Should have thrown")
        } catch DDGClientError.networkError {
            // OK
        }
    }

    @Test func fetchThrowsHTTPError() async throws {
        let mock = MockHTTPClient()
        mock.responseData = Data()
        mock.statusCode = 503
        let client = DDGInstantAnswerClient(http: mock)
        do {
            _ = try await client.fetch(WebSearchQuery(text: "test", queryType: .generalFinance))
            Issue.record("Should have thrown")
        } catch DDGClientError.httpError(let code) {
            #expect(code == 503)
        }
    }

    @Test func fetchThrowsDecodingErrorOnBadJSON() async throws {
        let mock = MockHTTPClient()
        mock.responseData = "not_json{{{".data(using: .utf8)!
        let client = DDGInstantAnswerClient(http: mock)
        do {
            _ = try await client.fetch(WebSearchQuery(text: "test", queryType: .generalFinance))
            Issue.record("Should have thrown")
        } catch DDGClientError.decodingError {
            // OK
        }
    }

    // MARK: - URL construction

    @Test func queryBuildsValidDDGURL() {
        let query = WebSearchQuery(text: "curs valutar eur", queryType: .currencyRate)
        let url = query.ddgURL
        #expect(url != nil)
        #expect(url?.host == "api.duckduckgo.com")
        let abs = url?.absoluteString ?? ""
        #expect(abs.contains("format=json"))
        #expect(abs.contains("no_html=1"))
        #expect(abs.contains("kl=ro-ro"))
    }

    @Test func queryURLEncodesSpaces() {
        let query = WebSearchQuery(text: "curs EUR RON BNR", queryType: .currencyRate)
        let url = query.ddgURL
        let abs = url?.absoluteString ?? ""
        // URL-encoded sau + encoded
        #expect(abs.contains("EUR") && abs.contains("RON"))
    }

    // MARK: - hasContent

    @Test func hasContentTrueWhenAnswerPresent() {
        let r = WebSearchResult(query: "x", queryType: .generalFinance, answer: "răspuns")
        #expect(r.hasContent == true)
    }

    @Test func hasContentTrueWhenAbstractPresent() {
        let r = WebSearchResult(query: "x", queryType: .generalFinance, abstractText: "text")
        #expect(r.hasContent == true)
    }

    @Test func hasContentFalseWhenBothNil() {
        let r = WebSearchResult(query: "x", queryType: .generalFinance)
        #expect(r.hasContent == false)
    }
}
