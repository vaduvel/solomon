import Testing
import Foundation
@testable import SolomonEmail
import SolomonCore

@Suite struct SubjectClassifierTests {

    let sc = SubjectClassifier()

    // MARK: - Financial relevance

    @Test func facturaTriggerRelevance() {
        #expect(sc.isFinanciallyRelevant("Factura ta din luna aprilie"))
    }

    @Test func comandaTriggerRelevance() {
        #expect(sc.isFinanciallyRelevant("Comanda ta #123456 a fost confirmată"))
    }

    @Test func abonamentTriggerRelevance() {
        #expect(sc.isFinanciallyRelevant("Abonamentul tău Netflix a fost reînnoit"))
    }

    @Test func confirmarePaymentTriggerRelevance() {
        #expect(sc.isFinanciallyRelevant("Confirmare plată Glovo"))
    }

    @Test func englishInvoiceTriggerRelevance() {
        #expect(sc.isFinanciallyRelevant("Your invoice #456 is ready"))
    }

    @Test func irrelevantSubjectReturnsFalse() {
        #expect(!sc.isFinanciallyRelevant("Bun venit înapoi! Ne-a fost dor de tine."))
    }

    @Test func greetingSubjectReturnsFalse() {
        #expect(!sc.isFinanciallyRelevant("Cum a fost weekendul?"))
    }

    // MARK: - Diacritic-insensitive matching

    @Test func matchesWithoutDiacritics() {
        // "plata" fără diacritice ar trebui să dea match la "plată"
        #expect(sc.isFinanciallyRelevant("Confirmare plata dvs."))
    }

    // MARK: - Direction inference

    @Test func subjectWithPlatitInfersOutgoing() {
        #expect(sc.inferDirection("Confirmare plată Glovo") == .outgoing)
    }

    @Test func subjectWithRambursareInfersIncoming() {
        #expect(sc.inferDirection("Rambursare procesată cu succes") == .incoming)
    }

    @Test func subjectWithPrimitInfersIncoming() {
        #expect(sc.inferDirection("Transfer primit în cont") == .incoming)
    }

    @Test func ambiguousSubjectReturnsNil() {
        #expect(sc.inferDirection("Notificare contul tău") == nil)
    }

    // MARK: - Category hints

    @Test func netflixSubjectSuggestsSubscriptions() {
        let cat = sc.suggestCategory("Abonamentul tău Netflix a fost reînnoit")
        #expect(cat == .subscriptions)
    }

    @Test func bookingSubjectSuggestsTravel() {
        let cat = sc.suggestCategory("Rezervarea ta la Booking.com a fost confirmată")
        #expect(cat == .travel)
    }

    @Test func uberSubjectSuggestsTransport() {
        let cat = sc.suggestCategory("Confirmarea călătoriei Uber")
        #expect(cat == .transport)
    }

    @Test func unknownSubjectReturnsNil() {
        let cat = sc.suggestCategory("Notificare cont bancar")
        #expect(cat == nil)
    }
}
