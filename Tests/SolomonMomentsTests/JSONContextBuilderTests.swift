import Testing
import Foundation
@testable import SolomonMoments
import SolomonCore

@Suite struct JSONContextBuilderTests {

    let builder = JSONContextBuilder()
    let user = MomentUser(name: "Alex", addressing: .tu)

    // MARK: - build() produces valid JSON

    @Test func buildProducesNonEmptyString() throws {
        let ctx = WeeklySummaryContext(
            user: user,
            week: WeekRange(start: Date(), end: Date(), weekNumber: 1),
            spending: WeeklySpendingBlock(total: 300, vsWeeklyAvg: 280, diffPct: 7, direction: .slightlyAbove),
            highlights: [],
            nextWeekPreview: NextWeekPreview(obligationsDue: [], eventsInCalendar: []),
            smallWin: SmallWin(exists: false)
        )
        let json = try builder.build(ctx)
        #expect(!json.isEmpty)
    }

    @Test func buildProducesValidJSONString() throws {
        let ctx = WeeklySummaryContext(
            user: user,
            week: WeekRange(start: Date(), end: Date(), weekNumber: 1),
            spending: WeeklySpendingBlock(total: 300, vsWeeklyAvg: 280, diffPct: 7, direction: .slightlyAbove),
            highlights: [],
            nextWeekPreview: NextWeekPreview(obligationsDue: [], eventsInCalendar: []),
            smallWin: SmallWin(exists: false)
        )
        let json = try builder.build(ctx)
        let data = json.data(using: .utf8)!
        let parsed = try? JSONSerialization.jsonObject(with: data)
        #expect(parsed != nil)
    }

    // MARK: - Snake_case keys

    @Test func buildUsesSnakeCaseForMomentType() throws {
        let ctx = CanIAffordContext(
            user: user,
            query: CanIAffordQuery(rawText: "pizza?", amountRequested: 50, categoryInferred: .foodDelivery),
            context: CanIAffordContextBlock(
                today: Date(), daysUntilPayday: 5, currentBalance: 500,
                obligationsRemainingThisPeriod: [], obligationsTotalRemaining: 0,
                availableAfterObligations: 500, availablePerDayAfter: 100, availablePerDayAfterPurchase: 90
            ),
            decision: CanIAffordDecision(verdict: .yes, verdictReason: .comfortableMargin, mathVisible: "ok"),
            userHistoryContext: CanIAffordHistoryContext(
                thisCategoryThisMonth: 50, thisCategoryAvgMonthly: 100, isAboveAverageToday: false
            )
        )
        let json = try builder.build(ctx)
        #expect(json.contains("moment_type"))
        #expect(!json.contains("momentType"))
    }

    @Test func buildUsesSnakeCaseForDaysUntilPayday() throws {
        let ctx = CanIAffordContext(
            user: user,
            query: CanIAffordQuery(rawText: "pizza?", amountRequested: 50, categoryInferred: .foodDelivery),
            context: CanIAffordContextBlock(
                today: Date(), daysUntilPayday: 7, currentBalance: 700,
                obligationsRemainingThisPeriod: [], obligationsTotalRemaining: 0,
                availableAfterObligations: 700, availablePerDayAfter: 100, availablePerDayAfterPurchase: 93
            ),
            decision: CanIAffordDecision(verdict: .yes, verdictReason: .comfortableMargin, mathVisible: "ok"),
            userHistoryContext: CanIAffordHistoryContext(
                thisCategoryThisMonth: 50, thisCategoryAvgMonthly: 100, isAboveAverageToday: false
            )
        )
        let json = try builder.build(ctx)
        #expect(json.contains("days_until_payday"))
    }

    // MARK: - Top-level keys

    @Test func topLevelKeysContainsMomentType() throws {
        let ctx = CanIAffordContext(
            user: user,
            query: CanIAffordQuery(rawText: "pizza?", amountRequested: 50, categoryInferred: .foodDelivery),
            context: CanIAffordContextBlock(
                today: Date(), daysUntilPayday: 5, currentBalance: 500,
                obligationsRemainingThisPeriod: [], obligationsTotalRemaining: 0,
                availableAfterObligations: 500, availablePerDayAfter: 100, availablePerDayAfterPurchase: 90
            ),
            decision: CanIAffordDecision(verdict: .yes, verdictReason: .comfortableMargin, mathVisible: "ok"),
            userHistoryContext: CanIAffordHistoryContext(
                thisCategoryThisMonth: 50, thisCategoryAvgMonthly: 100, isAboveAverageToday: false
            )
        )
        let keys = try builder.topLevelKeys(ctx)
        #expect(keys.contains("moment_type"))
        #expect(keys.contains("user"))
    }

    // MARK: - Round trip

    @Test func roundTripPreservesUserName() throws {
        let ctx = WeeklySummaryContext(
            user: MomentUser(name: "Mihai", addressing: .tu),
            week: WeekRange(start: Date(), end: Date(), weekNumber: 10),
            spending: WeeklySpendingBlock(total: 500, vsWeeklyAvg: 480, diffPct: 4, direction: .slightlyAbove),
            highlights: [],
            nextWeekPreview: NextWeekPreview(obligationsDue: [], eventsInCalendar: []),
            smallWin: SmallWin(exists: false)
        )
        let roundTripped = try builder.roundTrip(ctx)
        #expect(roundTripped.user.name == "Mihai")
    }

    @Test func roundTripPreservesSpendingTotal() throws {
        let ctx = WeeklySummaryContext(
            user: user,
            week: WeekRange(start: Date(), end: Date(), weekNumber: 5),
            spending: WeeklySpendingBlock(total: 777, vsWeeklyAvg: 700, diffPct: 11, direction: .above),
            highlights: [],
            nextWeekPreview: NextWeekPreview(obligationsDue: [], eventsInCalendar: []),
            smallWin: SmallWin(exists: false)
        )
        let roundTripped = try builder.roundTrip(ctx)
        #expect(roundTripped.spending.total == Money(777))
    }

    // MARK: - Estimated token count

    @Test func estimatedTokenCountIsPositive() throws {
        let ctx = WeeklySummaryContext(
            user: user,
            week: WeekRange(start: Date(), end: Date(), weekNumber: 1),
            spending: WeeklySpendingBlock(total: 300, vsWeeklyAvg: 280, diffPct: 7, direction: .slightlyAbove),
            highlights: [],
            nextWeekPreview: NextWeekPreview(obligationsDue: [], eventsInCalendar: []),
            smallWin: SmallWin(exists: false)
        )
        let tokens = try builder.estimatedTokenCount(ctx)
        #expect(tokens > 0)
    }

    // MARK: - buildPretty

    @Test func buildPrettyContainsNewlines() throws {
        let ctx = WeeklySummaryContext(
            user: user,
            week: WeekRange(start: Date(), end: Date(), weekNumber: 1),
            spending: WeeklySpendingBlock(total: 300, vsWeeklyAvg: 280, diffPct: 7, direction: .slightlyAbove),
            highlights: [],
            nextWeekPreview: NextWeekPreview(obligationsDue: [], eventsInCalendar: []),
            smallWin: SmallWin(exists: false)
        )
        let pretty = try builder.buildPretty(ctx)
        #expect(pretty.contains("\n"))
    }
}
