import Foundation
import SolomonCore

/// Calculează agregatele cash flow lunare folosite de Wow Moment, Payday și Pre-factură
/// (spec §7.2 modul 1).
///
/// Tot raționamentul matematic se face aici — LLM-ul nu calculează. Output-ul
/// `CashFlowAnalysis` are toate cifrele gata pentru context-ul JSON al momentelor.
public struct CashFlowAnalyzer: Sendable {

    public init() {}

    /// Analizează tranzacțiile dintr-o fereastră (default 180 zile spec §6.2).
    ///
    /// - Parameters:
    ///   - transactions: lista de tranzacții (incoming + outgoing).
    ///   - windowDays: numărul de zile retroactive de luat în calcul.
    ///   - referenceDate: „azi". Default: data curentă.
    ///   - calendar: calendarul folosit pentru bucketing (default RO).
    public func analyze(
        transactions: [Transaction],
        windowDays: Int = 180,
        referenceDate: Date = Date(),
        calendar: Calendar = .gregorianRO
    ) -> CashFlowAnalysis {
        guard let windowStart = calendar.date(byAdding: .day, value: -windowDays, to: referenceDate) else {
            return Self.empty(windowDays: windowDays)
        }

        let inWindow = transactions.filter { $0.date >= windowStart && $0.date <= referenceDate }
        guard !inWindow.isEmpty else {
            return Self.empty(windowDays: windowDays)
        }

        let monthlyBuckets = Self.groupByMonth(inWindow, calendar: calendar)
        let analyzedMonths = monthlyBuckets.count

        let incomeAmounts = monthlyBuckets.map { $0.income }
        let spendingAmounts = monthlyBuckets.map { $0.spending }

        let monthlyIncomeAvg = Self.averageMoney(incomeAmounts)
        let monthlySpendingAvg = Self.averageMoney(spendingAmounts)

        let lowestIncomeBucket = monthlyBuckets.min { $0.income < $1.income }
        let highestIncomeBucket = monthlyBuckets.max { $0.income < $1.income }

        let spendingByCategory = Self.aggregateByCategory(inWindow)

        let monthlySavingsAvg = monthlyIncomeAvg - monthlySpendingAvg
        let incomeConsumptionRatio = monthlyIncomeAvg.amount > 0
            ? Double(monthlySpendingAvg.amount) / Double(monthlyIncomeAvg.amount)
            : 0

        let velocityRONPerDay = Money(monthlySpendingAvg.amount / 30)
        let breakEvenStatus = Self.classifyBreakEven(income: monthlyIncomeAvg, spending: monthlySpendingAvg)
        let monthlyBalanceTrend = Self.classifyBalanceTrend(buckets: monthlyBuckets)

        return CashFlowAnalysis(
            windowDays: windowDays,
            analyzedMonths: analyzedMonths,
            monthlyIncomeAvg: monthlyIncomeAvg,
            monthlyIncomeLowest: lowestIncomeBucket.map { MonthlyAmount(amount: $0.income, key: $0.key) },
            monthlyIncomeHighest: highestIncomeBucket.map { MonthlyAmount(amount: $0.income, key: $0.key) },
            monthlySpendingAvg: monthlySpendingAvg,
            spendingByCategory: spendingByCategory,
            monthlyBalanceTrend: monthlyBalanceTrend,
            velocityRONPerDay: velocityRONPerDay,
            breakEvenStatus: breakEvenStatus,
            monthlySavingsAvg: monthlySavingsAvg,
            incomeConsumptionRatio: incomeConsumptionRatio
        )
    }

    // MARK: - Internals

    struct MonthlyBucket: Sendable {
        let key: MonthKey
        let income: Money
        let spending: Money

        var balance: Money { income - spending }
    }

    static func groupByMonth(_ transactions: [Transaction], calendar: Calendar) -> [MonthlyBucket] {
        var income: [MonthKey: Int] = [:]
        var spending: [MonthKey: Int] = [:]

        for tx in transactions {
            let key = MonthKey(from: tx.date, calendar: calendar)
            switch tx.direction {
            case .incoming:
                income[key, default: 0] += tx.amount.amount
            case .outgoing:
                spending[key, default: 0] += tx.amount.amount
            }
        }

        let allKeys = Set(income.keys).union(spending.keys)
        return allKeys
            .sorted()
            .map { key in
                MonthlyBucket(
                    key: key,
                    income: Money(income[key] ?? 0),
                    spending: Money(spending[key] ?? 0)
                )
            }
    }

    static func aggregateByCategory(_ transactions: [Transaction]) -> [TransactionCategory: Money] {
        var totals: [TransactionCategory: Int] = [:]
        for tx in transactions where tx.direction == .outgoing {
            totals[tx.category, default: 0] += tx.amount.amount
        }
        return totals.mapValues { Money($0) }
    }

    static func averageMoney(_ values: [Money]) -> Money {
        guard !values.isEmpty else { return Money(0) }
        let total = values.reduce(0) { $0 + $1.amount }
        return Money(total / values.count)
    }

    static func classifyBreakEven(income: Money, spending: Money) -> BreakEvenStatus {
        guard income.amount > 0 else {
            return spending.isZero ? .atBreakEven : .wellBelowBreakEven
        }
        let net = income.amount - spending.amount
        let ratio = Double(net) / Double(income.amount)
        switch ratio {
        case 0.15...:    return .wellAboveBreakEven
        case 0.05..<0.15: return .aboveBreakEven
        case -0.05..<0.05: return .atBreakEven
        case -0.15..<(-0.05): return .belowBreakEven
        default: return .wellBelowBreakEven
        }
    }

    /// Trend bazat pe ultimele 3 luni (sau toate dacă sunt mai puține).
    static func classifyBalanceTrend(buckets: [MonthlyBucket]) -> BalanceTrend {
        let recent = buckets.suffix(3)
        guard !recent.isEmpty else { return .breakingEven }
        let balances = recent.map(\.balance.amount)
        let allPositive = balances.allSatisfy { $0 > 0 }
        let allNegative = balances.allSatisfy { $0 < 0 }
        let avgBalance = balances.reduce(0, +) / max(balances.count, 1)
        let avgIncome = recent.map(\.income.amount).reduce(0, +) / max(recent.count, 1)

        if avgIncome == 0 {
            return allNegative ? .negative : .breakingEven
        }
        let savingsRatio = Double(avgBalance) / Double(avgIncome)

        // Praguri calibrate pe realitatea RO (salariu mediu 4-6k):
        // 20% savings = sănătos, sub 20% = strâns dar pozitiv,
        // deficit moderat = alunecă, deficit > 10% = negativ clar.
        if allPositive && savingsRatio >= 0.20 {
            return .healthy
        }
        if allPositive {
            return .barelyBreakeven
        }
        if allNegative && savingsRatio <= -0.10 {
            return .negative
        }
        if allNegative {
            return .slidingNegative
        }
        // Mixed signs.
        return savingsRatio > 0 ? .barelyBreakeven : .slidingNegative
    }

    static func empty(windowDays: Int) -> CashFlowAnalysis {
        CashFlowAnalysis(
            windowDays: windowDays, analyzedMonths: 0,
            monthlyIncomeAvg: 0, monthlyIncomeLowest: nil, monthlyIncomeHighest: nil,
            monthlySpendingAvg: 0, spendingByCategory: [:],
            monthlyBalanceTrend: .breakingEven,
            velocityRONPerDay: 0, breakEvenStatus: .atBreakEven,
            monthlySavingsAvg: 0, incomeConsumptionRatio: 0
        )
    }
}
