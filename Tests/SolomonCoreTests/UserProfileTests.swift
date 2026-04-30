import Testing
import Foundation
@testable import SolomonCore

@Suite struct AddressingTests {

    @Test func tuFormHasShortPronouns() {
        #expect(Addressing.tu.subjectPronoun == "tu")
        #expect(Addressing.tu.canVerb == "poți")
    }

    @Test func formalAddressingHasFullPronoun() {
        #expect(Addressing.dumneavoastra.subjectPronoun == "dumneavoastră")
        #expect(Addressing.dumneavoastra.canVerb == "puteți")
    }

    @Test func codableRawValuesMatchSpec() throws {
        // Spec §6.2: addressing serializat ca "tu" / "dumneavoastra"
        // (forma fără diacritice e folosită de partea tehnică).
        let tuData = try JSONEncoder().encode(Addressing.tu)
        #expect(String(data: tuData, encoding: .utf8) == "\"tu\"")

        let formalData = try JSONEncoder().encode(Addressing.dumneavoastra)
        #expect(String(data: formalData, encoding: .utf8) == "\"dumneavoastra\"")
    }
}

@Suite struct AgeRangeTests {

    @Test func fourBucketsCoverWholePopulation() {
        #expect(AgeRange.allCases.count == 4)
    }

    @Test func rawValuesMatchSpec() {
        #expect(AgeRange.under25.rawValue == "<25")
        #expect(AgeRange.range25to35.rawValue == "25-35")
        #expect(AgeRange.range35to45.rawValue == "35-45")
        #expect(AgeRange.over45.rawValue == "45+")
    }
}

@Suite struct SalaryRangeTests {

    @Test func fiveBucketsCoverFullSpread() {
        #expect(SalaryRange.allCases.count == 5)
    }

    @Test func midpointsAreMonotonic() {
        let midpoints = SalaryRange.allCases.map(\.midpointRON)
        let sorted = midpoints.sorted()
        #expect(midpoints == sorted, "Midpoints trebuie să fie crescătoare")
    }

    @Test func midpointsAreReasonable() {
        // Punctele medii ale intervalelor declarate în spec.
        #expect(SalaryRange.under3k.midpointRON < 3_000)
        #expect((3_000...5_000).contains(SalaryRange.range3to5.midpointRON))
        #expect((5_000...8_000).contains(SalaryRange.range5to8.midpointRON))
        #expect((8_000...15_000).contains(SalaryRange.range8to15.midpointRON))
        #expect(SalaryRange.over15k.midpointRON > 15_000)
    }
}

@Suite struct SalaryFrequencyTests {

    @Test func monthlyAndBimonthlyArePredictable() {
        #expect(SalaryFrequency.monthly(dayOfMonth: 15).isPredictable)
        #expect(SalaryFrequency.bimonthly(firstDay: 15, secondDay: 30).isPredictable)
        #expect(!SalaryFrequency.variable.isPredictable)
    }

    @Test func codableRoundTripPreservesAssociatedValues() throws {
        let original = SalaryFrequency.bimonthly(firstDay: 15, secondDay: 30)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SalaryFrequency.self, from: data)
        #expect(decoded == original)
    }
}

@Suite struct BankTests {

    @Test func banksDeclared() {
        // 16 bănci RO din spec §8.1 (incl. Idea) + cazul `.other`.
        // Sincronizat cu enum Bank — actualizează când adaugi/scoți bănci.
        #expect(Bank.allCases.count == 17)
    }

    @Test func everyBankHasDisplayName() {
        for bank in Bank.allCases {
            #expect(!bank.displayNameRO.isEmpty)
        }
    }
}

@Suite struct UserProfileTests {

    @Test func fullRoundTripPreservesEverything() throws {
        let original = UserProfile(
            demographics: DemographicProfile(
                name: "Daniel",
                addressing: .tu,
                ageRange: .range25to35
            ),
            financials: FinancialProfile(
                salaryRange: .range3to5,
                salaryFrequency: .monthly(dayOfMonth: 15),
                hasSecondaryIncome: true,
                secondaryIncomeAvg: 600,
                primaryBank: .bancaTransilvania
            )
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(UserProfile.self, from: data)
        #expect(decoded == original)
    }
}
