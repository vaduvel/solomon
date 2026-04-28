import Foundation
import SolomonCore

// MARK: - SubscriptionUsageDetector
//
// Auto-calculează `lastUsedDaysAgo` pentru subscriptions analizând tranzacțiile.
// Strategy: pentru fiecare subscription, găsim ultima tranzacție care matches
// merchant-ul și amount-ul (sau o variantă apropiată).
//
// "Folosit" = există o tranzacție cu numele subscription-ului în ultimele N zile.
// Dacă nu există → e ghost (lastUsedDaysAgo = days since detection).

public struct SubscriptionUsageDetector: Sendable {

    public init() {}

    /// Re-calculează lastUsedDaysAgo pentru fiecare subscription, comparând cu tranzacțiile.
    /// - Returns: subscriptions cu lastUsedDaysAgo updated.
    public func enrichWithUsage(
        subscriptions: [Subscription],
        transactions: [Transaction],
        referenceDate: Date = Date()
    ) -> [Subscription] {
        return subscriptions.map { sub in
            let daysAgo = computeDaysAgoFromTransactions(
                subscription: sub,
                transactions: transactions,
                referenceDate: referenceDate
            )
            var updated = sub
            updated.lastUsedDaysAgo = daysAgo

            // Auto-populate cancellation info din knowledge base dacă lipsește
            if updated.cancellationUrl == nil,
               let entry = SubscriptionCancellationDB.entry(forSubscriptionName: sub.name) {
                updated.cancellationUrl = entry.cancellationUrl
                updated.cancellationStepsSummary = entry.stepsSummary
                updated.cancellationWarning = entry.warning
                updated.alternativeSuggestion = entry.alternative
                updated.cancellationDifficulty = entry.difficulty
            }
            return updated
        }
    }

    /// Pentru un subscription dat, găsește ultima tranzacție care îl reprezintă.
    /// Match strategie: numele subscription-ului apare în merchant-ul tranzacției
    /// (case-insensitive) ȘI suma e în range ±20% din amountMonthly.
    func computeDaysAgoFromTransactions(
        subscription: Subscription,
        transactions: [Transaction],
        referenceDate: Date
    ) -> Int? {
        let subNameLow = subscription.name.lowercased()
        let expectedAmount = subscription.amountMonthly.amount
        let lowerBound = Int(Double(expectedAmount) * 0.8)
        let upperBound = Int(Double(expectedAmount) * 1.2)

        let matchingTxs = transactions.filter { tx in
            guard tx.isOutgoing else { return false }
            guard let merchant = tx.merchant?.lowercased() else { return false }
            guard merchant.contains(subNameLow) || subNameLow.contains(merchant) else { return false }
            // Suma plauzibilă pentru a fi pentru subscription
            return tx.amount.amount >= lowerBound && tx.amount.amount <= upperBound
        }

        guard let lastMatch = matchingTxs.max(by: { $0.date < $1.date }) else {
            // Niciun match — păstrăm valoarea existentă (sau nil)
            return subscription.lastUsedDaysAgo
        }

        let daysAgo = Calendar.current.dateComponents([.day], from: lastMatch.date, to: referenceDate).day ?? 0
        return max(0, daysAgo)
    }
}
