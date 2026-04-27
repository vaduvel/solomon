import Testing
import Foundation
@testable import SolomonEmail
import SolomonCore

// MARK: - Sample emails

private let cal = Calendar.gregorianRO

private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
    var c = DateComponents(); c.year = y; c.month = m; c.day = d
    return cal.date(from: c) ?? Date()
}

// Glovo email tipic
private let glovoEmail = EmailMessage(
    from: "no-reply@glovoapp.com",
    subject: "Confirmarea comenzii tale Glovo",
    bodyText: """
    Bună ziua!
    Comanda ta a fost livrată cu succes.
    Taxa livrare: 9 RON
    Total comandă: 187 RON
    Plătit cu cardul.
    """,
    date: date(2026, 4, 15)
)

// Netflix renewal
private let netflixEmail = EmailMessage(
    from: "info@account.netflix.com",
    subject: "Abonamentul tău Netflix a fost reînnoit",
    bodyText: """
    Abonamentul tău Standard Netflix a fost reînnoit automat.
    Sumă percepută: 40 RON
    Data facturare: 15 aprilie 2026
    """,
    date: date(2026, 4, 15)
)

// Credius IFN — credit primit
private let crediusEmail = EmailMessage(
    from: "no-reply@credius.ro",
    subject: "Credit aprobat și virat în cont",
    bodyText: """
    Felicitări! Creditul tău de 2.500 RON a fost aprobat și virat.
    Rata lunară: 280 RON/lună × 10 luni.
    """,
    date: date(2026, 4, 18)
)

// Email necunoscut, dar cu sumă în body
private let unknownEmailWithAmount = EmailMessage(
    from: "noreply@some-unknown-shop.ro",
    subject: "Confirmare comandă #789",
    bodyText: "Comanda ta de 349 RON a fost plasată cu succes.",
    date: date(2026, 4, 10)
)

// Email complet irelevant
private let irrelevantEmail = EmailMessage(
    from: "hello@newsletter.ro",
    subject: "Weekendul se apropie!",
    bodyText: "Salut! Ai planuri pentru weekend?",
    date: date(2026, 4, 12)
)

// MARK: - Tests

@Suite struct EmailTransactionParserTests {

    let parser = EmailTransactionParser()

    // MARK: - Known sender, full confidence

    @Test func glovoEmailProducesHighConfidenceResult() {
        let result = parser.parse(glovoEmail)
        #expect(result != nil)
        #expect(result?.merchant == "Glovo")
        #expect(result?.direction == .outgoing)
        #expect(result?.suggestedCategory == .foodDelivery)
        #expect(result?.confidence ?? 0 >= 0.80)
        #expect(result?.isAutoImportReady == true)
    }

    @Test func glovoEmailExtractsPrimaryAmount() {
        let result = parser.parse(glovoEmail)
        // Total 187 RON trebuie să fie suma principală
        #expect(result?.amount?.value == 187)
        #expect(result?.amount?.currency == .ron)
    }

    @Test func glovoEmailTransactionConversion() {
        let result = parser.parse(glovoEmail)!
        let tx = result.toTransaction()
        #expect(tx != nil)
        #expect(tx?.amount == Money(187))
        #expect(tx?.direction == .outgoing)
        #expect(tx?.source == .emailParsed)
    }

    @Test func netflixEmailProducesSubscriptionCategory() {
        let result = parser.parse(netflixEmail)
        #expect(result?.suggestedCategory == .subscriptions)
        #expect(result?.amount?.value == 40)
        #expect(result?.direction == .outgoing)
        #expect(result?.confidence ?? 0 >= 0.80)
    }

    // MARK: - IFN detection

    @Test func crediusEmailDetectedAsIncoming() {
        let result = parser.parse(crediusEmail)
        #expect(result != nil)
        #expect(result?.merchant == "Credius")
        // "credit aprobat și virat" → incoming
        #expect(result?.direction == .incoming)
        #expect(result?.amount?.value == 2500)
    }

    // MARK: - Unknown sender

    @Test func unknownSenderWithAmountReturnsKeywordConfidence() {
        let result = parser.parse(unknownEmailWithAmount)
        #expect(result != nil)
        #expect(result?.confidenceSource == .keywordMatch)
        #expect(result?.confidence ?? 0 < 0.80)
        #expect(result?.requiresManualReview == true)
        #expect(result?.amount?.value == 349)
    }

    @Test func irrelevantEmailReturnsNil() {
        let result = parser.parse(irrelevantEmail)
        #expect(result == nil)
    }

    // MARK: - Missing amount penalties

    @Test func knownSenderNoAmountReducesConfidence() {
        let email = EmailMessage(
            from: "no-reply@glovoapp.com",
            subject: "Livrarea ta este în drum",
            bodyText: "Curierul este pe drum.",
            date: date(2026, 4, 15)
        )
        let result = parser.parse(email)
        // Sender cunoscut dar fără sumă → confidence sub 0.80
        let c = result?.confidence ?? 0
        #expect(c < 0.80)
    }

    // MARK: - Date passthrough

    @Test func parsedResultPreservesEmailDate() {
        let result = parser.parse(glovoEmail)
        #expect(result?.date == glovoEmail.date)
    }

    // MARK: - Confidence source

    @Test func exactSenderMatchProducesCorrectSource() {
        let result = parser.parse(glovoEmail)
        #expect(result?.confidenceSource == .senderExactMatch)
    }

    @Test func unknownSenderProducesKeywordSource() {
        let result = parser.parse(unknownEmailWithAmount)
        #expect(result?.confidenceSource == .keywordMatch)
    }

    // MARK: - Batch parse

    @Test func batchParseFiveEmails() {
        let emails = [glovoEmail, netflixEmail, crediusEmail, unknownEmailWithAmount, irrelevantEmail]
        let results = emails.compactMap { parser.parse($0) }
        // Emailul irelevant trebuie exclus
        #expect(results.count == 4)
    }
}
