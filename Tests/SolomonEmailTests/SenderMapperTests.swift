import Testing
import Foundation
@testable import SolomonEmail
import SolomonCore

@Suite struct SenderMapperTests {

    let mapper = SenderMapper()

    // MARK: - Exact match

    @Test func exactMatchGlovoReturnsHighConfidence() {
        let result = mapper.map(from: "no-reply@glovoapp.com")
        #expect(result != nil)
        #expect(result?.sender.displayName == "Glovo")
        #expect(result?.confidence == .exact)
        #expect(result?.confidenceScore == 0.90)
    }

    @Test func exactMatchBTReturnsHighConfidence() {
        let result = mapper.map(from: "notificare@bt.ro")
        #expect(result != nil)
        #expect(result?.sender.displayName == "Banca Transilvania")
        #expect(result?.confidence == .exact)
    }

    @Test func exactMatchNetflixReturnsHighConfidence() {
        let result = mapper.map(from: "info@account.netflix.com")
        #expect(result != nil)
        #expect(result?.sender.category == .streaming)
    }

    @Test func exactMatchMokkaReturnsBNPLCategory() {
        let result = mapper.map(from: "hello@mokka.ro")
        #expect(result?.sender.category == .bnpl)
    }

    @Test func exactMatchCrediusReturnsIFNCategory() {
        let result = mapper.map(from: "no-reply@credius.ro")
        #expect(result?.sender.category == .ifn)
    }

    // MARK: - Domain match (subdomain)

    @Test func subdomainMatchReturnsMediumConfidence() {
        // "alerts.glovoapp.com" e subdomain al "glovoapp.com"
        let result = mapper.map(from: "alerts@alerts.glovoapp.com")
        #expect(result != nil)
        #expect(result?.confidence == .domain)
        #expect(result?.confidenceScore == 0.70)
    }

    @Test func differentDomainReturnsNil() {
        // "glovoapp.net" nu e în whitelist
        let result = mapper.map(from: "no-reply@glovoapp.net")
        #expect(result == nil)
    }

    // MARK: - Unknown sender

    @Test func unknownSenderReturnsNil() {
        let result = mapper.map(from: "newsletter@unrelated-brand.com")
        #expect(result == nil)
    }

    @Test func emptyFromReturnsNil() {
        let result = mapper.map(from: "")
        #expect(result == nil)
    }

    // MARK: - Case insensitivity

    @Test func matchIsCaseInsensitive() {
        let result = mapper.map(from: "NO-REPLY@GLOVOAPP.COM")
        #expect(result != nil)
        #expect(result?.sender.displayName == "Glovo")
    }

    // MARK: - Category mapping

    @Test func wolterMapsToFoodDelivery() {
        let result = mapper.map(from: "no-reply@wolt.com")
        #expect(result?.sender.defaultTransactionCategory == .foodDelivery)
    }

    @Test func spotifyMapsToSubscriptions() {
        let result = mapper.map(from: "no-reply@spotify.com")
        #expect(result?.sender.category == .streaming)
    }
}
