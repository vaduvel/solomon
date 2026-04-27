import Testing
import Foundation
@testable import SolomonAnalytics
import SolomonCore

@Suite struct ObligationMapperTests {

    private func obligation(_ name: String, _ amount: Int, day: Int,
                            kind: ObligationKind = .other,
                            confidence: ObligationConfidence = .declared) -> Obligation {
        Obligation(name: name, amount: Money(amount), dayOfMonth: day,
                   kind: kind, confidence: confidence)
    }

    @Test func sumsTotalAndComputesRatio() {
        let declared = [
            obligation("Chirie", 1_500, day: 1, kind: .rentMortgage),
            obligation("Internet Digi", 65, day: 15, kind: .utility),
            obligation("Curent Enel", 220, day: 28, kind: .utility),
            obligation("Netflix", 40, day: 5, kind: .subscription)
        ]
        let map = ObligationMapper().map(
            declared: declared, detected: [],
            monthlyIncomeAvg: 4_500
        )
        #expect(map.monthlyTotalFixed == 1_825)
        #expect(abs(map.obligationsToIncomeRatio - 0.4055) < 0.01)
    }

    @Test func calendarBucketsByDayOfMonth() {
        let declared = [
            obligation("Chirie", 1_500, day: 1),
            obligation("Sală", 150, day: 1),
            obligation("Netflix", 40, day: 5)
        ]
        let map = ObligationMapper().map(declared: declared, monthlyIncomeAvg: 4_500)
        #expect(map.calendarByDay[1]?.count == 2)
        #expect(map.calendarByDay[5]?.count == 1)
        // Sortat descrescător după sumă.
        #expect(map.calendarByDay[1]?.first?.name == "Chirie")
    }

    @Test func detectedDoesntDuplicateDeclared() {
        let declared = [
            obligation("Netflix", 40, day: 5)
        ]
        let detected = [
            obligation("netflix", 40, day: 5, confidence: .detected),  // case-insensitive match
            obligation("Spotify", 25, day: 10, confidence: .detected)  // nou
        ]
        let map = ObligationMapper().map(
            declared: declared, detected: detected, monthlyIncomeAvg: 4_500
        )
        #expect(map.allObligations.count == 2)
        #expect(map.detectedSilent.count == 1)
        #expect(map.detectedSilent.first?.name == "Spotify")
    }

    @Test func debtTotalSumsOnlyDebtKinds() {
        let obligations = [
            obligation("Chirie", 1_500, day: 1, kind: .rentMortgage),
            obligation("Credit BCR", 850, day: 5, kind: .loanBank),
            obligation("Credius", 500, day: 18, kind: .loanIFN),
            obligation("Mokka", 240, day: 20, kind: .bnpl)
        ]
        let map = ObligationMapper().map(declared: obligations, monthlyIncomeAvg: 4_500)
        #expect(map.debtMonthlyTotal == 1_590)
    }

    @Test func obligationsRemainingFromDayFiltersAndSorts() {
        let obligations = [
            obligation("Chirie", 1_500, day: 1),
            obligation("Internet", 65, day: 15),
            obligation("Curent Enel", 280, day: 28),
            obligation("CASCO", 171, day: 20)
        ]
        let map = ObligationMapper().map(declared: obligations, monthlyIncomeAvg: 4_500)
        let remaining = map.obligationsRemainingFrom(day: 18)
        #expect(remaining.count == 2)
        #expect(remaining[0].dayOfMonth == 20)
        #expect(remaining[1].dayOfMonth == 28)
    }
}

@Suite struct SafeToSpendCalculatorTests {

    @Test func happyPathFromSpec() {
        // Spec §6.3 fixture: balance 2160, obligations 1780, 9 zile până la salariu.
        // available = 380, per day = 42 RON.
        let budget = SafeToSpendCalculator().calculate(
            currentBalance: 2_160,
            obligationsRemaining: 1_780,
            daysUntilNextPayday: 9
        )
        #expect(budget.availableAfterObligations == 380)
        #expect(budget.availablePerDay == 42)
    }

    @Test func bufferIsTenPercentMinFifty() {
        let small = SafeToSpendCalculator().calculate(
            currentBalance: 200, obligationsRemaining: 0, daysUntilNextPayday: 5
        )
        // 10% from 200 = 20, dar floor-ul e 50.
        #expect(small.bufferRecommended == 50)

        let large = SafeToSpendCalculator().calculate(
            currentBalance: 5_000, obligationsRemaining: 0, daysUntilNextPayday: 30
        )
        // 10% from 5000 = 500.
        #expect(large.bufferRecommended == 500)
    }

    @Test func negativeAfterObligationsHasZeroBuffer() {
        let budget = SafeToSpendCalculator().calculate(
            currentBalance: 1_500, obligationsRemaining: 1_800, daysUntilNextPayday: 10
        )
        #expect(budget.availableAfterObligations == -300)
        #expect(budget.bufferRecommended == 0)
        #expect(budget.daysUntilCritical == 0)
    }

    @Test func tightFlagAtThirtyOrLess() {
        let tight = SafeToSpendCalculator().calculate(
            currentBalance: 350, obligationsRemaining: 100, daysUntilNextPayday: 10
        )
        // available 250 / 10 = 25/zi → tight
        #expect(tight.isTight)
    }

    @Test func verdictYesForComfortableMargin() {
        let budget = SafeToSpendCalculator().calculate(
            currentBalance: 3_000, obligationsRemaining: 800, daysUntilNextPayday: 10
        )
        let verdict = budget.verdict(for: Money(80))
        if case .yes = verdict { } else { Issue.record("Așteptam YES, am primit \(verdict)") }
    }

    @Test func verdictYesWithCautionWhenTight() {
        let budget = SafeToSpendCalculator().calculate(
            currentBalance: 2_160, obligationsRemaining: 1_780, daysUntilNextPayday: 9
        )
        let verdict = budget.verdict(for: Money(80))
        if case .yesWithCaution = verdict { } else { Issue.record("Așteptam YES_WITH_CAUTION, am primit \(verdict)") }
    }

    @Test func verdictNoWhenWouldBreakObligation() {
        let budget = SafeToSpendCalculator().calculate(
            currentBalance: 2_160, obligationsRemaining: 1_780, daysUntilNextPayday: 9
        )
        // available 380, cer 500
        let verdict = budget.verdict(for: Money(500))
        #expect(!verdict.isAffordable)
        if case .no(let reason) = verdict {
            #expect(reason == .wouldBreakObligation)
        } else {
            Issue.record("Așteptam NO, am primit \(verdict)")
        }
    }

    @Test func daysUntilCriticalUsesVelocity() {
        // velocity 50 RON/zi, available 200 = 4 zile critice
        let budget = SafeToSpendCalculator().calculate(
            currentBalance: 200, obligationsRemaining: 0,
            daysUntilNextPayday: 10, velocityRONPerDay: Money(50)
        )
        #expect(budget.daysUntilCritical == 4)
    }
}
