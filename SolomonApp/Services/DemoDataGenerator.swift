import Foundation
import SolomonCore
import SolomonStorage

// MARK: - DemoDataGenerator
//
// Generează 6 luni de date realiste pentru testare:
//   - Salariu lunar pe data 28
//   - Cheltuieli zilnice (mâncare, transport, livrări)
//   - Subscriptions recurente (Netflix, Spotify, etc.)
//   - Câteva spike-uri (eMAG, vacanță)
//
// Folosit din Settings → Debug → "Generate demo data"

@MainActor
public enum DemoDataGenerator {

    // MARK: - Public API

    public static func populate(
        transactionRepo: any TransactionRepository,
        obligationRepo: any ObligationRepository,
        subscriptionRepo: any SubscriptionRepository,
        userProfileRepo: any UserProfileRepository
    ) throws {
        let now = Date()
        let cal = Calendar.current

        // 1) UserProfile — adaugăm doar dacă lipsește
        let existingProfile = try? userProfileRepo.fetchProfile()
        if existingProfile == nil {
            let demo = DemographicProfile(
                name: "Andrei",
                addressing: .tu,
                ageRange: .range25to35
            )
            let fin = FinancialProfile(
                salaryRange: .range5to8,
                salaryFrequency: .monthly(dayOfMonth: 28),
                hasSecondaryIncome: false,
                primaryBank: .bancaTransilvania
            )
            try userProfileRepo.saveProfile(UserProfile(demographics: demo, financials: fin))
        }

        // 2) Obligații recurente
        let obligations: [Obligation] = [
            Obligation(name: "Chirie",         amount: Money(2500), dayOfMonth: 1,  kind: .rentMortgage, confidence: .declared),
            Obligation(name: "Enel",           amount: Money(180),  dayOfMonth: 12, kind: .utility,      confidence: .declared),
            Obligation(name: "Digi internet",  amount: Money(60),   dayOfMonth: 15, kind: .utility,      confidence: .declared),
            Obligation(name: "Apa Nova",       amount: Money(45),   dayOfMonth: 18, kind: .utility,      confidence: .declared),
            Obligation(name: "Asigurare casa", amount: Money(95),   dayOfMonth: 5,  kind: .insurance,    confidence: .declared),
        ]
        for o in obligations {
            try obligationRepo.upsert(o)
        }

        // 3) Subscriptions (cu ghost detection prin lastUsedDaysAgo)
        let subscriptions: [Subscription] = [
            Subscription(name: "Netflix",              amountMonthly: Money(40),  lastUsedDaysAgo: 3),
            Subscription(name: "Spotify",              amountMonthly: Money(25),  lastUsedDaysAgo: 1),
            Subscription(name: "HBO Max",              amountMonthly: Money(35),  lastUsedDaysAgo: 110),  // ghost
            Subscription(name: "Adobe Creative Cloud", amountMonthly: Money(120), lastUsedDaysAgo: 150),  // ghost
            Subscription(name: "iCloud+ 200GB",        amountMonthly: Money(15),  lastUsedDaysAgo: 0),
        ]
        for s in subscriptions {
            try subscriptionRepo.upsert(s)
        }

        // 4) 6 luni de tranzacții
        var allTransactions: [Transaction] = []

        for monthOffset in stride(from: 6, through: 0, by: -1) {
            guard let monthDate = cal.date(byAdding: .month, value: -monthOffset, to: now) else { continue }

            // Salariu pe 28
            if let salaryDate = cal.date(bySetting: .day, value: 28, of: monthDate),
               salaryDate <= now {
                allTransactions.append(Transaction(
                    date: salaryDate,
                    amount: Money(6200),
                    direction: .incoming,
                    category: .unknown,
                    merchant: "Salariu",
                    description: "Virament salariu lunar",
                    source: .manualEntry
                ))
            }

            // Cheltuieli recurente (chirie, utilități)
            for o in obligations {
                if let dueDate = cal.date(bySetting: .day, value: o.dayOfMonth, of: monthDate),
                   dueDate <= now {
                    let cat: TransactionCategory = o.kind == .utility ? .utilities : .rentMortgage
                    allTransactions.append(Transaction(
                        date: dueDate,
                        amount: o.amount,
                        direction: .outgoing,
                        category: cat,
                        merchant: o.name,
                        description: nil,
                        source: .derivedFromObligation
                    ))
                }
            }

            // Subscriptions
            for s in subscriptions {
                let renewDay = ((monthOffset * 7) + s.name.count) % 28 + 1
                if let renewDate = cal.date(bySetting: .day, value: renewDay, of: monthDate),
                   renewDate <= now {
                    allTransactions.append(Transaction(
                        date: renewDate,
                        amount: s.amountMonthly,
                        direction: .outgoing,
                        category: .subscriptions,
                        merchant: s.name,
                        description: nil,
                        source: .emailParsed
                    ))
                }
            }

            // Cheltuieli random per zi
            let daysInMonth = cal.range(of: .day, in: .month, for: monthDate)?.count ?? 30
            for day in 1...daysInMonth {
                guard let dayDate = cal.date(bySetting: .day, value: day, of: monthDate) else { continue }
                if dayDate > now { break }

                // 60% șansă food delivery
                if Double.random(in: 0...1) < 0.6 {
                    let amount = [25, 32, 45, 58, 67, 89].randomElement() ?? 35
                    allTransactions.append(Transaction(
                        date: dayDate.addingTimeInterval(Double.random(in: 12*3600...20*3600)),
                        amount: Money(amount),
                        direction: .outgoing,
                        category: .foodDelivery,
                        merchant: ["Glovo", "Bolt Food", "Tazz"].randomElement() ?? "Glovo",
                        description: nil,
                        source: .notificationParsed
                    ))
                }

                // 40% șansă transport
                if Double.random(in: 0...1) < 0.4 {
                    allTransactions.append(Transaction(
                        date: dayDate.addingTimeInterval(Double.random(in: 8*3600...22*3600)),
                        amount: Money([12, 15, 18, 22, 28].randomElement() ?? 15),
                        direction: .outgoing,
                        category: .transport,
                        merchant: ["Bolt", "Uber"].randomElement() ?? "Bolt",
                        description: nil,
                        source: .notificationParsed
                    ))
                }

                // 30% șansă supermarket
                if Double.random(in: 0...1) < 0.3 {
                    allTransactions.append(Transaction(
                        date: dayDate.addingTimeInterval(Double.random(in: 10*3600...20*3600)),
                        amount: Money([45, 67, 89, 123, 156, 234].randomElement() ?? 80),
                        direction: .outgoing,
                        category: .foodGrocery,
                        merchant: ["Kaufland", "Lidl", "Mega Image", "Carrefour", "Profi"].randomElement() ?? "Lidl",
                        description: nil,
                        source: .notificationParsed
                    ))
                }

                // 10% șansă shopping online
                if Double.random(in: 0...1) < 0.1 {
                    allTransactions.append(Transaction(
                        date: dayDate,
                        amount: Money([89, 145, 234, 389, 567].randomElement() ?? 200),
                        direction: .outgoing,
                        category: .shoppingOnline,
                        merchant: ["eMAG", "Altex", "Fashion Days"].randomElement() ?? "eMAG",
                        description: nil,
                        source: .emailParsed
                    ))
                }
            }
        }

        try transactionRepo.save(allTransactions)
    }

    // MARK: - Cleanup

    public static func clearAll(
        transactionRepo: any TransactionRepository,
        obligationRepo: any ObligationRepository,
        subscriptionRepo: any SubscriptionRepository
    ) throws {
        for tx in try transactionRepo.fetchAll() {
            try transactionRepo.delete(id: tx.id)
        }
        for o in try obligationRepo.fetchAll() {
            try obligationRepo.delete(id: o.id)
        }
        for s in try subscriptionRepo.fetchAll() {
            try subscriptionRepo.delete(id: s.id)
        }
    }
}
