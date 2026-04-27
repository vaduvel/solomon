import Foundation
import SolomonCore

// MARK: - SuspiciousTransactionDetector
//
// Conform spec §10.3 — detectează tranzacții suspecte care merită
// un soft ping ("Văd ceva neobișnuit. Tu ești?").
//
// 3 trigger-uri:
//   1. Tranzacție > 5x media zilnică
//   2. 5+ tranzacții în <1h (burst)
//   3. Tranzacție la merchant nou de noapte (00:00-05:00)

public struct SuspiciousTransactionDetector: Sendable {

    // MARK: - Configurare

    /// Multiplicatorul aplicat mediei zilnice peste care o sumă e suspectă.
    public var dailyAverageMultiplier: Double = 5.0

    /// Numărul de tranzacții consecutive în interval scurt → burst.
    public var burstThreshold: Int = 5

    /// Intervalul de timp pentru burst detection (secunde).
    public var burstWindow: TimeInterval = 3600  // 1h

    /// Ora de început a "nocturnului" (24h format).
    public var nightStart: Int = 0
    /// Ora de sfârșit (exclusiv).
    public var nightEnd: Int = 5

    /// Numărul de zile de istoric considerat când calculăm media zilnică.
    public var historyWindowDays: Int = 30

    public init() {}

    // MARK: - Result type

    public struct Suspicion: Sendable, Equatable, Hashable, Identifiable {
        public let id: UUID                    // = transaction.id
        public let transactionId: UUID
        public let trigger: Trigger
        public let severity: Severity
        public let evidenceText: String

        public enum Trigger: String, Sendable, Hashable {
            case largeAmountVsAverage   // 5x avg
            case burstActivity          // 5+ in 1h
            case unusualNightMerchant   // 00-05 nou
        }

        public enum Severity: String, Sendable, Hashable {
            case soft       // Soft ping ("Tu ești?")
            case medium     // Dublu trigger (large + night, etc)
            case high       // Trigger triplu sau very large amount

            public var rank: Int {
                switch self {
                case .soft:   return 1
                case .medium: return 2
                case .high:   return 3
                }
            }
        }

        public init(transactionId: UUID, trigger: Trigger, severity: Severity, evidenceText: String) {
            self.id = transactionId
            self.transactionId = transactionId
            self.trigger = trigger
            self.severity = severity
            self.evidenceText = evidenceText
        }
    }

    // MARK: - Public API

    /// Analizează un set de tranzacții și returnează lista celor suspecte.
    /// - Parameters:
    ///   - transactions: toate tranzacțiile (incoming + outgoing); algoritmul filtrează
    ///   - referenceDate: data de referință pentru "now" (default: Date())
    public func detect(
        in transactions: [Transaction],
        referenceDate: Date = Date()
    ) -> [Suspicion] {
        let outgoing = transactions
            .filter { $0.isOutgoing }
            .sorted { $0.date < $1.date }

        guard !outgoing.isEmpty else { return [] }

        // 1) Calculăm media zilnică pe history window
        let avgDaily = computeDailyAverage(
            outgoing,
            referenceDate: referenceDate,
            windowDays: historyWindowDays
        )

        var triggersByTransaction: [UUID: Set<Suspicion.Trigger>] = [:]
        var evidenceByTransaction: [UUID: [String]] = [:]

        // 2) Trigger 1: large amount vs avg
        if avgDaily > 0 {
            let threshold = Double(avgDaily) * dailyAverageMultiplier
            for tx in outgoing where Double(tx.amount.amount) >= threshold {
                triggersByTransaction[tx.id, default: []].insert(.largeAmountVsAverage)
                let multiple = Double(tx.amount.amount) / Double(avgDaily)
                evidenceByTransaction[tx.id, default: []].append(
                    String(format: "%.1fx media zilnică (%d RON)", multiple, avgDaily)
                )
            }
        }

        // 3) Trigger 2: burst (5+ în 1h)
        let burstIds = detectBursts(outgoing)
        for id in burstIds {
            triggersByTransaction[id, default: []].insert(.burstActivity)
            evidenceByTransaction[id, default: []].append(
                "\(burstThreshold)+ tranzacții în <1h"
            )
        }

        // 4) Trigger 3: night new merchant
        let nightSuspectIds = detectNightNewMerchants(outgoing, referenceDate: referenceDate)
        for id in nightSuspectIds {
            triggersByTransaction[id, default: []].insert(.unusualNightMerchant)
            evidenceByTransaction[id, default: []].append("Merchant nou la noapte (00–05)")
        }

        // 5) Construim rezultate. Triggerii multipli → severity mai mare.
        var suspicions: [Suspicion] = []
        for (txId, triggers) in triggersByTransaction {
            let primaryTrigger: Suspicion.Trigger
            if triggers.contains(.largeAmountVsAverage) { primaryTrigger = .largeAmountVsAverage }
            else if triggers.contains(.unusualNightMerchant) { primaryTrigger = .unusualNightMerchant }
            else { primaryTrigger = .burstActivity }

            let severity: Suspicion.Severity
            switch triggers.count {
            case 1: severity = .soft
            case 2: severity = .medium
            default: severity = .high
            }

            let evidence = (evidenceByTransaction[txId] ?? []).joined(separator: " · ")
            suspicions.append(Suspicion(
                transactionId: txId,
                trigger: primaryTrigger,
                severity: severity,
                evidenceText: evidence
            ))
        }

        // Sortăm desc după severity → trigger
        return suspicions.sorted {
            if $0.severity.rank != $1.severity.rank { return $0.severity.rank > $1.severity.rank }
            return $0.trigger.rawValue < $1.trigger.rawValue
        }
    }

    // MARK: - Internals

    func computeDailyAverage(
        _ outgoing: [Transaction],
        referenceDate: Date,
        windowDays: Int
    ) -> Int {
        let cal = Calendar.current
        guard let windowStart = cal.date(byAdding: .day, value: -windowDays, to: referenceDate) else { return 0 }
        let recent = outgoing.filter { $0.date >= windowStart }
        guard !recent.isEmpty else { return 0 }

        let totalSpent = recent.reduce(0) { $0 + $1.amount.amount }
        let days = max(1, windowDays)
        return totalSpent / days
    }

    /// Returnează ID-urile tranzacțiilor care fac parte dintr-un burst (5+ în 1h).
    func detectBursts(_ outgoing: [Transaction]) -> Set<UUID> {
        var burstIds: Set<UUID> = []
        guard outgoing.count >= burstThreshold else { return burstIds }

        for i in 0...(outgoing.count - burstThreshold) {
            let window = outgoing[i..<(i + burstThreshold)]
            let first = window.first!
            let last = window.last!
            if last.date.timeIntervalSince(first.date) <= burstWindow {
                for tx in window {
                    burstIds.insert(tx.id)
                }
            }
        }
        return burstIds
    }

    /// Identifică tranzacții la merchant NOU făcute la noapte (00–05).
    /// "Nou" = primul merchant pe care nu l-ai mai văzut în ultimele `historyWindowDays` zile.
    func detectNightNewMerchants(_ outgoing: [Transaction], referenceDate: Date) -> Set<UUID> {
        let cal = Calendar.current
        guard let cutoff = cal.date(byAdding: .day, value: -historyWindowDays, to: referenceDate) else { return [] }

        var seenMerchants: Set<String> = []
        // Build "seen" set din istoricul vechi (mai vechi de cutoff dar în orele 5-24)
        for tx in outgoing where tx.date < cutoff {
            if let m = tx.merchant?.lowercased() {
                seenMerchants.insert(m)
            }
        }

        var suspect: Set<UUID> = []
        for tx in outgoing where tx.date >= cutoff {
            let hour = cal.component(.hour, from: tx.date)
            let isNight = (hour >= nightStart && hour < nightEnd)
            guard isNight else {
                // Adăugăm la seen (apariție de zi → pattern normal)
                if let m = tx.merchant?.lowercased() { seenMerchants.insert(m) }
                continue
            }
            // E noapte
            if let m = tx.merchant?.lowercased() {
                if !seenMerchants.contains(m) {
                    suspect.insert(tx.id)
                }
                seenMerchants.insert(m)  // după ce l-am marcat, devine "seen"
            } else {
                // Tranzacție de noapte fără merchant nume → suspect
                suspect.insert(tx.id)
            }
        }
        return suspect
    }
}
