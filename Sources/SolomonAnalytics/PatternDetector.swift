import Foundation
import SolomonCore

// MARK: - Output types

public struct CategorySpending: Sendable, Hashable, Codable {
    public var category: TransactionCategory
    public var totalAmount: Money
    public var transactionCount: Int
    public var dominantMerchant: String?
    public var fractionOfTotal: Double

    public init(category: TransactionCategory, totalAmount: Money,
                transactionCount: Int, dominantMerchant: String? = nil,
                fractionOfTotal: Double) {
        self.category = category
        self.totalAmount = totalAmount
        self.transactionCount = transactionCount
        self.dominantMerchant = dominantMerchant
        self.fractionOfTotal = fractionOfTotal
    }
}

public struct WeekendSpikeSignal: Sendable, Hashable, Codable {
    public var weekendAvgPerDay: Money
    public var weekdayAvgPerDay: Money
    public var ratio: Double
    public var isSignificant: Bool
}

public struct TemporalCluster: Sendable, Hashable, Codable {
    public var category: TransactionCategory
    public var dominantWeekday: Int       // 1=duminică ... 7=sâmbătă
    public var concentration: Double      // fractionOf transactions on dominant day
    public var isStrong: Bool             // ≥ 60% concentration
    public var description: String
}

public struct OutlierTransaction: Sendable, Hashable, Codable {
    public var transactionId: UUID
    public var amount: Money
    public var category: TransactionCategory
    public var merchant: String?
    public var date: Date
    public var ratioToDailyAvg: Double
}

public struct FrequencySpike: Sendable, Hashable, Codable {
    public var category: TransactionCategory
    public var merchantDominant: String?
    public var countLast7Days: Int
    public var amountLast7Days: Money
    public var monthlyProjection: Money
    public var description: String
}

public struct PatternReport: Sendable, Hashable, Codable {
    public var topCategories: [CategorySpending]
    public var weekendSpike: WeekendSpikeSignal
    public var temporalClusters: [TemporalCluster]
    public var outliers: [OutlierTransaction]
    public var frequencySpikes: [FrequencySpike]

    public init(topCategories: [CategorySpending], weekendSpike: WeekendSpikeSignal,
                temporalClusters: [TemporalCluster], outliers: [OutlierTransaction],
                frequencySpikes: [FrequencySpike]) {
        self.topCategories = topCategories
        self.weekendSpike = weekendSpike
        self.temporalClusters = temporalClusters
        self.outliers = outliers
        self.frequencySpikes = frequencySpikes
    }
}

// MARK: - Detector

/// Detectează pattern-uri de cheltuieli pe o fereastră de tranzacții (spec §7.2 modul 4).
public struct PatternDetector: Sendable {

    public init() {}

    public func detect(
        transactions: [Transaction],
        windowDays: Int = 90,
        referenceDate: Date = Date(),
        calendar: Calendar = .gregorianRO
    ) -> PatternReport {
        guard let windowStart = calendar.date(byAdding: .day, value: -windowDays, to: referenceDate) else {
            return Self.empty
        }
        let inWindow = transactions.filter { $0.direction == .outgoing
            && $0.date >= windowStart && $0.date <= referenceDate }

        let topCategories = computeTopCategories(inWindow)
        let weekendSpike = computeWeekendSpike(inWindow, windowDays: windowDays, calendar: calendar)
        let temporalClusters = computeTemporalClusters(inWindow, calendar: calendar)
        let outliers = computeOutliers(inWindow, windowDays: windowDays)
        let frequencySpikes = computeFrequencySpikes(
            inWindow, referenceDate: referenceDate, calendar: calendar
        )

        return PatternReport(
            topCategories: topCategories,
            weekendSpike: weekendSpike,
            temporalClusters: temporalClusters,
            outliers: outliers,
            frequencySpikes: frequencySpikes
        )
    }

    // MARK: - Sub-computations

    func computeTopCategories(_ txs: [Transaction]) -> [CategorySpending] {
        let totalSpending = txs.reduce(0) { $0 + $1.amount.amount }
        guard totalSpending > 0 else { return [] }

        var byCategory: [TransactionCategory: [Transaction]] = [:]
        for tx in txs { byCategory[tx.category, default: []].append(tx) }

        return byCategory
            .map { category, items in
                let total = items.reduce(0) { $0 + $1.amount.amount }
                let dominantMerchant = mostFrequentMerchant(items)
                return CategorySpending(
                    category: category,
                    totalAmount: Money(total),
                    transactionCount: items.count,
                    dominantMerchant: dominantMerchant,
                    fractionOfTotal: Double(total) / Double(totalSpending)
                )
            }
            .sorted { $0.totalAmount.amount > $1.totalAmount.amount }
    }

    func mostFrequentMerchant(_ txs: [Transaction]) -> String? {
        var counts: [String: Int] = [:]
        for tx in txs {
            guard let merchant = tx.merchant else { continue }
            counts[merchant, default: 0] += 1
        }
        return counts.max { $0.value < $1.value }?.key
    }

    func computeWeekendSpike(_ txs: [Transaction], windowDays: Int, calendar: Calendar) -> WeekendSpikeSignal {
        var weekendTotal = 0
        var weekdayTotal = 0
        for tx in txs {
            let weekday = calendar.component(.weekday, from: tx.date)
            // Sat = 7, Sun = 1
            if weekday == 1 || weekday == 7 {
                weekendTotal += tx.amount.amount
            } else {
                weekdayTotal += tx.amount.amount
            }
        }
        let weekendDays = Double(windowDays) * 2.0 / 7.0
        let weekdayDays = Double(windowDays) * 5.0 / 7.0
        let weekendAvg = weekendDays > 0 ? Double(weekendTotal) / weekendDays : 0
        let weekdayAvg = weekdayDays > 0 ? Double(weekdayTotal) / weekdayDays : 0
        let ratio = weekdayAvg > 0 ? weekendAvg / weekdayAvg : 0
        return WeekendSpikeSignal(
            weekendAvgPerDay: Money(Int(weekendAvg.rounded())),
            weekdayAvgPerDay: Money(Int(weekdayAvg.rounded())),
            ratio: ratio,
            isSignificant: ratio >= 1.8
        )
    }

    func computeTemporalClusters(_ txs: [Transaction], calendar: Calendar) -> [TemporalCluster] {
        var byCategory: [TransactionCategory: [Transaction]] = [:]
        for tx in txs { byCategory[tx.category, default: []].append(tx) }

        var clusters: [TemporalCluster] = []
        for (category, items) in byCategory where items.count >= 5 {
            var counts = [Int: Int]()  // weekday → count
            for tx in items {
                let weekday = calendar.component(.weekday, from: tx.date)
                counts[weekday, default: 0] += 1
            }
            guard let dominant = counts.max(by: { $0.value < $1.value }) else { continue }
            let concentration = Double(dominant.value) / Double(items.count)
            if concentration >= 0.40 {
                let dayName = RomanianDateFormatter.weekdayName(dominant.key)
                let pct = Int((concentration * 100).rounded())
                let description = "\(pct)% din tranzacțiile la \(category.displayNameRO) sunt \(dayName)"
                clusters.append(TemporalCluster(
                    category: category, dominantWeekday: dominant.key,
                    concentration: concentration, isStrong: concentration >= 0.60,
                    description: description
                ))
            }
        }
        return clusters.sorted { $0.concentration > $1.concentration }
    }

    func computeOutliers(_ txs: [Transaction], windowDays: Int) -> [OutlierTransaction] {
        guard !txs.isEmpty else { return [] }
        let totalAmount = txs.reduce(0) { $0 + $1.amount.amount }
        let dailyAvg = Double(totalAmount) / Double(max(windowDays, 1))
        guard dailyAvg > 0 else { return [] }

        return txs
            .filter { Double($0.amount.amount) >= dailyAvg * 5.0 }
            .map {
                OutlierTransaction(
                    transactionId: $0.id, amount: $0.amount, category: $0.category,
                    merchant: $0.merchant, date: $0.date,
                    ratioToDailyAvg: Double($0.amount.amount) / dailyAvg
                )
            }
            .sorted { $0.amount.amount > $1.amount.amount }
            .prefix(5)
            .map { $0 }
    }

    func computeFrequencySpikes(_ txs: [Transaction], referenceDate: Date, calendar: Calendar) -> [FrequencySpike] {
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: referenceDate) else { return [] }
        let last7 = txs.filter { $0.date >= weekAgo && $0.date <= referenceDate }

        var byCategory: [TransactionCategory: [Transaction]] = [:]
        for tx in last7 { byCategory[tx.category, default: []].append(tx) }

        var spikes: [FrequencySpike] = []
        for (category, items) in byCategory where items.count >= 4 {
            let total = items.reduce(0) { $0 + $1.amount.amount }
            let dominant = mostFrequentMerchant(items)
            spikes.append(FrequencySpike(
                category: category, merchantDominant: dominant,
                countLast7Days: items.count, amountLast7Days: Money(total),
                monthlyProjection: Money(total * 4),
                description: "\(items.count) tranzacții la \(category.displayNameRO) în 7 zile"
            ))
        }
        return spikes.sorted { $0.countLast7Days > $1.countLast7Days }
    }

    static let empty = PatternReport(
        topCategories: [],
        weekendSpike: WeekendSpikeSignal(
            weekendAvgPerDay: 0, weekdayAvgPerDay: 0, ratio: 0, isSignificant: false
        ),
        temporalClusters: [],
        outliers: [],
        frequencySpikes: []
    )
}
