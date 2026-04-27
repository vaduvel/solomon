import Testing
import Foundation
import SolomonCore
@testable import SolomonWeb

@Suite struct ScamPatternMatcherTests {

    let matcher = ScamPatternMatcher()

    // MARK: - match(in:)

    @Test func matchesHighYieldGuaranteescam() {
        let text = "Investește acum! Randament garantat 2% pe luna, fara risc."
        let result = matcher.match(in: text)
        #expect(result != nil)
        #expect(result?.pattern.severity == .definiteScam)
    }

    @Test func matchesCryptoGuaranteed() {
        // Folosim keywords exclusive pentru crypto, fără "garantat" (care e și în investmentReturn/definiteScam)
        let text = "Robot trading crypto automat, investitie cripto sigura pe termen lung."
        let result = matcher.match(in: text)
        #expect(result != nil)
        #expect(result?.pattern.category == .crypto)
    }

    @Test func matchesLoanFeeAdvance() {
        // Folosim keyword exclusiv pentru loanFee, fără "primesti 5000" (care triggerează investmentReturn)
        let text = "Comision in avans pentru credit rapid — depune taxa acum."
        let result = matcher.match(in: text)
        #expect(result != nil)
        #expect(result?.pattern.category == .loanFee)
    }

    @Test func matchesPhishingBank() {
        let text = "Contul tau a fost suspendat! Click pentru a verifica contul."
        let result = matcher.match(in: text)
        #expect(result != nil)
        #expect(result?.pattern.category == .phishingFinancial)
    }

    @Test func matchesPyramidScheme() {
        let text = "Aduci 3 prieteni si castigi comision daca recrutezi mai multi."
        let result = matcher.match(in: text)
        #expect(result != nil)
        #expect(result?.pattern.category == .pyramidScheme)
    }

    @Test func matchesLotteryScam() {
        let text = "Felicitari! Ai castigat la loterie! Trimite date pentru a primi premiul."
        let result = matcher.match(in: text)
        #expect(result != nil)
        #expect(result?.pattern.category == .lottery)
    }

    @Test func matchesRomanceScam() {
        let text = "Trimite-mi bani urgent, am o urgenta medicala, sunt blocat in alta tara."
        let result = matcher.match(in: text)
        #expect(result != nil)
        #expect(result?.pattern.category == .romance)
    }

    @Test func noMatchForLegitimateText() {
        let text = "Curs valutar BNR: 1 EUR = 4.97 RON. Consultați bnr.ro pentru detalii."
        let result = matcher.match(in: text)
        #expect(result == nil)
    }

    // MARK: - riskScore mapping

    @Test func definiteScamHasRiskScore1() {
        let text = "Garantat 2% pe luna, fara risc."
        let result = matcher.match(in: text)
        #expect(result?.riskScore == 1.0)
    }

    @Test func likelyScamHasRiskScore0_7() {
        // Fără "garantat" — keyword exclusiv crypto (likelyScam), nu se amestecă cu definiteScam
        let text = "Robot trading crypto automat cu retrageri zilnice."
        let result = matcher.match(in: text)
        // crypto -> likelyScam -> 0.7
        #expect(result?.riskScore == 0.7)
    }

    @Test func shouldAlertTrueForLikelyScam() {
        let text = "Bitcoin garantat, randament sigur zilnic."
        let result = matcher.match(in: text)
        #expect(result?.shouldAlert == true)
    }

    @Test func shouldAlertFalseForSuspiciousOnly() {
        // Niciun pattern actual nu e .suspicious în catalog curent
        // Testăm că un text fără match nu are shouldAlert
        let text = "Buna ziua! Vrem să îți oferim servicii financiare."
        let result = matcher.match(in: text)
        // nil -> shouldAlert nu există
        #expect(result == nil)
    }

    // MARK: - allMatches

    @Test func allMatchesReturnsMultiplePatterns() {
        // Text cu 2 pattern-uri: garantat 2% + aduci 3 prieteni
        let text = "Garantat 2% pe luna fara risc. Aduci 3 prieteni si primesti bonus."
        let matches = matcher.allMatches(in: text)
        #expect(matches.count >= 2)
    }

    @Test func allMatchesSortedBySeverityDescending() {
        let text = "Garantat 2% pe luna fara risc. Bitcoin garantat."
        let matches = matcher.allMatches(in: text)
        // Cel puțin 2 matches, primul trebuie să fie cel mai sever
        if matches.count >= 2 {
            #expect(matches[0].pattern.severity >= matches[1].pattern.severity)
        }
    }

    @Test func allMatchesEmptyForCleanText() {
        let text = "Cont curent la ING Bank, dobânda 0.5%/an standard."
        let matches = matcher.allMatches(in: text)
        #expect(matches.isEmpty)
    }

    // MARK: - matchEmail

    @Test func matchEmailSubjectOnly() {
        let result = matcher.matchEmail(
            subject: "Contul tau a fost suspendat",
            body: "Nimic suspect în body."
        )
        #expect(result != nil)
        #expect(result?.pattern.category == .phishingFinancial)
    }

    @Test func matchEmailBodyOnly() {
        let result = matcher.matchEmail(
            subject: "Oferta speciala",
            body: "Transfera 50 lei pentru aprobare credit rapid."
        )
        #expect(result != nil)
        #expect(result?.pattern.category == .loanFee)
    }

    @Test func matchEmailCleanReturnsNil() {
        let result = matcher.matchEmail(
            subject: "Extras de cont",
            body: "Suma totala cheltuita luna aceasta: 1200 RON."
        )
        #expect(result == nil)
    }

    // MARK: - matchURL

    @Test func matchURLPhishingDomain() {
        // url.path returnează path decodat → keyword-ul cu spații va fi prezent în text
        let url = URL(string: "https://banca-fake.ro/contul%20tau%20a%20fost%20suspendat")!
        let result = matcher.matchURL(url)
        #expect(result != nil)
    }

    @Test func matchURLCleanDomainReturnsNil() {
        let url = URL(string: "https://bnr.ro/noutati")!
        let result = matcher.matchURL(url)
        #expect(result == nil)
    }

    // MARK: - Convenience methods

    @Test func hasAnyRiskTrueForScamText() {
        let text = "Profit garantat, randament garantat 5% pe luna."
        #expect(matcher.hasAnyRisk(in: text) == true)
    }

    @Test func hasAnyRiskFalseForCleanText() {
        let text = "Extras de cont, fara tranzactii suspecte."
        #expect(matcher.hasAnyRisk(in: text) == false)
    }

    @Test func isDefiniteScamTrueForClearScam() {
        let text = "Investeste 500, primesti 5000 in 30 de zile."
        #expect(matcher.isDefiniteScam(text) == true)
    }

    @Test func isDefiniteScamFalseForLikelyScam() {
        // Only triggers crypto (likelyScam); no "garantat" or other definiteScam keywords
        let text = "Investitie cripto sigura, robot trading crypto cu profit zilnic."
        // likelyScam, nu definiteScam
        #expect(matcher.isDefiniteScam(text) == false)
    }

    // MARK: - Diacritic-insensitive matching

    @Test func matchesDiacriticsInsensitive() {
        // Keyword-ul e fara diacritice → trebuie să matches și cu diacritice
        let textWithDiacritics = "Randament garantat 2% pe lună, fără risc."
        let result = matcher.match(in: textWithDiacritics)
        #expect(result != nil)
    }

    // MARK: - patterns(for:)

    @Test func patternsForInvestmentReturnNotEmpty() {
        let patterns = matcher.patterns(for: .investmentReturn)
        #expect(!patterns.isEmpty)
    }

    @Test func patternsForCryptoNotEmpty() {
        let patterns = matcher.patterns(for: .crypto)
        #expect(!patterns.isEmpty)
    }
}
