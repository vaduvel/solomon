import Testing
import Foundation
@testable import SolomonStorage
import SolomonCore

private func makeSub(
    name: String = "Spotify",
    amount: Int = 25,
    lastUsedDaysAgo: Int? = nil,
    difficulty: CancellationDifficulty = .easy
) -> Subscription {
    Subscription(name: name, amountMonthly: Money(amount),
                 lastUsedDaysAgo: lastUsedDaysAgo,
                 cancellationDifficulty: difficulty)
}

@MainActor
private func makeRepo() -> CoreDataSubscriptionRepository {
    let ctrl = SolomonPersistenceController.makeInMemory()
    return CoreDataSubscriptionRepository(context: ctrl.container.viewContext)
}

@Suite @MainActor struct SubscriptionRepositoryTests {

    @Test func saveAndFetchAll() throws {
        let repo = makeRepo()
        let sub = makeSub()
        try repo.save(sub)
        let all = try repo.fetchAll()
        #expect(all.count == 1)
        #expect(all[0].name == "Spotify")
    }

    @Test func fetchAllSortedByAmountDescending() throws {
        let repo = makeRepo()
        try repo.save([
            makeSub(name: "Spotify", amount: 25),
            makeSub(name: "Netflix", amount: 40),
            makeSub(name: "Adobe",   amount: 250)
        ])
        let all = try repo.fetchAll()
        #expect(all[0].name == "Adobe")
        #expect(all[1].name == "Netflix")
        #expect(all[2].name == "Spotify")
    }

    @Test func fetchGhostsReturnOnlyOver30Days() throws {
        let repo = makeRepo()
        try repo.save([
            makeSub(name: "Spotify",  amount: 25,  lastUsedDaysAgo: 2),   // active
            makeSub(name: "Netflix",  amount: 40,  lastUsedDaysAgo: 47),  // ghost
            makeSub(name: "HBO",      amount: 35,  lastUsedDaysAgo: 92),  // ghost
            makeSub(name: "Calm",     amount: 29,  lastUsedDaysAgo: nil)  // no signal
        ])
        let ghosts = try repo.fetchGhosts()
        #expect(ghosts.count == 2)
        #expect(ghosts.allSatisfy { $0.isGhost })
    }

    @Test func fetchGhostsExcludesNoSignal() throws {
        let repo = makeRepo()
        try repo.save(makeSub(name: "Calm", lastUsedDaysAgo: nil))
        let ghosts = try repo.fetchGhosts()
        #expect(ghosts.isEmpty)
    }

    @Test func deleteSubscription() throws {
        let repo = makeRepo()
        let sub = makeSub()
        try repo.save(sub)
        try repo.delete(id: sub.id)
        #expect(try repo.count() == 0)
    }

    @Test func upsertUpdatesAmount() throws {
        let repo = makeRepo()
        let id = UUID()
        let original = Subscription(id: id, name: "Spotify", amountMonthly: Money(25),
                                    lastUsedDaysAgo: nil)
        try repo.upsert(original)
        let updated = Subscription(id: id, name: "Spotify", amountMonthly: Money(30),
                                   lastUsedDaysAgo: nil)
        try repo.upsert(updated)

        let all = try repo.fetchAll()
        #expect(all.count == 1)
        #expect(all[0].amountMonthly == Money(30))
    }

    @Test func allFieldsRoundtripThroughCoreData() throws {
        let repo = makeRepo()
        let sub = Subscription(
            name: "Adobe Creative Cloud",
            amountMonthly: Money(249),
            lastUsedDaysAgo: 89,
            cancellationDifficulty: .hard,
            cancellationUrl: URL(string: "https://account.adobe.com"),
            cancellationStepsSummary: "Contul Adobe → Planuri → Anulare",
            alternativeSuggestion: "Canva gratuit pentru uz basic",
            cancellationWarning: "Penalitate de anulare anticipată"
        )
        try repo.save(sub)
        let fetched = try repo.fetchAll().first!
        #expect(fetched.id == sub.id)
        #expect(fetched.name == "Adobe Creative Cloud")
        #expect(fetched.amountMonthly == Money(249))
        #expect(fetched.lastUsedDaysAgo == 89)
        #expect(fetched.cancellationDifficulty == .hard)
        #expect(fetched.cancellationUrl?.host() == "account.adobe.com")
        #expect(fetched.cancellationStepsSummary == "Contul Adobe → Planuri → Anulare")
        #expect(fetched.alternativeSuggestion == "Canva gratuit pentru uz basic")
        #expect(fetched.cancellationWarning == "Penalitate de anulare anticipată")
        #expect(fetched.isGhost == true)
    }
}
