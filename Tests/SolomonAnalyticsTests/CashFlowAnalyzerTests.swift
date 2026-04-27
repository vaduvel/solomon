import Testing
import Foundation
@testable import SolomonAnalytics
import SolomonCore

@Suite struct CashFlowAnalyzerTests {

    // MARK: - Helpers

    private static let calendar: Calendar = .gregorianRO

    private static func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        var c = DateComponents()
        c.year = y; c.month = m; c.day = d
        return calendar.date(from: c) ?? Date()
    }

    private static func tx(
        _ amount: Int,
        _ direction: FlowDirection,
        _ category: TransactionCategory = .unknown,
        on date: Date,
        merchant: String? = nil
    ) -> Transaction {
        Transaction(
            date: date,
            amount: Money(amount),
            direction: direction,
            category: category,
            merchant: merchant,
            source: .csvImport
        )
    }

    // MARK: - Tests

    @Test func emptyTransactionsReturnsZeroes() {
        let analysis = CashFlowAnalyzer().analyze(
            transactions: [],
            windowDays: 180,
            referenceDate: Self.date(2026, 4, 25)
        )
        #expect(analysis.analyzedMonths == 0)
        #expect(analysis.monthlyIncomeAvg == 0)
        #expect(analysis.monthlySpendingAvg == 0)
        #expect(analysis.spendingByCategory.isEmpty)
    }

    @Test func threeMonthOfStableSalary() {
        let txs: [Transaction] = [
            // Salary 4500 each month, on the 15th.
            Self.tx(4_500, .incoming, .savings, on: Self.date(2026, 2, 15)),
            Self.tx(4_500, .incoming, .savings, on: Self.date(2026, 3, 15)),
            Self.tx(4_500, .incoming, .savings, on: Self.date(2026, 4, 15)),
            // Spending 4000 each month
            Self.tx(2_000, .outgoing, .rentMortgage, on: Self.date(2026, 2, 1)),
            Self.tx(2_000, .outgoing, .foodGrocery,  on: Self.date(2026, 2, 20)),
            Self.tx(2_000, .outgoing, .rentMortgage, on: Self.date(2026, 3, 1)),
            Self.tx(2_000, .outgoing, .foodGrocery,  on: Self.date(2026, 3, 20)),
            Self.tx(2_000, .outgoing, .rentMortgage, on: Self.date(2026, 4, 1)),
            Self.tx(2_000, .outgoing, .foodGrocery,  on: Self.date(2026, 4, 20))
        ]
        let analysis = CashFlowAnalyzer().analyze(
            transactions: txs, windowDays: 180,
            referenceDate: Self.date(2026, 4, 25)
        )
        #expect(analysis.analyzedMonths == 3)
        #expect(analysis.monthlyIncomeAvg == 4_500)
        #expect(analysis.monthlySpendingAvg == 4_000)
        #expect(analysis.monthlySavingsAvg == 500)
        #expect(abs(analysis.incomeConsumptionRatio - 0.888) < 0.01)
        #expect(analysis.breakEvenStatus == .aboveBreakEven)
        #expect(analysis.monthlyBalanceTrend == .barelyBreakeven)
    }

    @Test func categoryBreakdownIncludesAllOutgoings() {
        let txs: [Transaction] = [
            Self.tx(4_500, .incoming, on: Self.date(2026, 4, 15)),
            Self.tx(1_500, .outgoing, .rentMortgage, on: Self.date(2026, 4, 1)),
            Self.tx(800,   .outgoing, .foodGrocery,  on: Self.date(2026, 4, 5)),
            Self.tx(280,   .outgoing, .foodDelivery, on: Self.date(2026, 4, 10)),
            Self.tx(120,   .outgoing, .foodDelivery, on: Self.date(2026, 4, 12)),
            Self.tx(40,    .outgoing, .subscriptions, on: Self.date(2026, 4, 5))
        ]
        let analysis = CashFlowAnalyzer().analyze(
            transactions: txs, windowDays: 180,
            referenceDate: Self.date(2026, 4, 25)
        )
        #expect(analysis.spendingByCategory[.rentMortgage] == 1_500)
        #expect(analysis.spendingByCategory[.foodGrocery] == 800)
        #expect(analysis.spendingByCategory[.foodDelivery] == 400)
        #expect(analysis.spendingByCategory[.subscriptions] == 40)
        #expect(analysis.spendingByCategory.count == 4)
    }

    @Test func topSpendingCategoriesAreSorted() {
        let txs: [Transaction] = [
            Self.tx(1_500, .outgoing, .rentMortgage,  on: Self.date(2026, 4, 1)),
            Self.tx(800,   .outgoing, .foodGrocery,   on: Self.date(2026, 4, 5)),
            Self.tx(400,   .outgoing, .foodDelivery,  on: Self.date(2026, 4, 10)),
            Self.tx(200,   .outgoing, .transport,     on: Self.date(2026, 4, 12)),
            Self.tx(40,    .outgoing, .subscriptions, on: Self.date(2026, 4, 5))
        ]
        let analysis = CashFlowAnalyzer().analyze(
            transactions: txs, windowDays: 30,
            referenceDate: Self.date(2026, 4, 25)
        )
        let top = analysis.topSpendingCategories(3)
        #expect(top.count == 3)
        #expect(top[0].0 == .rentMortgage)
        #expect(top[1].0 == .foodGrocery)
        #expect(top[2].0 == .foodDelivery)
    }

    @Test func transactionsOutsideWindowAreIgnored() {
        let txs: [Transaction] = [
            // 2 ani în urmă — out
            Self.tx(10_000, .incoming, on: Self.date(2024, 4, 15)),
            Self.tx(5_000,  .outgoing, .shoppingOnline, on: Self.date(2024, 4, 16)),
            // Recent — in
            Self.tx(4_500, .incoming, on: Self.date(2026, 4, 15)),
            Self.tx(2_000, .outgoing, .rentMortgage, on: Self.date(2026, 4, 1))
        ]
        let analysis = CashFlowAnalyzer().analyze(
            transactions: txs, windowDays: 90,
            referenceDate: Self.date(2026, 4, 25)
        )
        #expect(analysis.analyzedMonths == 1)
        #expect(analysis.monthlyIncomeAvg == 4_500)
    }

    @Test func lowestAndHighestIncomeAreIdentified() {
        let txs: [Transaction] = [
            Self.tx(4_500, .incoming, on: Self.date(2026, 2, 15)),  // februarie
            Self.tx(4_200, .incoming, on: Self.date(2026, 3, 15)),  // martie - lowest
            Self.tx(4_800, .incoming, on: Self.date(2026, 4, 15))   // aprilie - highest
        ]
        let analysis = CashFlowAnalyzer().analyze(
            transactions: txs, windowDays: 180,
            referenceDate: Self.date(2026, 4, 25)
        )
        #expect(analysis.monthlyIncomeLowest?.amount == 4_200)
        #expect(analysis.monthlyIncomeLowest?.monthNameRO == "martie")
        #expect(analysis.monthlyIncomeHighest?.amount == 4_800)
        #expect(analysis.monthlyIncomeHighest?.monthNameRO == "aprilie")
    }

    @Test func deficitMonthsClassifyAsSlidingNegative() {
        let txs: [Transaction] = [
            Self.tx(4_500, .incoming, on: Self.date(2026, 2, 15)),
            Self.tx(4_900, .outgoing, .shoppingOnline, on: Self.date(2026, 2, 16)),

            Self.tx(4_500, .incoming, on: Self.date(2026, 3, 15)),
            Self.tx(5_100, .outgoing, .shoppingOnline, on: Self.date(2026, 3, 16)),

            Self.tx(4_500, .incoming, on: Self.date(2026, 4, 15)),
            Self.tx(5_300, .outgoing, .shoppingOnline, on: Self.date(2026, 4, 16))
        ]
        let analysis = CashFlowAnalyzer().analyze(
            transactions: txs, windowDays: 180,
            referenceDate: Self.date(2026, 4, 25)
        )
        // Deficit constant: trend negativ.
        #expect(analysis.monthlyBalanceTrend == .negative ||
                analysis.monthlyBalanceTrend == .slidingNegative)
        #expect(analysis.breakEvenStatus == .belowBreakEven ||
                analysis.breakEvenStatus == .wellBelowBreakEven)
    }

    @Test func velocityIsRoughlyMonthlySpendingDividedBy30() {
        let txs: [Transaction] = [
            Self.tx(4_500, .incoming, on: Self.date(2026, 4, 15)),
            Self.tx(3_000, .outgoing, .foodGrocery, on: Self.date(2026, 4, 5))
        ]
        let analysis = CashFlowAnalyzer().analyze(
            transactions: txs, windowDays: 30,
            referenceDate: Self.date(2026, 4, 25)
        )
        #expect(analysis.velocityRONPerDay == 100)
    }
}
