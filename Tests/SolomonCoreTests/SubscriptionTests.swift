import Testing
import Foundation
@testable import SolomonCore

@Suite struct SubscriptionTests {

    @Test func annualAmountIsTwelveMonthly() {
        let netflix = Subscription(name: "Netflix", amountMonthly: 40)
        #expect(netflix.amountAnnual == 480)
    }

    @Test func ghostThresholdIs30Days() {
        // Spec §4.2: > 30 zile fără utilizare = ghost.
        let active = Subscription(name: "Spotify", amountMonthly: 25, lastUsedDaysAgo: 5)
        let edge = Subscription(name: "Edge", amountMonthly: 30, lastUsedDaysAgo: 30)
        let ghost = Subscription(name: "Calm", amountMonthly: 29, lastUsedDaysAgo: 178)
        let unknown = Subscription(name: "Unknown", amountMonthly: 10, lastUsedDaysAgo: nil)

        #expect(!active.isGhost)
        #expect(!edge.isGhost, "Exact 30 zile = încă activ")
        #expect(ghost.isGhost)
        #expect(!unknown.isGhost, "Fără semnal = nu marcăm ghost")
    }

    @Test func ghostConfidenceScalesByDuration() {
        #expect(Subscription(name: "x", amountMonthly: 1, lastUsedDaysAgo: 5).ghostConfidence == .low)
        #expect(Subscription(name: "x", amountMonthly: 1, lastUsedDaysAgo: 47).ghostConfidence == .medium)
        #expect(Subscription(name: "x", amountMonthly: 1, lastUsedDaysAgo: 92).ghostConfidence == .high)
        #expect(Subscription(name: "x", amountMonthly: 1, lastUsedDaysAgo: 178).ghostConfidence == .veryHigh)
        #expect(Subscription(name: "x", amountMonthly: 1, lastUsedDaysAgo: nil).ghostConfidence == .low)
    }

    @Test func cancellationDifficultyHasRomanianLabels() {
        for d in CancellationDifficulty.allCases {
            #expect(!d.displayNameRO.isEmpty)
        }
    }
}
