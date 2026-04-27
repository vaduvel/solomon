import Testing
import Foundation
@testable import SolomonWeb

// MARK: - Helpers

private func makeResult(query: String = "test", type: WebQueryType = .generalFinance) -> WebSearchResult {
    WebSearchResult(
        query: query,
        queryType: type,
        answer: "Răspuns test",
        abstractText: "Abstract test",
        sourceURL: URL(string: "https://bnr.ro"),
        relatedTopics: ["topic1"],
        fetchedAt: Date()
    )
}

// MARK: - Tests

@Suite struct WebSearchCacheTests {

    // MARK: - Basic get/set

    @Test func setAndGetReturnsResult() async {
        let cache = WebSearchCache()
        let result = makeResult()
        await cache.set(key: "k1", result: result, ttl: 3600)
        let fetched = await cache.get(key: "k1")
        #expect(fetched != nil)
        #expect(fetched?.query == "test")
    }

    @Test func getCachedResultHasIsFromCacheTrue() async {
        let cache = WebSearchCache()
        let result = makeResult()
        await cache.set(key: "k1", result: result, ttl: 3600)
        let fetched = await cache.get(key: "k1")
        #expect(fetched?.isFromCache == true)
    }

    @Test func getMissingKeyReturnsNil() async {
        let cache = WebSearchCache()
        let fetched = await cache.get(key: "nonexistent")
        #expect(fetched == nil)
    }

    // MARK: - TTL expiry

    @Test func expiredEntryReturnsNil() async {
        let cache = WebSearchCache()
        let result = makeResult()
        // TTL -1 → already expired
        await cache.set(key: "k_expired", result: result, ttl: -1)
        let fetched = await cache.get(key: "k_expired")
        #expect(fetched == nil)
    }

    @Test func notYetExpiredEntryReturnsResult() async {
        let cache = WebSearchCache()
        let result = makeResult()
        // TTL un an → nu expiră
        await cache.set(key: "k_long", result: result, ttl: 365 * 24 * 3600)
        let fetched = await cache.get(key: "k_long")
        #expect(fetched != nil)
    }

    // MARK: - Invalidate

    @Test func invalidateRemovesEntry() async {
        let cache = WebSearchCache()
        let result = makeResult()
        await cache.set(key: "k_inv", result: result, ttl: 3600)
        await cache.invalidate(key: "k_inv")
        let fetched = await cache.get(key: "k_inv")
        #expect(fetched == nil)
    }

    @Test func invalidateNonExistentIsNoop() async {
        let cache = WebSearchCache()
        // Nu aruncă excepție
        await cache.invalidate(key: "ghost")
        let count = await cache.count
        #expect(count == 0)
    }

    // MARK: - Count

    @Test func countReflectsSetEntries() async {
        let cache = WebSearchCache()
        await cache.set(key: "a", result: makeResult(query: "a"), ttl: 3600)
        await cache.set(key: "b", result: makeResult(query: "b"), ttl: 3600)
        let count = await cache.count
        #expect(count == 2)
    }

    @Test func validCountExcludesExpired() async {
        let cache = WebSearchCache()
        await cache.set(key: "valid", result: makeResult(query: "ok"), ttl: 3600)
        await cache.set(key: "expired", result: makeResult(query: "bad"), ttl: -1)
        let valid = await cache.validCount
        #expect(valid == 1)
    }

    // MARK: - PurgeAll

    @Test func purgeAllClearsStore() async {
        let cache = WebSearchCache()
        for i in 0..<5 {
            await cache.set(key: "k\(i)", result: makeResult(query: "q\(i)"), ttl: 3600)
        }
        await cache.purgeAll()
        let count = await cache.count
        #expect(count == 0)
    }

    // MARK: - PurgeExpired

    @Test func purgeExpiredKeepsValidEntries() async {
        let cache = WebSearchCache()
        await cache.set(key: "good1", result: makeResult(query: "g1"), ttl: 3600)
        await cache.set(key: "good2", result: makeResult(query: "g2"), ttl: 3600)
        await cache.set(key: "expired1", result: makeResult(query: "e1"), ttl: -1)
        await cache.purgeExpired()
        let count = await cache.count
        #expect(count == 2)
    }

    @Test func purgeExpiredRemovesExpiredEntries() async {
        let cache = WebSearchCache()
        await cache.set(key: "expired1", result: makeResult(query: "e1"), ttl: -1)
        await cache.set(key: "expired2", result: makeResult(query: "e2"), ttl: -1)
        await cache.purgeExpired()
        let count = await cache.count
        #expect(count == 0)
    }

    // MARK: - Cache key uniqueness per type

    @Test func differentTypesHaveIndependentKeys() async {
        let cache = WebSearchCache()
        let r1 = makeResult(query: "test", type: .currencyRate)
        let r2 = makeResult(query: "test", type: .scamAlert)
        let q1 = WebSearchQuery(text: "test", queryType: .currencyRate)
        let q2 = WebSearchQuery(text: "test", queryType: .scamAlert)
        await cache.set(key: q1.cacheKey, result: r1, ttl: 3600)
        await cache.set(key: q2.cacheKey, result: r2, ttl: 3600)
        let count = await cache.count
        // Chei diferite deoarece `queryType` diferă
        #expect(count == 2)
    }

    // MARK: - TTL per query type constants

    @Test func currencyRateTTLIsSixHours() {
        #expect(WebQueryType.currencyRate.cacheTTL == 6 * 3600)
    }

    @Test func scamAlertTTLIsOneHour() {
        #expect(WebQueryType.scamAlert.cacheTTL == 3600)
    }

    @Test func interestRateTTLIs24Hours() {
        #expect(WebQueryType.interestRate.cacheTTL == 24 * 3600)
    }

    @Test func generalFinanceTTLIs24Hours() {
        #expect(WebQueryType.generalFinance.cacheTTL == 24 * 3600)
    }

    @Test func priceComparisonTTLIsSixHours() {
        #expect(WebQueryType.priceComparison.cacheTTL == 6 * 3600)
    }
}
