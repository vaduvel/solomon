import Testing
import Foundation
@testable import SolomonCore

@Suite struct ObligationTests {

    @Test func debtKindsAreFlaggedAsDebt() {
        let bank = Obligation(name: "Credit BCR", amount: 850, dayOfMonth: 5,
                              kind: .loanBank, confidence: .declared)
        let ifn = Obligation(name: "Credius", amount: 500, dayOfMonth: 18,
                             kind: .loanIFN, confidence: .detected)
        let bnpl = Obligation(name: "Mokka", amount: 240, dayOfMonth: 20,
                              kind: .bnpl, confidence: .detected)
        let rent = Obligation(name: "Chirie", amount: 1_500, dayOfMonth: 1,
                              kind: .rentMortgage, confidence: .declared)

        #expect(bank.isDebt)
        #expect(ifn.isDebt)
        #expect(bnpl.isDebt)
        #expect(!rent.isDebt)
    }

    @Test func essentialKindsAreFlaggedAsEssential() {
        let utility = Obligation(name: "Enel", amount: 220, dayOfMonth: 28,
                                 kind: .utility, confidence: .estimated)
        let insurance = Obligation(name: "CASCO", amount: 171, dayOfMonth: 20,
                                   kind: .insurance, confidence: .declared)
        let netflix = Obligation(name: "Netflix", amount: 40, dayOfMonth: 5,
                                 kind: .subscription, confidence: .detected)
        #expect(utility.isEssential)
        #expect(insurance.isEssential)
        #expect(!netflix.isEssential)
    }

    @Test func confidenceLevelsRoundTrip() throws {
        let cases: [ObligationConfidence] = [.declared, .detected, .estimated]
        for c in cases {
            let data = try JSONEncoder().encode(c)
            let decoded = try JSONDecoder().decode(ObligationConfidence.self, from: data)
            #expect(decoded == c)
        }
    }

    @Test func dayOfMonthValidationAcceptsBoundary() {
        _ = Obligation(name: "x", amount: 100, dayOfMonth: 1, kind: .other, confidence: .declared)
        _ = Obligation(name: "x", amount: 100, dayOfMonth: 31, kind: .other, confidence: .declared)
    }

    @Test func everyKindHasDisplayName() {
        for kind in ObligationKind.allCases {
            #expect(!kind.displayNameRO.isEmpty)
        }
    }
}
