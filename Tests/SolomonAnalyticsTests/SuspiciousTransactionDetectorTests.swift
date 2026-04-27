import Testing
import Foundation
@testable import SolomonAnalytics
@testable import SolomonCore

@Suite struct SuspiciousTransactionDetectorTests {

    let detector = SuspiciousTransactionDetector()
    let now = Date(timeIntervalSince1970: 1_761_600_000)  // 2025-10-27 14:40 UTC, fixed
    let cal = Calendar(identifier: .gregorian)

    // MARK: - Helpers

    private func tx(
        amount: Int,
        daysAgo: Int = 0,
        hourOfDay: Int = 12,
        merchant: String = "Glovo",
        id: UUID = UUID()
    ) -> Transaction {
        let baseDate = cal.date(byAdding: .day, value: -daysAgo, to: now)!
        let dateAtHour = cal.date(bySetting: .hour, value: hourOfDay, of: baseDate)!
        return Transaction(
            id: id,
            date: dateAtHour,
            amount: Money(amount),
            direction: .outgoing,
            category: .foodDelivery,
            merchant: merchant,
            description: nil,
            source: .notificationParsed
        )
    }

    // MARK: - 1. Large amount vs average

    @Test func detectsLargeAmountVsAverage() {
        // 30 days of small txs (50 RON each, total 1500 RON, avg 50 RON/day)
        var txs: [Transaction] = []
        for d in 0..<30 {
            txs.append(tx(amount: 50, daysAgo: d, merchant: "Glovo"))
        }
        // 1 large tx (5x avg = 250+) → should be flagged
        let largeId = UUID()
        txs.append(tx(amount: 1000, daysAgo: 0, merchant: "eMAG", id: largeId))

        let result = detector.detect(in: txs, referenceDate: now)
        #expect(result.contains { $0.transactionId == largeId })
        #expect(result.first { $0.transactionId == largeId }?.trigger == .largeAmountVsAverage)
    }

    @Test func ignoresAmountUnderThreshold() {
        // avg ~50/day; 200 RON e 4x → NU 5x → NU flag
        var txs: [Transaction] = []
        for d in 0..<30 {
            txs.append(tx(amount: 50, daysAgo: d))
        }
        let normalId = UUID()
        txs.append(tx(amount: 200, daysAgo: 0, id: normalId))

        let result = detector.detect(in: txs, referenceDate: now)
        let flagged = result.first { $0.transactionId == normalId }
        // Poate să fie flagged DOAR pe burst sau night, nu pe large
        if let f = flagged {
            #expect(f.trigger != .largeAmountVsAverage)
        }
    }

    // MARK: - 2. Burst activity

    @Test func detectsBurst5InOneHour() {
        // 5 tranzacții în 30 minute
        let baseDate = now
        var txs: [Transaction] = []
        let burstIds: [UUID] = (0..<5).map { _ in UUID() }
        for (i, id) in burstIds.enumerated() {
            let date = baseDate.addingTimeInterval(Double(i) * 300)  // 5 min apart
            txs.append(Transaction(
                id: id,
                date: date,
                amount: Money(30),
                direction: .outgoing,
                category: .foodDelivery,
                merchant: "Glovo",
                description: nil,
                source: .notificationParsed
            ))
        }

        let result = detector.detect(in: txs, referenceDate: now)
        // Toate 5 ar trebui flagate
        for id in burstIds {
            #expect(result.contains { $0.transactionId == id })
        }
    }

    @Test func ignores4InOneHour() {
        // 4 tranzacții (sub threshold 5) — nu trebuie flagate ca burst
        var txs: [Transaction] = []
        let baseDate = now
        for i in 0..<4 {
            let date = baseDate.addingTimeInterval(Double(i) * 600)
            txs.append(Transaction(
                id: UUID(),
                date: date,
                amount: Money(30),
                direction: .outgoing,
                category: .foodDelivery,
                merchant: "Glovo",
                description: nil,
                source: .notificationParsed
            ))
        }
        let result = detector.detect(in: txs, referenceDate: now)
        // Niciuna nu ar trebui flagată ca burst
        for r in result {
            #expect(r.trigger != .burstActivity)
        }
    }

    @Test func ignores5InTwoHours() {
        // 5 tranzacții peste 2 ore — fereastra e 1h, deci NU burst
        var txs: [Transaction] = []
        let baseDate = now
        for i in 0..<5 {
            let date = baseDate.addingTimeInterval(Double(i) * 1900)  // ~32 min apart → 2.1h total
            txs.append(Transaction(
                id: UUID(),
                date: date,
                amount: Money(30),
                direction: .outgoing,
                category: .foodDelivery,
                merchant: "Glovo",
                description: nil,
                source: .notificationParsed
            ))
        }
        let result = detector.detect(in: txs, referenceDate: now)
        for r in result {
            #expect(r.trigger != .burstActivity)
        }
    }

    // MARK: - 3. Night new merchant

    @Test func detectsNightNewMerchant() {
        // Istoricul vechi (>30 zile) — merchanti cunoscuți
        var txs: [Transaction] = []
        for d in 31...60 {
            txs.append(tx(amount: 30, daysAgo: d, hourOfDay: 14, merchant: "Glovo"))
        }
        // Recent: tranzacție la 02:00 la merchant NOU
        let nightId = UUID()
        txs.append(tx(amount: 200, daysAgo: 1, hourOfDay: 2, merchant: "WeirdMerchant", id: nightId))

        let result = detector.detect(in: txs, referenceDate: now)
        let flagged = result.first { $0.transactionId == nightId }
        #expect(flagged != nil)
    }

    @Test func ignoresNightKnownMerchant() {
        // Glovo la 02:00 — dar Glovo e cunoscut din istoricul de zi
        var txs: [Transaction] = []
        for d in 31...60 {
            txs.append(tx(amount: 30, daysAgo: d, hourOfDay: 14, merchant: "Glovo"))
        }
        let knownNightId = UUID()
        txs.append(tx(amount: 30, daysAgo: 1, hourOfDay: 2, merchant: "Glovo", id: knownNightId))

        let result = detector.detect(in: txs, referenceDate: now)
        let flagged = result.first { $0.transactionId == knownNightId }
        // Nu trebuie să fie flagată pe night (e cunoscut)
        if let f = flagged {
            #expect(f.trigger != .unusualNightMerchant)
        }
    }

    @Test func ignoresDayNewMerchant() {
        // Tranzacție de zi (14:00) la merchant nou — NU e suspect (oamenii descoperă mereu)
        var txs: [Transaction] = []
        for d in 31...60 {
            txs.append(tx(amount: 30, daysAgo: d, hourOfDay: 14, merchant: "Glovo"))
        }
        let dayNewId = UUID()
        txs.append(tx(amount: 50, daysAgo: 1, hourOfDay: 14, merchant: "NewRestaurant", id: dayNewId))

        let result = detector.detect(in: txs, referenceDate: now)
        let flagged = result.first { $0.transactionId == dayNewId }
        if let f = flagged {
            #expect(f.trigger != .unusualNightMerchant)
        }
    }

    // MARK: - Combined / severity

    @Test func tripleSeverityCombined() {
        // O tranzacție mare la noapte ca parte din burst
        // Nu mereu se întâmplă, dar testăm suprapunerea
        var txs: [Transaction] = []
        for d in 31...60 {
            txs.append(tx(amount: 30, daysAgo: d, hourOfDay: 14, merchant: "Glovo"))
        }

        // 5 tranzacții la noapte la merchant nou
        let baseDate = cal.date(byAdding: .day, value: -1, to: now)!
        let nightDate = cal.date(bySetting: .hour, value: 2, of: baseDate)!
        let burstIds: [UUID] = (0..<5).map { _ in UUID() }
        for (i, id) in burstIds.enumerated() {
            let amount = i == 0 ? 1000 : 30
            txs.append(Transaction(
                id: id,
                date: nightDate.addingTimeInterval(Double(i) * 300),
                amount: Money(amount),
                direction: .outgoing,
                category: .foodDelivery,
                merchant: "ScamMerchant",
                description: nil,
                source: .notificationParsed
            ))
        }

        let result = detector.detect(in: txs, referenceDate: now)
        // Prima tranzacție din burst (1000 RON, noapte, merchant nou) ar trebui să aibă severity high
        let first = result.first { $0.transactionId == burstIds[0] }
        #expect(first != nil)
        #expect(first?.severity == .high)
    }

    // MARK: - Empty input

    @Test func emptyTransactionsReturnsEmpty() {
        let result = detector.detect(in: [], referenceDate: now)
        #expect(result.isEmpty)
    }

    @Test func onlyIncomingReturnsEmpty() {
        let income = Transaction(
            id: UUID(),
            date: now,
            amount: Money(5000),
            direction: .incoming,
            category: .unknown,
            merchant: "Salariu",
            description: nil,
            source: .manualEntry
        )
        let result = detector.detect(in: [income], referenceDate: now)
        #expect(result.isEmpty)
    }
}
