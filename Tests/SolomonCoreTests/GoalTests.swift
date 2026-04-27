import Testing
import Foundation
@testable import SolomonCore

@Suite struct GoalTests {

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        var c = DateComponents()
        c.year = y; c.month = m; c.day = d
        return Calendar.gregorianRO.date(from: c) ?? Date()
    }

    @Test func progressFractionIsSavedOverTarget() {
        let g = Goal(kind: .vacation, destination: "Grecia",
                     amountTarget: 4_500, amountSaved: 800,
                     deadline: date(2026, 7, 15))
        #expect(abs(g.progressFraction - (800.0 / 4500.0)) < 0.0001)
    }

    @Test func amountRemainingNeverGoesNegative() {
        let g = Goal(kind: .vacation, amountTarget: 4_500, amountSaved: 5_000,
                     deadline: date(2026, 7, 15))
        #expect(g.amountRemaining == 0)
        #expect(g.isReached)
    }

    @Test func amountRemainingMatchesTargetMinusSaved() {
        let g = Goal(kind: .vacation, amountTarget: 4_500, amountSaved: 800,
                     deadline: date(2026, 7, 15))
        #expect(g.amountRemaining == 3_700)
        #expect(!g.isReached)
    }

    @Test func everyGoalKindHasDisplayName() {
        for k in GoalKind.allCases {
            #expect(!k.displayNameRO.isEmpty)
        }
    }

    @Test func everyFeasibilityHasDisplayName() {
        for f in GoalFeasibility.allCases {
            #expect(!f.displayNameRO.isEmpty)
        }
    }

    @Test func codableRoundTripPreservesEverything() throws {
        let original = Goal(
            kind: .vacation,
            destination: "Grecia",
            amountTarget: 4_500,
            amountSaved: 800,
            deadline: date(2026, 7, 15)
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(Goal.self, from: data)
        #expect(decoded == original)
    }
}
