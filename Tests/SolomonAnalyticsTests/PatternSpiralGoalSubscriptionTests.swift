import Testing
import Foundation
@testable import SolomonAnalytics
import SolomonCore

// MARK: - Helpers

private let cal: Calendar = .gregorianRO
private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
    var c = DateComponents(); c.year = y; c.month = m; c.day = d
    return cal.date(from: c) ?? Date()
}
private func tx(_ a: Int, _ dir: FlowDirection,
                _ cat: TransactionCategory, on d: Date,
                merchant: String? = nil) -> Transaction {
    Transaction(date: d, amount: Money(a), direction: dir,
                category: cat, merchant: merchant, source: .csvImport)
}

// MARK: - PatternDetector

@Suite struct PatternDetectorTests {

    @Test func topCategoriesAreSortedByTotal() {
        let txs: [Transaction] = [
            tx(1_500, .outgoing, .rentMortgage, on: date(2026, 4, 1), merchant: "Landlord"),
            tx(800,   .outgoing, .foodGrocery,  on: date(2026, 4, 5), merchant: "Lidl"),
            tx(400,   .outgoing, .foodDelivery, on: date(2026, 4, 10), merchant: "Glovo"),
            tx(280,   .outgoing, .foodDelivery, on: date(2026, 4, 13), merchant: "Glovo"),
            tx(120,   .outgoing, .foodDelivery, on: date(2026, 4, 17), merchant: "Wolt")
        ]
        let report = PatternDetector().detect(transactions: txs, windowDays: 30, referenceDate: date(2026, 4, 25))
        #expect(report.topCategories.first?.category == .rentMortgage)
        #expect(report.topCategories.contains { $0.category == .foodDelivery })
        let foodDelivery = report.topCategories.first { $0.category == .foodDelivery }!
        #expect(foodDelivery.dominantMerchant == "Glovo")
        #expect(foodDelivery.transactionCount == 3)
    }

    @Test func weekendSpikeDetectsSignificantRatio() {
        // Generăm 90 zile cu cheltuieli mai mari în weekend.
        var txs: [Transaction] = []
        for offset in 0..<60 {
            let d = cal.date(byAdding: .day, value: -offset, to: date(2026, 4, 25))!
            let weekday = cal.component(.weekday, from: d)
            let amount = (weekday == 1 || weekday == 7) ? 200 : 50
            txs.append(tx(amount, .outgoing, .foodDining, on: d))
        }
        let report = PatternDetector().detect(transactions: txs, windowDays: 60, referenceDate: date(2026, 4, 25))
        #expect(report.weekendSpike.isSignificant)
        #expect(report.weekendSpike.ratio > 1.8)
    }

    @Test func temporalClusterDetectsConcentratedDay() {
        // 6 din 7 tranzacții vinerea (zi 6).
        var txs: [Transaction] = []
        // Friday tranzacții (mai 2026: 1, 8, 15, 22, 29 sunt vineri)
        for d in [date(2026, 4, 3), date(2026, 4, 10), date(2026, 4, 17), date(2026, 4, 24)] {
            txs.append(tx(50, .outgoing, .foodDelivery, on: d, merchant: "Glovo"))
        }
        for d in [date(2026, 4, 5), date(2026, 4, 12)] {
            txs.append(tx(40, .outgoing, .foodDelivery, on: d, merchant: "Glovo"))
        }
        let report = PatternDetector().detect(transactions: txs, windowDays: 30, referenceDate: date(2026, 4, 25))
        let foodCluster = report.temporalClusters.first { $0.category == .foodDelivery }
        #expect(foodCluster != nil)
        #expect(foodCluster?.dominantWeekday == 6)
    }

    @Test func outliersFlagTransactions5xAboveAverage() {
        var txs: [Transaction] = []
        // 89 zile × 50 RON/zi = 4450 total
        for offset in 0..<89 {
            let d = cal.date(byAdding: .day, value: -offset, to: date(2026, 4, 25))!
            txs.append(tx(50, .outgoing, .foodGrocery, on: d))
        }
        // Outlier: 1850 într-o singură zi (Categorie shopping).
        txs.append(tx(1_850, .outgoing, .shoppingOnline, on: date(2026, 3, 12), merchant: "eMAG"))
        let report = PatternDetector().detect(transactions: txs, windowDays: 90, referenceDate: date(2026, 4, 25))
        #expect(!report.outliers.isEmpty)
        #expect(report.outliers.first?.amount == Money(1_850))
        #expect(report.outliers.first?.merchant == "eMAG")
    }

    @Test func frequencySpikeFlagsHotCategoryInLast7Days() {
        var txs: [Transaction] = []
        for d in [date(2026, 4, 19), date(2026, 4, 21), date(2026, 4, 23), date(2026, 4, 24)] {
            txs.append(tx(70, .outgoing, .foodDelivery, on: d, merchant: "Glovo"))
        }
        let report = PatternDetector().detect(transactions: txs, windowDays: 30, referenceDate: date(2026, 4, 25))
        #expect(report.frequencySpikes.contains { $0.category == .foodDelivery })
        let spike = report.frequencySpikes.first { $0.category == .foodDelivery }!
        #expect(spike.countLast7Days == 4)
        #expect(spike.amountLast7Days == 280)
    }
}

// MARK: - SpiralDetector

@Suite struct SpiralDetectorTests {

    @Test func zeroFactorsGivesScoreZero() {
        let report = SpiralDetector().detect(
            transactions: [], obligations: [],
            monthlyIncomeAvg: 4_500, monthlySpendingAvg: 3_500,
            monthlyBalanceHistory: [Money(800), Money(900), Money(1_000)]
        )
        #expect(report.score == 0)
        #expect(report.severity == .none)
        #expect(!report.requiresIntervention)
    }

    @Test func balanceDecliningFactorTriggers() {
        let history: [Money] = [820, 540, 230, -120].map { Money($0) }
        let report = SpiralDetector().detect(
            transactions: [], obligations: [],
            monthlyIncomeAvg: 4_500, monthlySpendingAvg: 3_500,
            monthlyBalanceHistory: history
        )
        #expect(report.factors.contains { $0.factor == .balanceDeclining })
    }

    @Test func bnplStackingTriggersWithTwoOrMoreBNPL() {
        let bnpls = [
            Obligation(name: "Mokka", amount: 240, dayOfMonth: 5, kind: .bnpl, confidence: .detected),
            Obligation(name: "TBI", amount: 180, dayOfMonth: 12, kind: .bnpl, confidence: .detected)
        ]
        let report = SpiralDetector().detect(
            transactions: [], obligations: bnpls,
            monthlyIncomeAvg: 4_500, monthlySpendingAvg: 3_000,
            monthlyBalanceHistory: [Money(500)]
        )
        #expect(report.factors.contains { $0.factor == .bnplStacking })
    }

    @Test func ifnIncomingTriggersAndCsalbRelevant() {
        let ifnTx = tx(2_500, .incoming, .loansIFN, on: date(2026, 4, 18), merchant: "Credius")
        let report = SpiralDetector().detect(
            transactions: [ifnTx], obligations: [],
            monthlyIncomeAvg: 4_500, monthlySpendingAvg: 3_500,
            monthlyBalanceHistory: [Money(800)],
            referenceDate: date(2026, 4, 25)
        )
        #expect(report.factors.contains { $0.factor == .ifnActive })
        #expect(report.csalbRelevant)
    }

    @Test func obligationsExceedIncomeTriggersWhenGapPositive() {
        // Income 4500, spending 3000, obligations 2000 → gap 500
        let obligations = [
            Obligation(name: "Chirie", amount: 1_500, dayOfMonth: 1, kind: .rentMortgage, confidence: .declared),
            Obligation(name: "Credit", amount: 500, dayOfMonth: 5, kind: .loanBank, confidence: .declared)
        ]
        let report = SpiralDetector().detect(
            transactions: [], obligations: obligations,
            monthlyIncomeAvg: 4_500, monthlySpendingAvg: 3_000,
            monthlyBalanceHistory: [Money(500)]
        )
        #expect(report.factors.contains { $0.factor == .obligationsExceedIncome })
    }

    @Test func criticalScenarioYieldsCriticalSeverity() {
        let history: [Money] = [820, 540, 230, -120].map { Money($0) }
        let bnpls = [
            Obligation(name: "Mokka", amount: 240, dayOfMonth: 5, kind: .bnpl, confidence: .detected),
            Obligation(name: "TBI",   amount: 180, dayOfMonth: 12, kind: .bnpl, confidence: .detected)
        ]
        let ifnTx = tx(2_500, .incoming, .loansIFN, on: date(2026, 4, 18), merchant: "Credius")
        let bigObligations = [
            Obligation(name: "Chirie", amount: 1_500, dayOfMonth: 1, kind: .rentMortgage, confidence: .declared),
            Obligation(name: "Credius", amount: 500, dayOfMonth: 18, kind: .loanIFN, confidence: .declared)
        ] + bnpls

        let report = SpiralDetector().detect(
            transactions: [ifnTx], obligations: bigObligations,
            monthlyIncomeAvg: 4_500, monthlySpendingAvg: 3_500,
            monthlyBalanceHistory: history,
            referenceDate: date(2026, 4, 25)
        )
        #expect(report.score >= 3)
        #expect(report.severity == .high || report.severity == .critical)
        #expect(report.requiresIntervention)
        #expect(report.csalbRelevant)
    }
}

// MARK: - GoalProgress

@Suite struct GoalProgressTests {

    @Test func vacationOnTrackWhenSavingPaceMatchesRequired() {
        let goal = Goal(
            kind: .vacation, destination: "Grecia",
            amountTarget: 4_500, amountSaved: 800,
            deadline: date(2026, 7, 15)
        )
        let report = GoalProgress().evaluate(
            goal: goal, monthlyCurrentSavingPace: 1_300,
            referenceDate: date(2026, 4, 15)
        )
        #expect(report.monthsRemaining == 3)
        #expect(report.feasibility == .easy || report.feasibility == .onTrack)
        #expect(report.currentPaceWillReach)
    }

    @Test func challengingButPossibleWhenPaceFiftyToNinetyFivePct() {
        let goal = Goal(
            kind: .vacation, amountTarget: 4_500, amountSaved: 800,
            deadline: date(2026, 7, 15)
        )
        // Required: ~1233 RON/lună; pace 800 ≈ 65% → challenging.
        let report = GoalProgress().evaluate(
            goal: goal, monthlyCurrentSavingPace: 800,
            referenceDate: date(2026, 4, 15)
        )
        #expect(report.feasibility == .challengingButPossible)
        #expect(!report.currentPaceWillReach)
        #expect(report.shortfallPerMonth != nil)
    }

    @Test func unrealisticWhenSavingsZero() {
        let goal = Goal(
            kind: .vacation, amountTarget: 4_500, amountSaved: 800,
            deadline: date(2026, 7, 15)
        )
        let report = GoalProgress().evaluate(
            goal: goal, monthlyCurrentSavingPace: 0,
            referenceDate: date(2026, 4, 15)
        )
        #expect(report.feasibility == .unrealistic)
        #expect(!report.currentPaceWillReach)
    }

    @Test func reachedGoalShowsZeroMonths() {
        let goal = Goal(
            kind: .emergencyFund, amountTarget: 5_000, amountSaved: 5_000,
            deadline: date(2026, 12, 31)
        )
        let report = GoalProgress().evaluate(
            goal: goal, monthlyCurrentSavingPace: 500,
            referenceDate: date(2026, 4, 15)
        )
        #expect(report.currentPaceWillReach)
        #expect(report.amountRemaining == 0)
        #expect(report.monthsRemainingAtCurrentPace == 0)
    }

    @Test func threeScenariosAlwaysReturned() {
        let goal = Goal(
            kind: .vacation, amountTarget: 4_500, amountSaved: 0,
            deadline: date(2026, 7, 15)
        )
        let report = GoalProgress().evaluate(
            goal: goal, monthlyCurrentSavingPace: 500,
            referenceDate: date(2026, 4, 15)
        )
        #expect(report.scenarios.count == 3)
        #expect(report.scenarios.contains { $0.id == "current_pace" })
        #expect(report.scenarios.contains { $0.id == "required_pace" })
        #expect(report.scenarios.contains { $0.id == "boost_50" })
    }
}

// MARK: - SubscriptionAuditor

@Suite struct SubscriptionAuditorTests {

    @Test func separatesGhostsFromActive() {
        let subs = [
            Subscription(name: "Spotify",  amountMonthly: 25, lastUsedDaysAgo: 2),
            Subscription(name: "Netflix",  amountMonthly: 40, lastUsedDaysAgo: 47),
            Subscription(name: "HBO Max",  amountMonthly: 35, lastUsedDaysAgo: 92),
            Subscription(name: "Calm",     amountMonthly: 29, lastUsedDaysAgo: 178)
        ]
        let report = SubscriptionAuditor().audit(subscriptions: subs)
        #expect(report.ghostCount == 3)
        #expect(report.activeSubscriptions.map(\.name) == ["Spotify"])
        #expect(report.monthlyRecoverable == 104)
        #expect(report.annualRecoverable == 1_248)
    }

    @Test func ghostsSortedByImpactThenStaleness() {
        let subs = [
            Subscription(name: "Calm",     amountMonthly: 29, lastUsedDaysAgo: 178),
            Subscription(name: "Netflix",  amountMonthly: 40, lastUsedDaysAgo: 47),
            Subscription(name: "Adobe",    amountMonthly: 250, lastUsedDaysAgo: 89)
        ]
        let report = SubscriptionAuditor().audit(subscriptions: subs)
        #expect(report.ghostSubscriptions.first?.name == "Adobe")
        #expect(report.ghostSubscriptions[1].name == "Netflix")
        #expect(report.ghostSubscriptions[2].name == "Calm")
    }

    @Test func emptyInputProducesEmptyReport() {
        let report = SubscriptionAuditor().audit(subscriptions: [])
        #expect(report.ghostCount == 0)
        #expect(report.monthlyRecoverable == 0)
        #expect(report.annualRecoverable == 0)
        #expect(report.activeSubscriptions.isEmpty)
    }

    @Test func annualKeptSumsCorrectly() {
        let subs = [
            Subscription(name: "Spotify", amountMonthly: 25, lastUsedDaysAgo: 5),
            Subscription(name: "Sală", amountMonthly: 150, lastUsedDaysAgo: 1)
        ]
        let report = SubscriptionAuditor().audit(subscriptions: subs)
        #expect(report.monthlyKeptTotal == 175)
        #expect(report.annualKeptTotal == 2_100)
    }
}
