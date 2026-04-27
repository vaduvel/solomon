import Testing
import Foundation
@testable import SolomonCore

/// Verifică că structurile noastre se mapează 1:1 cu JSON-ul din spec §6.
/// Strategy: build complete contexts in Swift, round-trip prin coder configurat,
/// verify equality + snake_case keys în JSON output.

// MARK: - Helpers

private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
    var c = DateComponents()
    c.year = y; c.month = m; c.day = d
    return Calendar.gregorianRO.date(from: c) ?? Date()
}

private let danielUser = MomentUser(name: "Daniel", addressing: .tu, ageRange: .range25to35)
private let marianUser = MomentUser(name: "Marian", addressing: .tu)

// MARK: - Wow Moment

@Suite struct WowMomentContextTests {

    private func sampleContext() -> WowMomentContext {
        WowMomentContext(
            user: danielUser,
            analysisPeriodDays: 180,
            income: WowIncome(
                monthlyAvg: 4_500,
                stability: .stable,
                lowestMonth: LowestMonth(amount: 4_200, month: "februarie"),
                extraIncomeDetected: true,
                extraIncomeAvg: 600
            ),
            spending: WowSpending(
                monthlyAvg: 4_218,
                incomeConsumptionRatio: 0.94,
                monthlyBalanceTrend: .barelyBreakeven,
                cardCreditUsed: false,
                overdraftUsedCount180d: 0
            ),
            outliers: [
                OutlierItem(
                    rank: 1, type: .singleLargePurchase, category: .shoppingOnline,
                    merchant: "eMAG", amount: 1_850, date: date(2026, 3, 12),
                    contextPhrase: "44% din salariul lunar într-o singură zi",
                    contextComparison: "echivalent cu 5 luni de Netflix anual"
                ),
                OutlierItem(
                    rank: 2, type: .categoryConcentration, category: .foodDelivery,
                    merchant: "Glovo",
                    amountTotal180d: 7_480,
                    amountMonthlyAvg: 1_247,
                    contextPhrase: "media lunară 1.247 RON, 28% din salariu",
                    contextComparison: "echivalent cu o vacanță de 7 zile la munte"
                )
            ],
            patterns: [
                PatternItem(
                    type: .temporalClustering, category: .foodDelivery,
                    description: "67% din comenzi vinerea seara între 19:00-22:00",
                    interpretation: "pattern emotional-eating după săptămâna de muncă"
                ),
                PatternItem(
                    type: .weekendSpike,
                    description: "weekendurile sunt 2.3x mai scumpe ca zilele lucrătoare",
                    averageWeekendSpend: 480, averageWeekdaySpend: 210, ratio: 2.3
                )
            ],
            obligations: ObligationsBlock(
                monthlyTotalFixed: 2_235,
                items: [
                    ObligationSummaryItem(name: "Chirie", amount: 1_500, dayOfMonth: 1),
                    ObligationSummaryItem(name: "Internet Digi", amount: 65, dayOfMonth: 15),
                    ObligationSummaryItem(name: "Curent Enel", amount: 220, dayOfMonth: 28)
                ],
                obligationsToIncomeRatio: 0.50
            ),
            ghostSubscriptions: GhostSubscriptionsBlock(
                count: 3, monthlyTotal: 104, annualTotal: 1_248,
                items: [
                    GhostSubscriptionItem(name: "Netflix", amount: 40, lastUsedDaysAgo: 47, confidence: .high),
                    GhostSubscriptionItem(name: "App Calm", amount: 29, lastUsedDaysAgo: 178, confidence: .veryHigh),
                    GhostSubscriptionItem(name: "HBO Max", amount: 35, lastUsedDaysAgo: 92, confidence: .high)
                ]
            ),
            positives: [
                PositiveItem(
                    type: .noIFN,
                    description: "fără IFN-uri sau credite cu dobândă mare",
                    rarityContext: "doar 1 din 4 români poate spune asta"
                ),
                PositiveItem(
                    type: .noLatePayments, description: "plătești facturile la timp, fără penalități",
                    durationMonths: 6
                ),
                PositiveItem(
                    type: .rentToIncomeHealthy,
                    description: "chiria e 33% din venit, ratio sănătos",
                    ratio: 0.33
                )
            ],
            goal: GoalBlock(
                declared: true, type: .vacation, destination: "Grecia",
                amountTarget: 4_500, amountSaved: 800,
                deadline: date(2026, 7, 15),
                monthsRemaining: 3, monthlyRequired: 1_233,
                feasibility: .challengingButPossible,
                currentPaceWillReach: false, shortfallPerMonth: 433
            ),
            spiralRisk: SpiralBlock(score: 0, severity: .none, factors: []),
            nextActionSuggested: NextActionSuggestion(
                type: .cancelGhostSubscriptions,
                rationale: "instant_savings_no_lifestyle_impact",
                monthlySaving: 104, annualSaving: 1_248,
                goalProgressImpact: "8% din vacanța Grecia"
            )
        )
    }

    @Test func roundTripPreservesAllFields() throws {
        let original = sampleContext()
        let restored = try SolomonContextCoder.roundTrip(original)
        #expect(restored == original)
    }

    @Test func jsonUsesSnakeCaseKeys() throws {
        let json = try SolomonContextCoder.encodeAsJSONString(sampleContext())
        // Spec §6.2 — toate cheile trebuie snake_case.
        #expect(json.contains("\"moment_type\""))
        #expect(json.contains("\"analysis_period_days\""))
        #expect(json.contains("\"monthly_avg\""))
        #expect(json.contains("\"income_consumption_ratio\""))
        #expect(json.contains("\"ghost_subscriptions\""))
        #expect(json.contains("\"context_phrase\""))
        #expect(json.contains("\"current_pace_will_reach\""))
        #expect(json.contains("\"spiral_risk\""))
        #expect(json.contains("\"next_action_suggested\""))
        // Și nici un camelCase „accidental":
        #expect(!json.contains("\"momentType\""))
        #expect(!json.contains("\"monthlyAvg\""))
    }

    @Test func momentTypeFieldIsLiteralWowMoment() throws {
        let json = try SolomonContextCoder.encodeAsJSONString(sampleContext())
        #expect(json.contains("\"moment_type\":\"wow_moment\""))
    }

    @Test func moneyFieldsAreBareIntegers() throws {
        let json = try SolomonContextCoder.encodeAsJSONString(sampleContext())
        // Money trebuie să apară ca integer literal, nu obiect: spec §6.1.
        #expect(json.contains("\"monthly_avg\":4500"))
        #expect(json.contains("\"amount\":1500"))
    }
}

// MARK: - Can I Afford

@Suite struct CanIAffordContextTests {

    private func sample() -> CanIAffordContext {
        CanIAffordContext(
            user: marianUser,
            query: CanIAffordQuery(
                rawText: "pot să iau pizza de 80 lei diseară?",
                amountRequested: 80,
                categoryInferred: .foodDining
            ),
            context: CanIAffordContextBlock(
                today: date(2026, 4, 25),
                daysUntilPayday: 9, currentBalance: 2_160,
                obligationsRemainingThisPeriod: [
                    AffordObligationRef(name: "Chirie", amount: 1_500, dueDate: date(2026, 5, 1)),
                    AffordObligationRef(name: "Curent Enel", amount: 280, dueDate: date(2026, 4, 28))
                ],
                obligationsTotalRemaining: 1_780,
                availableAfterObligations: 380,
                availablePerDayAfter: 42,
                availablePerDayAfterPurchase: 33
            ),
            decision: CanIAffordDecision(
                verdict: .yesWithCaution,
                verdictReason: .tightButWorkable,
                mathVisible: "după pizza, ai 33 RON/zi pentru 9 zile",
                alternativeToSuggest: .waitTwoDaysAfterEnel
            ),
            userHistoryContext: CanIAffordHistoryContext(
                thisCategoryThisMonth: 340,
                thisCategoryAvgMonthly: 425,
                isAboveAverageToday: false
            )
        )
    }

    @Test func roundTrip() throws {
        let original = sample()
        let restored = try SolomonContextCoder.roundTrip(original)
        #expect(restored == original)
    }

    @Test func momentTypeIsCanIAfford() throws {
        let json = try SolomonContextCoder.encodeAsJSONString(sample())
        #expect(json.contains("\"moment_type\":\"can_i_afford\""))
        #expect(json.contains("\"verdict\":\"yes_with_caution\""))
        #expect(json.contains("\"alternative_to_suggest\":\"wait_2_days_until_after_enel\""))
    }
}

// MARK: - Payday

@Suite struct PaydayContextTests {

    private func sample() -> PaydayContext {
        PaydayContext(
            user: danielUser,
            salary: PaydaySalary(
                amountReceived: 4_500, receivedDate: date(2026, 4, 15),
                source: "Salariu", isHigherThanAverage: false, isLowerThanAverage: false
            ),
            autoAllocation: PaydayAllocation(
                obligationsReserved: [
                    PaydayObligationReserve(name: "Chirie", amount: 1_500, status: .rezervat),
                    PaydayObligationReserve(name: "Curent Enel (estimat)", amount: 280, status: .estimat)
                ],
                subscriptionsReserved: [
                    PaydaySubscriptionReserve(name: "Netflix", amount: 40),
                    PaydaySubscriptionReserve(name: "Spotify", amount: 25)
                ],
                obligationsTotal: 2_295,
                subscriptionsTotal: 129,
                savingsAuto: PaydaySavingsAuto(enabled: true, amount: 450, destination: "Fond Grecia"),
                availableToSpend: 1_626,
                daysUntilNextPayday: 30,
                availablePerDay: 54
            ),
            comparisons: PaydayComparisons(
                vsLastMonthAvailable: 1_480, vsLastMonthDiff: 146, vsLastMonthDirection: .better
            ),
            categoryBudgetsSuggested: [
                CategoryBudgetSuggestion(category: .foodGrocery, amount: 600, basedOn: .average),
                CategoryBudgetSuggestion(category: .foodDelivery, amount: 400, basedOn: .reducedTarget)
            ],
            warnings: [
                PaydayWarning(
                    type: .upcomingEvent,
                    description: "Nuntă pe 8 mai, ai notat ~700 RON",
                    impact: "scoate 700 RON din disponibilul de 1.626"
                )
            ]
        )
    }

    @Test func roundTrip() throws {
        let original = sample()
        let restored = try SolomonContextCoder.roundTrip(original)
        #expect(restored == original)
    }

    @Test func reserveStatusUsesRomanian() throws {
        let json = try SolomonContextCoder.encodeAsJSONString(sample())
        #expect(json.contains("\"status\":\"rezervat\""))
        #expect(json.contains("\"status\":\"estimat\""))
    }
}

// MARK: - Upcoming Obligation

@Suite struct UpcomingObligationContextTests {

    @Test func roundTrip() throws {
        let original = UpcomingObligationContext(
            user: marianUser,
            upcoming: UpcomingObligationItem(
                name: "Curent Enel", amountEstimated: 280,
                dueDate: date(2026, 4, 28), daysUntilDue: 3,
                amountEstimationConfidence: .high,
                basedOnHistory: "media ultimelor 3 luni"
            ),
            context: UpcomingObligationCashContext(
                currentBalance: 720, afterPayment: 440,
                daysUntilNextPayday: 6, availablePerDayAfter: 73
            ),
            assessment: UpcomingObligationAssessment(
                isAffordable: true, isTight: false, tone: .reassuring
            ),
            weekendWarning: WeekendWarning(
                isWeekendComing: true, weekendAvgSpend: 340, wouldCreateProblem: false
            )
        )
        let restored = try SolomonContextCoder.roundTrip(original)
        #expect(restored == original)
    }
}

// MARK: - Pattern Alert

@Suite struct PatternAlertContextTests {

    @Test func roundTripPreservesScenarios() throws {
        let original = PatternAlertContext(
            user: danielUser,
            patternDetected: PatternDetected(
                category: .foodDelivery, merchantDominant: "Glovo",
                type: .frequencySpike, description: "4 comenzi în 7 zile",
                amountPeriod: 287, amountProjectedMonthly: 1_230,
                vsBudget: 920, vsBudgetPct: 134,
                temporalConcentration: TemporalConcentration(
                    isTemporal: true, pattern: "miercuri-vineri seara",
                    interpretation: "post-work emotional eating"
                )
            ),
            scenarios: [
                PatternScenario(
                    scenarioId: .continueAsIs, description: "continui ritmul actual",
                    monthEndOutcome: "depășire 310 RON peste buget",
                    goalImpact: "vacanța întârzie cu o săptămână"
                ),
                PatternScenario(
                    scenarioId: .reduce2PerWeek, description: "rămâi la 2 comenzi/săptămână",
                    monthEndOutcome: "respecți bugetul", goalImpact: "vacanța rămâne pe drum"
                ),
                PatternScenario(
                    scenarioId: .skipOneWeek, description: "skip complet săptămâna asta",
                    monthEndOutcome: "economisești 380 RON", goalImpact: "+1 zi vacanță în plus"
                )
            ],
            toneCalibration: .warmNoJudgment
        )
        let restored = try SolomonContextCoder.roundTrip(original)
        #expect(restored == original)
        #expect(restored.scenarios.count == 3)
    }
}

// MARK: - Subscription Audit

@Suite struct SubscriptionAuditContextTests {

    @Test func roundTrip() throws {
        let original = SubscriptionAuditContext(
            user: marianUser,
            auditPeriodDays: 30,
            ghostSubscriptions: [
                GhostSubscriptionDetail(
                    name: "Netflix", amountMonthly: 40, amountAnnual: 480,
                    lastUsedDaysAgo: 47, cancellationDifficulty: .easy,
                    cancellationUrl: URL(string: "https://netflix.com/cancelplan"),
                    alternativeSuggestion: "HBO Max sau Prime Video"
                ),
                GhostSubscriptionDetail(
                    name: "Calm", amountMonthly: 29, amountAnnual: 348,
                    lastUsedDaysAgo: 178, cancellationDifficulty: .medium,
                    cancellationStepsSummary: "din App Store, Subscriptions"
                ),
                GhostSubscriptionDetail(
                    name: "Adobe Creative Cloud", amountMonthly: 250, amountAnnual: 3_000,
                    lastUsedDaysAgo: 89, cancellationDifficulty: .hard,
                    cancellationWarning: "are penalty pentru anulare anticipată"
                )
            ],
            totals: SubscriptionAuditTotals(
                monthlyRecoverable: 319, annualRecoverable: 3_828,
                contextComparison: "echivalent cu vacanța Grecia + buffer"
            ),
            activeSubscriptionsKept: ActiveSubscriptionsKept(
                count: 4, monthlyTotal: 285,
                examples: ["Spotify", "HBO Max", "Sală", "Asigurare casco"]
            )
        )
        let restored = try SolomonContextCoder.roundTrip(original)
        #expect(restored == original)
    }
}

// MARK: - Spiral Alert

@Suite struct SpiralAlertContextTests {

    @Test func roundTripWithCriticalSeverity() throws {
        let original = SpiralAlertContext(
            user: danielUser, spiralScore: 3, severity: .critical,
            factorsDetected: [
                SpiralFactor(
                    factor: .balanceDeclining,
                    evidence: "balance final de lună a scăzut 4 luni la rând",
                    values: [820, 540, 230, -120]
                ),
                SpiralFactor(
                    factor: .cardCreditIncreasing,
                    evidence: "datorie pe card credit a crescut de la 0 la 1.840 RON",
                    monthlyIncreaseAvg: 460
                ),
                SpiralFactor(
                    factor: .ifnActive,
                    evidence: "Credius incoming detected pe 18 aprilie",
                    amount: 2_500, estimatedTotalRepayment: 3_250
                ),
                SpiralFactor(
                    factor: .obligationsExceedIncome,
                    evidence: "obligații + cheltuieli medii > venit cu 380 RON/lună",
                    monthlyGap: 380
                )
            ],
            narrativeSummary: "spiral activ, IFN nou, obligații peste venit",
            interventionNeeded: true, csalbRelevant: true,
            recoveryPlan: RecoveryPlan(
                step1: RecoveryStep(action: "anulare ghost subscriptions", monthlySaving: 104, complexity: .easy),
                step2: RecoveryStep(action: "negociere refinanțare credit + IFN",
                                    potentialSaving: "200-400 RON/lună", complexity: .medium, tool: .csalb),
                step3: RecoveryStep(action: "reducere food_delivery cu 50%",
                                    monthlySaving: 600, complexity: .behavioral)
            )
        )
        let restored = try SolomonContextCoder.roundTrip(original)
        #expect(restored == original)
        #expect(restored.spiralScore == 3)
        #expect(restored.severity == .critical)
        #expect(restored.factorsDetected.count == 4)
    }

    @Test func severityIsComparable() {
        #expect(SpiralSeverity.none < .low)
        #expect(SpiralSeverity.medium < .high)
        #expect(SpiralSeverity.high < .critical)
    }
}

// MARK: - Weekly Summary

@Suite struct WeeklySummaryContextTests {

    @Test func roundTrip() throws {
        let original = WeeklySummaryContext(
            user: danielUser,
            week: WeekRange(start: date(2026, 4, 19), end: date(2026, 4, 25), weekNumber: 17),
            spending: WeeklySpendingBlock(
                total: 612, vsWeeklyAvg: 580, diffPct: 5, direction: .slightlyAbove
            ),
            highlights: [
                WeeklyHighlight(
                    type: .biggestExpense, category: .foodDelivery, amount: 187,
                    context: "3 comenzi Glovo, mai mult ca media"
                ),
                WeeklyHighlight(
                    type: .budgetKept, category: .transport, amount: 67,
                    context: "sub buget cu 30 RON"
                ),
                WeeklyHighlight(
                    type: .noIFNNoBNPLTemptation,
                    context: "săptămână curată, fără datorii noi"
                )
            ],
            nextWeekPreview: NextWeekPreview(
                obligationsDue: [UpcomingObligationRef(name: "Curent Enel", amount: 280, day: "marți")],
                eventsInCalendar: [CalendarEventRef(name: "Nuntă Andrei", estimatedCost: 700, date: "sâmbătă")]
            ),
            smallWin: SmallWin(exists: true, description: "ai redus delivery de la 4 la 3 comenzi/săpt")
        )
        let restored = try SolomonContextCoder.roundTrip(original)
        #expect(restored == original)
    }
}

// MARK: - Cross-cutting

@Suite struct MomentTypeMetadataTests {

    @Test func eightMomentTypesDefined() {
        #expect(MomentType.allCases.count == 8)
    }

    @Test func everyMomentHasReasonableMaxWords() {
        for type in MomentType.allCases {
            #expect(type.maxWords >= 50 && type.maxWords <= 300)
        }
    }

    @Test func wowMomentHasLargestBudget() {
        let wow = MomentType.wowMoment.maxWords
        for other in MomentType.allCases where other != .wowMoment {
            #expect(other.maxWords < wow)
        }
    }
}
