import Testing
import Foundation
@testable import SolomonCore

@Suite struct MoneyTests {

    @Test func arithmeticBehavesLikeInt() {
        let a: Money = 1_500
        let b: Money = 280
        #expect((a + b).amount == 1_780)
        #expect((a - b).amount == 1_220)
        #expect((b * 3).amount == 840)
        #expect((-a).amount == -1_500)
    }

    @Test func comparisonsAndSignChecks() {
        #expect(Money(0).isZero)
        #expect(Money(100).isPositive)
        #expect(Money(-50).isNegative)
        #expect(Money(100) > Money(50))
        #expect(Money(50) < Money(100))
    }

    @Test func fromMinorRoundsToNearestRON() {
        #expect(Money.fromMinor(8450).amount == 85)        // .50 rotunjește în sus
        #expect(Money.fromMinor(8449).amount == 84)        // .49 rotunjește în jos
        #expect(Money.fromMinor(0).amount == 0)
        #expect(Money.fromMinor(-8450).amount == -85)
    }

    @Test func fromRONRoundsBankerStyle() {
        #expect(Money.fromRON(84.4).amount == 84)
        #expect(Money.fromRON(84.5).amount == 84)         // banker rounding: even
        #expect(Money.fromRON(85.5).amount == 86)
    }

    @Test func codableRoundTripAsBareInteger() throws {
        let original = Money(1_247)
        let data = try JSONEncoder().encode(original)
        // Spec §6.1: sume ca integer JSON, nu ca obiect cu wrapper.
        #expect(String(data: data, encoding: .utf8) == "1247")
        let decoded = try JSONDecoder().decode(Money.self, from: data)
        #expect(decoded == original)
    }

    @Test func codableInsideStructPreservesShape() throws {
        struct Wrapper: Codable, Equatable { let monthly_avg: Money }
        let original = Wrapper(monthly_avg: 4500)
        let data = try JSONEncoder().encode(original)
        let json = String(data: data, encoding: .utf8) ?? ""
        #expect(json.contains("\"monthly_avg\":4500"))
        let decoded = try JSONDecoder().decode(Wrapper.self, from: data)
        #expect(decoded == original)
    }
}
