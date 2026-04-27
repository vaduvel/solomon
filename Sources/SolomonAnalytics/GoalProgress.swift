import Foundation
import SolomonCore

public struct GoalScenario: Sendable, Hashable, Codable {
    public var id: String
    public var description: String
    public var monthlyContribution: Money
    public var monthsToReach: Int?
    public var willReach: Bool
}

public struct GoalProgressReport: Sendable, Hashable, Codable {
    public var goal: Goal
    public var monthsRemaining: Int
    public var monthsRemainingAtCurrentPace: Int?
    public var monthlyRequired: Money
    public var monthlyCurrentSavingPace: Money
    public var feasibility: GoalFeasibility
    public var currentPaceWillReach: Bool
    public var shortfallPerMonth: Money?
    public var scenarios: [GoalScenario]

    public var progressFraction: Double { goal.progressFraction }
    public var amountRemaining: Money { goal.amountRemaining }
}

/// Calculează progresul către obiective (spec §7.2 modul 6 + §6.2 secțiunea goal).
public struct GoalProgress: Sendable {

    public init() {}

    /// - Parameters:
    ///   - goal: obiectivul declarat.
    ///   - monthlyCurrentSavingPace: ritmul actual de economisire (din CashFlow `monthlySavingsAvg`).
    ///   - referenceDate: „azi".
    public func evaluate(
        goal: Goal,
        monthlyCurrentSavingPace: Money,
        referenceDate: Date = Date(),
        calendar: Calendar = .gregorianRO
    ) -> GoalProgressReport {
        let monthsRemaining = max(0, calendar.dateComponents([.month], from: referenceDate, to: goal.deadline).month ?? 0)

        let amountRemaining = goal.amountRemaining
        let monthlyRequired = monthsRemaining > 0
            ? Money(Int(ceil(Double(amountRemaining.amount) / Double(monthsRemaining))))
            : amountRemaining

        let willReach: Bool = {
            guard !goal.isReached else { return true }
            guard monthlyCurrentSavingPace.isPositive else { return false }
            return monthlyCurrentSavingPace >= monthlyRequired
        }()

        let monthsAtCurrentPace: Int? = {
            guard !goal.isReached else { return 0 }
            guard monthlyCurrentSavingPace.isPositive else { return nil }
            return Int(ceil(Double(amountRemaining.amount) / Double(monthlyCurrentSavingPace.amount)))
        }()

        let shortfall: Money? = willReach
            ? nil
            : (monthlyRequired - monthlyCurrentSavingPace).isPositive
                ? monthlyRequired - monthlyCurrentSavingPace
                : nil

        let feasibility = Self.classifyFeasibility(
            monthlyCurrentSavingPace: monthlyCurrentSavingPace,
            monthlyRequired: monthlyRequired
        )

        let scenarios: [GoalScenario] = [
            scenario(
                id: "current_pace",
                description: "ritmul actual",
                contribution: monthlyCurrentSavingPace,
                amountRemaining: amountRemaining,
                deadline: monthsRemaining
            ),
            scenario(
                id: "required_pace",
                description: "ritmul necesar pentru deadline",
                contribution: monthlyRequired,
                amountRemaining: amountRemaining,
                deadline: monthsRemaining
            ),
            scenario(
                id: "boost_50",
                description: "ritm boost cu 50% peste actual",
                contribution: Money(Int(Double(monthlyCurrentSavingPace.amount) * 1.5)),
                amountRemaining: amountRemaining,
                deadline: monthsRemaining
            )
        ]

        return GoalProgressReport(
            goal: goal,
            monthsRemaining: monthsRemaining,
            monthsRemainingAtCurrentPace: monthsAtCurrentPace,
            monthlyRequired: monthlyRequired,
            monthlyCurrentSavingPace: monthlyCurrentSavingPace,
            feasibility: feasibility,
            currentPaceWillReach: willReach,
            shortfallPerMonth: shortfall,
            scenarios: scenarios
        )
    }

    // MARK: - Helpers

    private func scenario(id: String, description: String, contribution: Money,
                          amountRemaining: Money, deadline: Int) -> GoalScenario {
        let months: Int? = contribution.isPositive
            ? Int(ceil(Double(amountRemaining.amount) / Double(contribution.amount)))
            : nil
        let willReach: Bool
        if let months {
            willReach = months <= deadline
        } else {
            willReach = false
        }
        return GoalScenario(
            id: id, description: description,
            monthlyContribution: contribution,
            monthsToReach: months, willReach: willReach
        )
    }

    static func classifyFeasibility(
        monthlyCurrentSavingPace: Money,
        monthlyRequired: Money
    ) -> GoalFeasibility {
        if monthlyRequired.isZero { return .easy }
        if !monthlyCurrentSavingPace.isPositive { return .unrealistic }
        let ratio = Double(monthlyCurrentSavingPace.amount) / Double(monthlyRequired.amount)
        switch ratio {
        case 1.20...: return .easy
        case 0.95..<1.20: return .onTrack
        case 0.50..<0.95: return .challengingButPossible
        default: return .unrealistic
        }
    }
}
