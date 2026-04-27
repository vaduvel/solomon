import Testing
import Foundation
import SolomonCore
@testable import SolomonWeb

@Suite struct WebWhitelistFilterTests {

    let filter = WebWhitelistFilter()

    // MARK: - isAllowed

    @Test func bnrRoIsAllowed() {
        let url = URL(string: "https://bnr.ro/noutati/curs-valutar")!
        #expect(filter.isAllowed(url: url) == true)
    }

    @Test func anafIsAllowed() {
        let url = URL(string: "https://anaf.gov.ro/impozite")!
        #expect(filter.isAllowed(url: url) == true)
    }

    @Test func consoRoIsAllowed() {
        let url = URL(string: "https://conso.ro/depozite")!
        #expect(filter.isAllowed(url: url) == true)
    }

    @Test func randomDomainIsNotAllowed() {
        let url = URL(string: "https://random-site.ro/")!
        #expect(filter.isAllowed(url: url) == false)
    }

    @Test func googleIsNotAllowed() {
        let url = URL(string: "https://google.com/search?q=curs+valutar")!
        #expect(filter.isAllowed(url: url) == false)
    }

    @Test func subdomainBnrIsAllowed() {
        let url = URL(string: "https://www.bnr.ro/pagina.html")!
        #expect(filter.isAllowed(url: url) == true)
    }

    @Test func partialMatchIsNotAllowed() {
        // "fakbnr.ro" nu e pe whitelist
        let url = URL(string: "https://fakbnr.ro/malware")!
        #expect(filter.isAllowed(url: url) == false)
    }

    @Test func asfRoIsAllowed() {
        let url = URL(string: "https://asf.ro/avertismente")!
        #expect(filter.isAllowed(url: url) == true)
    }

    // MARK: - domain(for:)

    @Test func domainForBnrReturnsBNREntry() {
        let url = URL(string: "https://bnr.ro/")!
        let domain = filter.domain(for: url)
        #expect(domain != nil)
        #expect(domain?.host == "bnr.ro")
        #expect(domain?.trustLevel == .high)
    }

    @Test func domainForUnknownReturnsNil() {
        let url = URL(string: "https://unknown-site.xyz/")!
        let domain = filter.domain(for: url)
        #expect(domain == nil)
    }

    @Test func domainForSubdomainReturnsParentEntry() {
        let url = URL(string: "https://static.conso.ro/img/logo.png")!
        let domain = filter.domain(for: url)
        #expect(domain?.host == "conso.ro")
    }

    // MARK: - trustLevel

    @Test func trustLevelHighForOfficialDomains() {
        let officialURLs = [
            "https://bnr.ro",
            "https://anaf.gov.ro",
            "https://asf.ro",
            "https://anpc.ro",
            "https://csalb.ro"
        ]
        for urlStr in officialURLs {
            let url = URL(string: urlStr)!
            #expect(filter.trustLevel(for: url) == .high, "Expected high trust for \(urlStr)")
        }
    }

    @Test func trustLevelMediumForComparators() {
        let url = URL(string: "https://conso.ro")!
        #expect(filter.trustLevel(for: url) == .medium)
    }

    @Test func trustLevelNilForUnknown() {
        let url = URL(string: "https://notinwhitelist.ro")!
        #expect(filter.trustLevel(for: url) == nil)
    }

    // MARK: - domains(matchingTag:)

    @Test func tagsMatchCursValutar() {
        let matches = filter.domains(matchingTag: "curs_valutar")
        #expect(!matches.isEmpty)
        #expect(matches.contains { $0.host == "bnr.ro" })
    }

    @Test func tagsMatchScamAlerts() {
        let matches = filter.domains(matchingTag: "scam_alerts")
        #expect(matches.count >= 2)  // asf.ro + anpc.ro
    }

    @Test func tagsMatchIsCaseInsensitive() {
        let lower = filter.domains(matchingTag: "impozite")
        let upper = filter.domains(matchingTag: "IMPOZITE")
        #expect(lower.count == upper.count)
    }

    @Test func unknownTagReturnsEmpty() {
        let matches = filter.domains(matchingTag: "inexistent_tag_xyz")
        #expect(matches.isEmpty)
    }

    // MARK: - officialDomains

    @Test func officialDomainsAreAllHighTrust() {
        let official = filter.officialDomains
        #expect(!official.isEmpty)
        for d in official {
            #expect(d.trustLevel == .high, "\(d.host) nu are trustLevel .high")
        }
    }

    @Test func officialDomainsContainsBNR() {
        let official = filter.officialDomains
        #expect(official.contains { $0.host == "bnr.ro" })
    }

    // MARK: - cacheTTL

    @Test func cacheTTLForBnrIsSixHours() {
        let url = URL(string: "https://bnr.ro/curs")!
        let ttl = filter.cacheTTL(for: url)
        #expect(ttl == Double(6 * 3600))
    }

    @Test func cacheTTLForUnknownIsNil() {
        let url = URL(string: "https://unknown.ro")!
        let ttl = filter.cacheTTL(for: url)
        #expect(ttl == nil)
    }
}
