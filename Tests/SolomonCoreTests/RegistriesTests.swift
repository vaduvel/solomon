import Testing
import Foundation
@testable import SolomonCore

@Suite struct IFNDatabaseTests {

    @Test func sevenIFNsAndOneSoftConsumerCreditDeclared() {
        // Spec §10.1 listează 8 IFN-uri toxice + Cetelem (consumer credit „soft").
        #expect(IFNDatabase.all.count == 9)
    }

    @Test func everyIFNHasReasonableDAERange() {
        for ifn in IFNDatabase.all {
            #expect(ifn.daeMinPercent > 0)
            #expect(ifn.daeMaxPercent >= ifn.daeMinPercent)
        }
    }

    @Test func extremeRiskTierIncludesCrediusAndIuteAndAcredit() {
        let extreme = IFNDatabase.atLeast(.extreme)
        let names = Set(extreme.map(\.name))
        #expect(names.contains("Credius"))
        #expect(names.contains("IUTE Credit"))
        #expect(names.contains("Acredit"))
    }

    @Test func lookupBySenderFindsCredius() {
        let credius = IFNDatabase.record(forSender: "no-reply@credius.ro")
        #expect(credius?.name == "Credius")
        #expect(credius?.riskTier == .extreme)
    }

    @Test func lookupByDomainIsCaseInsensitive() {
        let r1 = IFNDatabase.record(forDomain: "credius.ro")
        let r2 = IFNDatabase.record(forDomain: "CREDIUS.RO")
        #expect(r1 == r2)
        #expect(r1?.name == "Credius")
    }

    @Test func cetelemIsSoftConsumerCredit() {
        let cetelem = IFNDatabase.record(forDomain: "cetelem.ro")
        #expect(cetelem?.riskTier == .high)
        #expect(cetelem?.daeMaxPercent ?? 0 < 50)
    }

    @Test func multiplierGrowsWithLongerTerm() {
        let credius = IFNDatabase.record(forSender: "no-reply@credius.ro")!
        let m6 = credius.estimatedRepaymentMultiplier(termMonths: 6)
        let m12 = credius.estimatedRepaymentMultiplier(termMonths: 12)
        #expect(m12 > m6)
        #expect(m6 > 1.0, "Pentru orice împrumut, rambursezi mai mult decât ai luat")
    }
}

@Suite struct EmailSenderRegistryTests {

    @Test func atLeastEightyEntries() {
        // Spec §3.1 menționează „~80 domenii financiare". Construcția noastră are mai mult cu BNPL+IFN.
        #expect(EmailSenderRegistry.all.count >= 80)
    }

    @Test func everyCategoryHasSomeSenders() {
        for category in EmailSenderCategory.allCases {
            let entries = EmailSenderRegistry.senders(in: category)
            #expect(!entries.isEmpty, "Categoria \(category) e goală")
        }
    }

    @Test func glovoMatchesExactly() {
        let result = EmailSenderRegistry.match(for: "no-reply@glovoapp.com")
        #expect(result?.0.displayName == "Glovo")
        #expect(result?.0.category == .foodDelivery)
        #expect(result?.0.defaultTransactionCategory == .foodDelivery)
        #expect(result?.1 == .exact)
    }

    @Test func subdomainFallsBackToParentDomain() {
        let result = EmailSenderRegistry.match(for: "noreply@notifications.bt.ro")
        #expect(result?.0.displayName == "Banca Transilvania")
        #expect(result?.1 == .domain)
    }

    @Test func unknownSenderReturnsNil() {
        #expect(EmailSenderRegistry.match(for: "spam@unknown-domain.xyz") == nil)
    }

    @Test func ifnSendersAreSpecifiedAsIFNCategory() {
        let credius = EmailSenderRegistry.match(for: "no-reply@credius.ro")
        #expect(credius?.0.category == .ifn)
        #expect(credius?.0.defaultTransactionCategory == .loansIFN)
    }

    @Test func bnplSendersAreCorrectlyClassified() {
        let mokka = EmailSenderRegistry.match(for: "hello@mokka.ro")
        #expect(mokka?.0.category == .bnpl)
        #expect(mokka?.0.defaultTransactionCategory == .bnpl)
    }
}

@Suite struct WebSearchWhitelistTests {

    @Test func allMandatoryDomainsPresent() {
        let hosts = Set(WebSearchWhitelist.all.map(\.host))
        #expect(hosts.contains("bnr.ro"))
        #expect(hosts.contains("anaf.gov.ro"))
        #expect(hosts.contains("asf.ro"))
        #expect(hosts.contains("anpc.ro"))
        #expect(hosts.contains("csalb.ro"))
    }

    @Test func officialSourcesHaveHighTrust() {
        for entry in WebSearchWhitelist.entries(for: .official) {
            #expect(entry.trustLevel == .high)
        }
    }

    @Test func newsCachedSevenDays() {
        for entry in WebSearchWhitelist.entries(for: .news) {
            #expect(entry.defaultCachePolicy == .sevenDays)
        }
    }

    @Test func isAllowedAcceptsExactHost() {
        #expect(WebSearchWhitelist.isAllowed(URL(string: "https://bnr.ro/cursuri")!))
    }

    @Test func isAllowedAcceptsSubdomain() {
        #expect(WebSearchWhitelist.isAllowed(URL(string: "https://www.bnr.ro/cursuri")!))
        #expect(WebSearchWhitelist.isAllowed(URL(string: "https://comunicate.asf.ro/")!))
    }

    @Test func isAllowedRejectsUnknownDomain() {
        #expect(!WebSearchWhitelist.isAllowed(URL(string: "https://random-blog.com/finance")!))
    }
}

@Suite struct ScamPatternsTests {

    @Test func atLeastTenPatternsDefined() {
        // Spec §13.3: „Database scam patterns RO active (10+ patterns cunoscute)".
        #expect(ScamPatterns.all.count >= 10)
    }

    @Test func matchesKnownHighYieldClaim() {
        let match = ScamPatterns.match(in: "Investește acum, 2% pe luna garantat, fara risc")
        #expect(match?.code == "high_yield_2pct_monthly")
        #expect(match?.severity == .definiteScam)
    }

    @Test func matchingIsDiacriticInsensitive() {
        // „lună" cu diacritică și „luna" fără trebuie să dea același match.
        let withDiacritics = ScamPatterns.match(in: "2% pe lună, randament garantat")
        let withoutDiacritics = ScamPatterns.match(in: "2% pe luna, randament garantat")
        #expect(withDiacritics?.code == "high_yield_2pct_monthly")
        #expect(withoutDiacritics?.code == "high_yield_2pct_monthly")
    }

    @Test func matchingIsCaseInsensitive() {
        let upper = ScamPatterns.match(in: "TRANSFERA 50 LEI PENTRU APROBARE")
        #expect(upper?.code == "loan_fee_advance")
    }

    @Test func phishingPatternMatchesBankSuspension() {
        let match = ScamPatterns.match(in: "Contul tau a fost suspendat. Click pentru a verifica contul.")
        #expect(match?.category == .phishingFinancial)
    }

    @Test func benignTextReturnsNoMatch() {
        let match = ScamPatterns.match(in: "Salut, ce mai faci? Vorbim luni la cafea?")
        #expect(match == nil)
    }

    @Test func severityIsComparable() {
        #expect(ScamSeverity.suspicious < .likelyScam)
        #expect(ScamSeverity.likelyScam < .definiteScam)
    }

    @Test func everyPatternHasNonEmptyExplanation() {
        for pattern in ScamPatterns.all {
            #expect(!pattern.explanation.isEmpty)
            #expect(!pattern.recommendation.isEmpty)
            #expect(!pattern.keywords.isEmpty)
        }
    }
}
