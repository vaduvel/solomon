import Testing
import Foundation
@testable import SolomonMoments
import SolomonCore
import SolomonLLM

// MARK: - Shared helpers

private let cal = Calendar.gregorianRO

private func futureDate(days: Int = 3) -> Date {
    Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
}

private let testUser = MomentUser(name: "Andrei", addressing: .tu, ageRange: .range25to35)

// MARK: - WowMomentContext fixture

private func makeWowContext() -> WowMomentContext {
    WowMomentContext(
        user: testUser,
        analysisPeriodDays: 180,
        income: WowIncome(
            monthlyAvg: Money(5000),
            stability: .stable,
            lowestMonth: LowestMonth(amount: Money(4200), month: "februarie"),
            extraIncomeDetected: false
        ),
        spending: WowSpending(
            monthlyAvg: Money(3800),
            incomeConsumptionRatio: 0.76,
            monthlyBalanceTrend: .healthy,
            cardCreditUsed: false,
            overdraftUsedCount180d: 0
        ),
        outliers: [
            OutlierItem(
                rank: 1, type: .singleLargePurchase, category: .shoppingOnline,
                amount: Money(2000), date: Date(),
                contextPhrase: "laptop cumpărat în martie",
                contextComparison: "echivalent cu 2 luni de Netflix"
            )
        ],
        patterns: [],
        obligations: ObligationsBlock(
            monthlyTotalFixed: Money(1500),
            items: [ObligationSummaryItem(name: "Chirie", amount: Money(1200), dayOfMonth: 1)],
            obligationsToIncomeRatio: 0.30
        ),
        ghostSubscriptions: GhostSubscriptionsBlock(count: 2, monthlyTotal: Money(80), annualTotal: Money(960), items: []),
        positives: [
            PositiveItem(type: .noIFN, description: "Fără IFN în ultimele 6 luni", durationMonths: 6)
        ],
        goal: GoalBlock(declared: false),
        spiralRisk: SpiralBlock(score: 0, severity: .none, factors: []),
        nextActionSuggested: NextActionSuggestion(
            type: .cancelGhostSubscriptions,
            rationale: "Două abonamente neutilizate pot fi anulate",
            monthlySaving: Money(80)
        )
    )
}

// MARK: - CanIAffordContext fixture

private func makeCanIAffordContext(verdict: CanIAffordVerdict = .yes) -> CanIAffordContext {
    CanIAffordContext(
        user: testUser,
        query: CanIAffordQuery(
            rawText: "Pot să comand pizza?",
            amountRequested: Money(65),
            categoryInferred: .foodDelivery,
            merchantInferred: "Glovo"
        ),
        context: CanIAffordContextBlock(
            today: Date(),
            daysUntilPayday: 9,
            currentBalance: Money(800),
            obligationsRemainingThisPeriod: [],
            obligationsTotalRemaining: Money(0),
            availableAfterObligations: Money(800),
            availablePerDayAfter: Money(88),
            availablePerDayAfterPurchase: Money(81)
        ),
        decision: CanIAffordDecision(
            verdict: verdict,
            verdictReason: .comfortableMargin,
            mathVisible: "după pizza, ai 735 RON / 9 zile = 81 RON/zi",
            alternativeToSuggest: .none
        ),
        userHistoryContext: CanIAffordHistoryContext(
            thisCategoryThisMonth: Money(150),
            thisCategoryAvgMonthly: Money(180),
            isAboveAverageToday: false
        )
    )
}

// MARK: - PaydayContext fixture

private func makePaydayContext() -> PaydayContext {
    PaydayContext(
        user: testUser,
        salary: PaydaySalary(
            amountReceived: Money(5200),
            receivedDate: Date(),
            source: "Angajator",
            isHigherThanAverage: true,
            isLowerThanAverage: false
        ),
        autoAllocation: PaydayAllocation(
            obligationsReserved: [PaydayObligationReserve(name: "Chirie", amount: Money(1200), status: .rezervat)],
            subscriptionsReserved: [PaydaySubscriptionReserve(name: "Netflix", amount: Money(40))],
            obligationsTotal: Money(1200),
            subscriptionsTotal: Money(40),
            savingsAuto: PaydaySavingsAuto(enabled: false),
            availableToSpend: Money(3960),
            daysUntilNextPayday: 30,
            availablePerDay: Money(132)
        ),
        comparisons: PaydayComparisons(
            vsLastMonthAvailable: Money(3800),
            vsLastMonthDiff: Money(160),
            vsLastMonthDirection: .better
        ),
        categoryBudgetsSuggested: [
            CategoryBudgetSuggestion(category: .foodDelivery, amount: Money(200), basedOn: .average)
        ]
    )
}

// MARK: - UpcomingObligationContext fixture

private func makeUpcomingObligationContext(daysUntilDue: Int = 2) -> UpcomingObligationContext {
    UpcomingObligationContext(
        user: testUser,
        upcoming: UpcomingObligationItem(
            name: "Rată ING",
            amountEstimated: Money(450),
            dueDate: futureDate(days: daysUntilDue),
            daysUntilDue: daysUntilDue,
            amountEstimationConfidence: .high,
            basedOnHistory: "Ultimele 3 luni: 450 RON constant"
        ),
        context: UpcomingObligationCashContext(
            currentBalance: Money(900),
            afterPayment: Money(450),
            daysUntilNextPayday: 12,
            availablePerDayAfter: Money(37)
        ),
        assessment: UpcomingObligationAssessment(
            isAffordable: true,
            isTight: true,
            tone: .calm
        ),
        weekendWarning: WeekendWarning(
            isWeekendComing: false,
            weekendAvgSpend: Money(200),
            wouldCreateProblem: false
        )
    )
}

// MARK: - PatternAlertContext fixture

private func makePatternAlertContext() -> PatternAlertContext {
    PatternAlertContext(
        user: testUser,
        patternDetected: PatternDetected(
            category: .foodDelivery,
            merchantDominant: "Glovo",
            type: .weekendSpike,
            description: "Cheltuiești ~300 RON pe weekend pe delivery, dublu față de media săptămânii",
            amountPeriod: Money(1200),
            amountProjectedMonthly: Money(600),
            vsBudget: Money(200),
            vsBudgetPct: 50,
            temporalConcentration: TemporalConcentration(
                isTemporal: true,
                pattern: "70% din cheltuieli în weekend",
                interpretation: "Obicei weekend confirmat"
            )
        ),
        scenarios: [
            PatternScenario(
                scenarioId: .continueAsIs,
                description: "Continui ca acum",
                monthEndOutcome: "600 RON pe delivery în total",
                goalImpact: "Nu contribui la niciun obiectiv"
            ),
            PatternScenario(
                scenarioId: .skipOneWeek,
                description: "Sari un weekend",
                monthEndOutcome: "450 RON pe delivery",
                goalImpact: "Economisești 150 RON"
            )
        ],
        toneCalibration: .warmNoJudgment
    )
}

// MARK: - SubscriptionAuditContext fixture

private func makeSubscriptionAuditContext() -> SubscriptionAuditContext {
    SubscriptionAuditContext(
        user: testUser,
        ghostSubscriptions: [
            GhostSubscriptionDetail(
                name: "HBO Max",
                amountMonthly: Money(28),
                amountAnnual: Money(336),
                lastUsedDaysAgo: 45,
                cancellationDifficulty: .easy,
                cancellationStepsSummary: "Settings → Subscription → Cancel"
            ),
            GhostSubscriptionDetail(
                name: "Spotify Family",
                amountMonthly: Money(34),
                amountAnnual: Money(408),
                lastUsedDaysAgo: 60,
                cancellationDifficulty: .medium
            )
        ],
        totals: SubscriptionAuditTotals(
            monthlyRecoverable: Money(62),
            annualRecoverable: Money(744),
            contextComparison: "echivalent cu o vacanță de 3 zile în Bulgaria"
        ),
        activeSubscriptionsKept: ActiveSubscriptionsKept(
            count: 3,
            monthlyTotal: Money(90),
            examples: ["Netflix", "iCloud 200GB", "Revolut Premium"]
        )
    )
}

// MARK: - SpiralAlertContext fixture

private func makeSpiralAlertContext(score: Int = 3, severity: SpiralSeverity = .high) -> SpiralAlertContext {
    SpiralAlertContext(
        user: testUser,
        spiralScore: score,
        severity: severity,
        factorsDetected: [
            SpiralFactor(
                factor: .balanceDeclining,
                evidence: "Soldul a scăzut cu 15% lunar în ultimele 3 luni",
                values: [-15, -12, -18]
            )
        ],
        narrativeSummary: "Soldul tău scade constant. Cheltuielile depășesc veniturile.",
        interventionNeeded: true,
        csalbRelevant: false,
        recoveryPlan: RecoveryPlan(
            step1: RecoveryStep(
                action: "Anulează 2 abonamente neutilizate",
                monthlySaving: Money(62),
                complexity: .easy
            ),
            step2: RecoveryStep(
                action: "Reduce delivery la 150 RON/lună",
                monthlySaving: Money(150),
                complexity: .easy
            ),
            step3: RecoveryStep(
                action: "Negociază chiria sau caută opțiune mai ieftină",
                complexity: .hard
            )
        )
    )
}

// MARK: - WeeklySummaryContext fixture

private func makeWeeklySummaryContext() -> WeeklySummaryContext {
    let monday = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    let sunday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
    return WeeklySummaryContext(
        user: testUser,
        week: WeekRange(start: monday, end: sunday, weekNumber: 17),
        spending: WeeklySpendingBlock(
            total: Money(420),
            vsWeeklyAvg: Money(380),
            diffPct: 10,
            direction: .slightlyAbove
        ),
        highlights: [
            WeeklyHighlight(
                type: .biggestExpense,
                category: .foodGrocery,
                amount: Money(180),
                context: "Cumpărături Kaufland joi"
            ),
            WeeklyHighlight(
                type: .budgetKept,
                category: .foodDelivery,
                context: "Sub bugetul de delivery pentru a 2-a săptămână consecutivă"
            )
        ],
        nextWeekPreview: NextWeekPreview(
            obligationsDue: [
                UpcomingObligationRef(name: "Enel", amount: Money(120), day: "marți")
            ],
            eventsInCalendar: []
        ),
        smallWin: SmallWin(
            exists: true,
            description: "Ai economisat 30 RON față de săptămâna trecută pe delivery"
        )
    )
}

// MARK: - Suite: Individual builder tests

@Suite struct MomentBuildersTests {

    let mock = MockLLMProvider()

    // MARK: - WowMomentBuilder

    @Test func wowBuilderProducesCorrectMomentType() async throws {
        let builder = WowMomentBuilder()
        let output = try await builder.build(makeWowContext(), using: mock)
        #expect(output.momentType == .wowMoment)
    }

    @Test func wowBuilderProducesNonEmptyJSON() async throws {
        let builder = WowMomentBuilder()
        let output = try await builder.build(makeWowContext(), using: mock)
        #expect(!output.contextJSON.isEmpty)
    }

    @Test func wowBuilderJSONContainsMomentType() async throws {
        let builder = WowMomentBuilder()
        let output = try await builder.build(makeWowContext(), using: mock)
        #expect(output.contextJSON.contains("wow_moment"))
    }

    @Test func wowBuilderJSONIsValidJSON() async throws {
        let builder = WowMomentBuilder()
        let output = try await builder.build(makeWowContext(), using: mock)
        let data = output.contextJSON.data(using: .utf8)!
        let parsed = try? JSONSerialization.jsonObject(with: data)
        #expect(parsed != nil)
    }

    @Test func wowBuilderLLMResponseNotEmpty() async throws {
        let builder = WowMomentBuilder()
        let output = try await builder.build(makeWowContext(), using: mock)
        #expect(output.hasResponse)
    }

    @Test func wowBuilderCallsLLMOnce() async throws {
        let mock = MockLLMProvider()
        let builder = WowMomentBuilder()
        _ = try await builder.build(makeWowContext(), using: mock)
        #expect(mock.generateCallCount == 1)
    }

    @Test func wowBuilderSystemPromptContainsMomentName() async throws {
        let builder = WowMomentBuilder()
        _ = try await builder.build(makeWowContext(), using: mock)
        #expect(mock.lastSystemPrompt?.contains("wow moment") == true ||
                mock.lastSystemPrompt?.contains("Solomon") == true)
    }

    @Test func wowBuilderContextRoundTrips() throws {
        let ctx = makeWowContext()
        let coder = JSONContextBuilder()
        let roundTripped = try coder.roundTrip(ctx)
        #expect(roundTripped.user.name == ctx.user.name)
        #expect(roundTripped.income.monthlyAvg == ctx.income.monthlyAvg)
    }

    // MARK: - CanIAffordBuilder

    @Test func canIAffordBuilderProducesCorrectType() async throws {
        let builder = CanIAffordBuilder()
        let output = try await builder.build(makeCanIAffordContext(), using: mock)
        #expect(output.momentType == .canIAfford)
    }

    @Test func canIAffordBuilderJSONContainsVerdict() async throws {
        let builder = CanIAffordBuilder()
        let output = try await builder.build(makeCanIAffordContext(verdict: .yesWithCaution), using: mock)
        #expect(output.contextJSON.contains("yes_with_caution"))
    }

    @Test func canIAffordBuilderJSONIsValidJSON() async throws {
        let builder = CanIAffordBuilder()
        let output = try await builder.build(makeCanIAffordContext(), using: mock)
        let data = output.contextJSON.data(using: .utf8)!
        #expect((try? JSONSerialization.jsonObject(with: data)) != nil)
    }

    @Test func canIAffordBuilderHasLLMResponse() async throws {
        let builder = CanIAffordBuilder()
        let output = try await builder.build(makeCanIAffordContext(), using: mock)
        #expect(output.hasResponse)
    }

    // MARK: - PaydayMagicBuilder

    @Test func paydayBuilderProducesCorrectType() async throws {
        let builder = PaydayMagicBuilder()
        let output = try await builder.build(makePaydayContext(), using: mock)
        #expect(output.momentType == .payday)
    }

    @Test func paydayBuilderJSONContainsSalary() async throws {
        let builder = PaydayMagicBuilder()
        let output = try await builder.build(makePaydayContext(), using: mock)
        #expect(output.contextJSON.contains("salary"))
    }

    @Test func paydayBuilderHasLLMResponse() async throws {
        let builder = PaydayMagicBuilder()
        let output = try await builder.build(makePaydayContext(), using: mock)
        #expect(output.hasResponse)
    }

    // MARK: - UpcomingObligationBuilder

    @Test func upcomingBuilderProducesCorrectType() async throws {
        let builder = UpcomingObligationBuilder()
        let output = try await builder.build(makeUpcomingObligationContext(), using: mock)
        #expect(output.momentType == .upcomingObligation)
    }

    @Test func upcomingBuilderJSONContainsUpcoming() async throws {
        let builder = UpcomingObligationBuilder()
        let output = try await builder.build(makeUpcomingObligationContext(), using: mock)
        #expect(output.contextJSON.contains("upcoming"))
    }

    @Test func upcomingBuilderHasLLMResponse() async throws {
        let builder = UpcomingObligationBuilder()
        let output = try await builder.build(makeUpcomingObligationContext(), using: mock)
        #expect(output.hasResponse)
    }

    // MARK: - PatternAlertBuilder

    @Test func patternAlertBuilderProducesCorrectType() async throws {
        let builder = PatternAlertBuilder()
        let output = try await builder.build(makePatternAlertContext(), using: mock)
        #expect(output.momentType == .patternAlert)
    }

    @Test func patternAlertBuilderJSONContainsPattern() async throws {
        let builder = PatternAlertBuilder()
        let output = try await builder.build(makePatternAlertContext(), using: mock)
        #expect(output.contextJSON.contains("pattern_detected"))
    }

    @Test func patternAlertBuilderHasLLMResponse() async throws {
        let builder = PatternAlertBuilder()
        let output = try await builder.build(makePatternAlertContext(), using: mock)
        #expect(output.hasResponse)
    }

    // MARK: - SubscriptionAuditBuilder

    @Test func subscriptionAuditBuilderProducesCorrectType() async throws {
        let builder = SubscriptionAuditBuilder()
        let output = try await builder.build(makeSubscriptionAuditContext(), using: mock)
        #expect(output.momentType == .subscriptionAudit)
    }

    @Test func subscriptionAuditBuilderJSONContainsGhosts() async throws {
        let builder = SubscriptionAuditBuilder()
        let output = try await builder.build(makeSubscriptionAuditContext(), using: mock)
        #expect(output.contextJSON.contains("ghost_subscriptions"))
    }

    @Test func subscriptionAuditBuilderHasLLMResponse() async throws {
        let builder = SubscriptionAuditBuilder()
        let output = try await builder.build(makeSubscriptionAuditContext(), using: mock)
        #expect(output.hasResponse)
    }

    // MARK: - SpiralAlertBuilder

    @Test func spiralAlertBuilderProducesCorrectType() async throws {
        let builder = SpiralAlertBuilder()
        let output = try await builder.build(makeSpiralAlertContext(), using: mock)
        #expect(output.momentType == .spiralAlert)
    }

    @Test func spiralAlertBuilderJSONContainsSpiralScore() async throws {
        let builder = SpiralAlertBuilder()
        let output = try await builder.build(makeSpiralAlertContext(score: 3), using: mock)
        #expect(output.contextJSON.contains("spiral_score"))
    }

    @Test func spiralAlertBuilderJSONContainsRecoveryPlan() async throws {
        let builder = SpiralAlertBuilder()
        let output = try await builder.build(makeSpiralAlertContext(), using: mock)
        #expect(output.contextJSON.contains("recovery_plan"))
    }

    @Test func spiralAlertBuilderHasLLMResponse() async throws {
        let builder = SpiralAlertBuilder()
        let output = try await builder.build(makeSpiralAlertContext(), using: mock)
        #expect(output.hasResponse)
    }

    // MARK: - WeeklySummaryBuilder

    @Test func weeklySummaryBuilderProducesCorrectType() async throws {
        let builder = WeeklySummaryBuilder()
        let output = try await builder.build(makeWeeklySummaryContext(), using: mock)
        #expect(output.momentType == .weeklySummary)
    }

    @Test func weeklySummaryBuilderJSONContainsSpending() async throws {
        let builder = WeeklySummaryBuilder()
        let output = try await builder.build(makeWeeklySummaryContext(), using: mock)
        #expect(output.contextJSON.contains("spending"))
    }

    @Test func weeklySummaryBuilderHasLLMResponse() async throws {
        let builder = WeeklySummaryBuilder()
        let output = try await builder.build(makeWeeklySummaryContext(), using: mock)
        #expect(output.hasResponse)
    }

    // MARK: - MomentOutput properties

    @Test func momentOutputWordCountCountsWords() async throws {
        let mock = MockLLMProvider()
        mock.forcedResponse = "unu doi trei patru cinci"
        let builder = WeeklySummaryBuilder()
        let output = try await builder.build(makeWeeklySummaryContext(), using: mock)
        #expect(output.wordCount == 5)
    }

    @Test func momentOutputIsWithinWordLimitForShortResponse() async throws {
        let mock = MockLLMProvider()
        mock.forcedResponse = "Răspuns scurt."
        let builder = CanIAffordBuilder()
        let output = try await builder.build(makeCanIAffordContext(), using: mock)
        #expect(output.isWithinWordLimit == true)
    }

    @Test func momentOutputGeneratedAtIsRecent() async throws {
        let before = Date()
        let builder = WowMomentBuilder()
        let output = try await builder.build(makeWowContext(), using: mock)
        let after = Date()
        #expect(output.generatedAt >= before)
        #expect(output.generatedAt <= after)
    }

    // MARK: - LLM error propagation

    @Test func builderPropagatesLLMError() async throws {
        let mock = MockLLMProvider()
        mock.shouldThrow = true
        let builder = WowMomentBuilder()
        do {
            _ = try await builder.build(makeWowContext(), using: mock)
            Issue.record("Should have thrown")
        } catch LLMError.generationFailed {
            // OK
        }
    }
}
