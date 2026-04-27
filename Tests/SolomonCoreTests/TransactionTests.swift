import Testing
import Foundation
@testable import SolomonCore

@Suite struct TransactionTests {

    @Test func signedAmountReflectsDirection() {
        let income = Transaction(
            date: Date(),
            amount: 4_500,
            direction: .incoming,
            category: .savings,
            source: .csvImport
        )
        let expense = Transaction(
            date: Date(),
            amount: 80,
            direction: .outgoing,
            category: .foodDining,
            source: .emailParsed
        )
        #expect(income.signedAmount == 4_500)
        #expect(expense.signedAmount == -80)
    }

    @Test func confidenceClampedTo01() {
        let txOver = Transaction(
            date: Date(), amount: 10, direction: .outgoing,
            category: .unknown, source: .manualEntry,
            categorizationConfidence: 1.7
        )
        let txUnder = Transaction(
            date: Date(), amount: 10, direction: .outgoing,
            category: .unknown, source: .manualEntry,
            categorizationConfidence: -0.3
        )
        #expect(txOver.categorizationConfidence == 1.0)
        #expect(txUnder.categorizationConfidence == 0.0)
    }

    @Test func codableRoundTripPreservesAllFields() throws {
        let original = Transaction(
            date: Date(timeIntervalSince1970: 1_700_000_000),
            amount: 287,
            direction: .outgoing,
            category: .foodDelivery,
            merchant: "Glovo",
            description: "Comandă vineri seara",
            source: .emailParsed,
            categorizationConfidence: 0.92
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Transaction.self, from: data)
        #expect(decoded == original)
    }
}
