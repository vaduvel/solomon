import Testing
import Foundation
@testable import SolomonMoments
import SolomonCore

// MARK: - Helpers (reused from MomentBuildersTests fixtures — redefined here for isolation)

private let testUser = MomentUser(name: "Maria", addressing: .dumneavoastra)

private func futureDate(days: Int) -> Date {
    Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
}

private func makeCanIAfford() -> CanIAffordContext {
    CanIAffordContext(
        user: testUser,
        query: CanIAffordQuery(rawText: "pizza?", amountRequested: 50, categoryInferred: .foodDelivery),
        context: CanIAffordContextBlock(
            today: Date(), daysUntilPayday: 10, currentBalance: 600,
            obligationsRemainingThisPeriod: [], obligationsTotalRemaining: 0,
            availableAfterObligations: 600, availablePerDayAfter: 60, availablePerDayAfterPurchase: 55
        ),
        decision: CanIAffordDecision(verdict: .yes, verdictReason: .comfortableMargin, mathVisible: "ok"),
        userHistoryContext: CanIAffordHistoryContext(
            thisCategoryThisMonth: 100, thisCategoryAvgMonthly: 150, isAboveAverageToday: false
        )
    )
}

private func makeUpcomingObligation(daysUntilDue: Int) -> UpcomingObligationContext {
    UpcomingObligationContext(
        user: testUser,
        upcoming: UpcomingObligationItem(
            name: "Chirie", amountEstimated: 1200,
            dueDate: futureDate(days: daysUntilDue),
            daysUntilDue: daysUntilDue,
            amountEstimationConfidence: .high,
            basedOnHistory: "Constant 1200 RON"
        ),
        context: UpcomingObligationCashContext(
            currentBalance: 1800, afterPayment: 600, daysUntilNextPayday: 15, availablePerDayAfter: 40
        ),
        assessment: UpcomingObligationAssessment(isAffordable: true, isTight: false, tone: .calm),
        weekendWarning: WeekendWarning(isWeekendComing: false, weekendAvgSpend: 200, wouldCreateProblem: false)
    )
}

private func makeSpiralAlert(score: Int) -> SpiralAlertContext {
    SpiralAlertContext(
        user: testUser,
        spiralScore: score,
        severity: score >= 3 ? .high : .low,
        factorsDetected: [SpiralFactor(factor: .balanceDeclining, evidence: "scade")],
        narrativeSummary: "Stres financiar",
        interventionNeeded: score >= 3,
        csalbRelevant: false,
        recoveryPlan: RecoveryPlan(
            step1: RecoveryStep(action: "Anulează abonamente", complexity: .easy),
            step2: RecoveryStep(action: "Reduce delivery", complexity: .easy),
            step3: RecoveryStep(action: "Negociază chiria", complexity: .hard)
        )
    )
}

private func makePayday() -> PaydayContext {
    PaydayContext(
        user: testUser,
        salary: PaydaySalary(amountReceived: 5000, receivedDate: Date(), source: "Angajator",
                             isHigherThanAverage: false, isLowerThanAverage: false),
        autoAllocation: PaydayAllocation(
            obligationsReserved: [], subscriptionsReserved: [],
            obligationsTotal: 1500, subscriptionsTotal: 50,
            savingsAuto: PaydaySavingsAuto(enabled: false),
            availableToSpend: 3450, daysUntilNextPayday: 30, availablePerDay: 115
        ),
        comparisons: PaydayComparisons(vsLastMonthAvailable: 3400, vsLastMonthDiff: 50, vsLastMonthDirection: .better),
        categoryBudgetsSuggested: []
    )
}

private func makePatternAlert() -> PatternAlertContext {
    PatternAlertContext(
        user: testUser,
        patternDetected: PatternDetected(
            category: .foodDelivery, type: .weekendSpike,
            description: "Weekend spike delivery",
            amountPeriod: 800, amountProjectedMonthly: 400,
            vsBudget: 150, vsBudgetPct: 37,
            temporalConcentration: TemporalConcentration(isTemporal: true, pattern: "weekend", interpretation: "obicei")
        ),
        scenarios: []
    )
}

private func makeSubscriptionAudit() -> SubscriptionAuditContext {
    SubscriptionAuditContext(
        user: testUser,
        ghostSubscriptions: [
            GhostSubscriptionDetail(name: "HBO Max", amountMonthly: 28, amountAnnual: 336,
                                    lastUsedDaysAgo: 45, cancellationDifficulty: .easy)
        ],
        totals: SubscriptionAuditTotals(monthlyRecoverable: 28, annualRecoverable: 336,
                                        contextComparison: "o cină bună"),
        activeSubscriptionsKept: ActiveSubscriptionsKept(count: 2, monthlyTotal: 62, examples: ["Netflix"])
    )
}

private func makeWeeklySummary() -> WeeklySummaryContext {
    WeeklySummaryContext(
        user: testUser,
        week: WeekRange(start: Date(), end: Date(), weekNumber: 17),
        spending: WeeklySpendingBlock(total: 400, vsWeeklyAvg: 380, diffPct: 5, direction: .slightlyAbove),
        highlights: [WeeklyHighlight(type: .budgetKept, context: "sub buget pe delivery")],
        nextWeekPreview: NextWeekPreview(obligationsDue: [], eventsInCalendar: []),
        smallWin: SmallWin(exists: false)
    )
}

private func makeWowMoment() -> WowMomentContext {
    WowMomentContext(
        user: testUser,
        income: WowIncome(monthlyAvg: 5000, stability: .stable,
                          lowestMonth: LowestMonth(amount: 4000, month: "ianuarie"),
                          extraIncomeDetected: false),
        spending: WowSpending(monthlyAvg: 3800, incomeConsumptionRatio: 0.76,
                              monthlyBalanceTrend: .healthy, cardCreditUsed: false, overdraftUsedCount180d: 0),
        outliers: [],
        patterns: [],
        obligations: ObligationsBlock(monthlyTotalFixed: 1200, items: [], obligationsToIncomeRatio: 0.24),
        ghostSubscriptions: GhostSubscriptionsBlock(count: 0, monthlyTotal: 0, annualTotal: 0, items: []),
        positives: [],
        goal: GoalBlock(declared: false),
        spiralRisk: SpiralBlock(score: 0, severity: .none, factors: []),
        nextActionSuggested: NextActionSuggestion(type: .noActionNeeded, rationale: "totul ok")
    )
}

// MARK: - Tests

@Suite struct MomentOrchestratorTests {

    let mock = MockLLMProvider()
    let orchestrator = MomentOrchestrator()

    // MARK: - Priority: SpiralAlert wins all

    @Test func spiralAlertScoreGte2HasHighestPriority() async throws {
        let candidates = MomentCandidates(
            wowMoment: makeWowMoment(),
            canIAfford: makeCanIAfford(),
            payday: makePayday(),
            upcomingObligation: makeUpcomingObligation(daysUntilDue: 1),
            patternAlert: makePatternAlert(),
            subscriptionAudit: makeSubscriptionAudit(),
            spiralAlert: makeSpiralAlert(score: 3),
            weeklySummary: makeWeeklySummary()
        )
        let output = try await orchestrator.generate(from: candidates, using: mock)
        #expect(output.momentType == .spiralAlert)
    }

    @Test func spiralAlertScore1IsNotSelected() {
        let candidates = MomentCandidates(
            spiralAlert: makeSpiralAlert(score: 1),
            weeklySummary: makeWeeklySummary()
        )
        let selected = orchestrator.selectedType(from: candidates)
        // spiralScore 1 < 2 → nu e selectat spiralAlert
        #expect(selected == .weeklySummary)
    }

    // MARK: - Priority: CanIAfford over upcomingObligation

    @Test func canIAffordBeatsUpcomingObligation() {
        let candidates = MomentCandidates(
            canIAfford: makeCanIAfford(),
            upcomingObligation: makeUpcomingObligation(daysUntilDue: 1)
        )
        let selected = orchestrator.selectedType(from: candidates)
        #expect(selected == .canIAfford)
    }

    // MARK: - Priority: UpcomingObligation (daysUntilDue <= 3)

    @Test func upcomingObligationWithin3DaysIsSelected() {
        let candidates = MomentCandidates(
            payday: makePayday(),
            upcomingObligation: makeUpcomingObligation(daysUntilDue: 3)
        )
        let selected = orchestrator.selectedType(from: candidates)
        #expect(selected == .upcomingObligation)
    }

    @Test func upcomingObligationAfter3DaysIsNotSelected() {
        let candidates = MomentCandidates(
            payday: makePayday(),
            upcomingObligation: makeUpcomingObligation(daysUntilDue: 4)
        )
        let selected = orchestrator.selectedType(from: candidates)
        // 4 zile → nu e urgent → payday câștigă
        #expect(selected == .payday)
    }

    // MARK: - Priority: Payday

    @Test func paydayBeatsPatternAlert() {
        let candidates = MomentCandidates(
            payday: makePayday(),
            patternAlert: makePatternAlert()
        )
        let selected = orchestrator.selectedType(from: candidates)
        #expect(selected == .payday)
    }

    // MARK: - Priority: PatternAlert over subscriptionAudit

    @Test func patternAlertBeatsSubscriptionAudit() {
        let candidates = MomentCandidates(
            patternAlert: makePatternAlert(),
            subscriptionAudit: makeSubscriptionAudit()
        )
        let selected = orchestrator.selectedType(from: candidates)
        #expect(selected == .patternAlert)
    }

    // MARK: - Priority: SubscriptionAudit over weeklySummary

    @Test func subscriptionAuditBeatsWeeklySummary() {
        let candidates = MomentCandidates(
            subscriptionAudit: makeSubscriptionAudit(),
            weeklySummary: makeWeeklySummary()
        )
        let selected = orchestrator.selectedType(from: candidates)
        #expect(selected == .subscriptionAudit)
    }

    // MARK: - Priority: WeeklySummary over wowMoment

    @Test func weeklySummaryBeatsWowMoment() {
        let candidates = MomentCandidates(
            wowMoment: makeWowMoment(),
            weeklySummary: makeWeeklySummary()
        )
        let selected = orchestrator.selectedType(from: candidates)
        #expect(selected == .weeklySummary)
    }

    // MARK: - WowMoment as fallback

    @Test func wowMomentSelectedWhenAloneAvailable() {
        let candidates = MomentCandidates(wowMoment: makeWowMoment())
        let selected = orchestrator.selectedType(from: candidates)
        #expect(selected == .wowMoment)
    }

    // MARK: - Empty candidates

    @Test func noCandidatesSelectedTypeIsNil() {
        let candidates = MomentCandidates()
        let selected = orchestrator.selectedType(from: candidates)
        #expect(selected == nil)
    }

    @Test func noCandidatesThrowsNoCandidatesAvailable() async throws {
        let candidates = MomentCandidates()
        do {
            _ = try await orchestrator.generate(from: candidates, using: mock)
            Issue.record("Should have thrown")
        } catch OrchestratorError.noCandidatesAvailable {
            // OK
        }
    }

    // MARK: - hasAnyCandidate

    @Test func hasAnyCandidateFalseForEmpty() {
        #expect(MomentCandidates().hasAnyCandidate == false)
    }

    @Test func hasAnyCandidateTrueWithOneContext() {
        let c = MomentCandidates(weeklySummary: makeWeeklySummary())
        #expect(c.hasAnyCandidate == true)
    }

    // MARK: - LLM error bubbles through orchestrator

    @Test func orchestratorPropagatesLLMError() async throws {
        let mock = MockLLMProvider()
        mock.shouldThrow = true
        let candidates = MomentCandidates(weeklySummary: makeWeeklySummary())
        do {
            _ = try await orchestrator.generate(from: candidates, using: mock)
            Issue.record("Should have thrown")
        } catch OrchestratorError.buildFailed(let type, _) {
            #expect(type == .weeklySummary)
        }
    }

    // MARK: - Full pipeline for each moment type

    @Test func orchestratorGeneratesSpiralAlert() async throws {
        let candidates = MomentCandidates(spiralAlert: makeSpiralAlert(score: 2))
        let output = try await orchestrator.generate(from: candidates, using: mock)
        #expect(output.momentType == .spiralAlert)
    }

    @Test func orchestratorGeneratesCanIAfford() async throws {
        let candidates = MomentCandidates(canIAfford: makeCanIAfford())
        let output = try await orchestrator.generate(from: candidates, using: mock)
        #expect(output.momentType == .canIAfford)
    }

    @Test func orchestratorGeneratesPayday() async throws {
        let candidates = MomentCandidates(payday: makePayday())
        let output = try await orchestrator.generate(from: candidates, using: mock)
        #expect(output.momentType == .payday)
    }

    @Test func orchestratorGeneratesPatternAlert() async throws {
        let candidates = MomentCandidates(patternAlert: makePatternAlert())
        let output = try await orchestrator.generate(from: candidates, using: mock)
        #expect(output.momentType == .patternAlert)
    }

    @Test func orchestratorGeneratesSubscriptionAudit() async throws {
        let candidates = MomentCandidates(subscriptionAudit: makeSubscriptionAudit())
        let output = try await orchestrator.generate(from: candidates, using: mock)
        #expect(output.momentType == .subscriptionAudit)
    }

    @Test func orchestratorGeneratesWeeklySummary() async throws {
        let candidates = MomentCandidates(weeklySummary: makeWeeklySummary())
        let output = try await orchestrator.generate(from: candidates, using: mock)
        #expect(output.momentType == .weeklySummary)
    }

    @Test func orchestratorGeneratesWowMoment() async throws {
        let candidates = MomentCandidates(wowMoment: makeWowMoment())
        let output = try await orchestrator.generate(from: candidates, using: mock)
        #expect(output.momentType == .wowMoment)
    }

    @Test func orchestratorGeneratesUpcomingObligation() async throws {
        let candidates = MomentCandidates(upcomingObligation: makeUpcomingObligation(daysUntilDue: 2))
        let output = try await orchestrator.generate(from: candidates, using: mock)
        #expect(output.momentType == .upcomingObligation)
    }
}
