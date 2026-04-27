import Testing
import Foundation
@testable import SolomonStorage
import SolomonCore

private func makeObligation(
    name: String = "Chirie",
    amount: Int = 1_500,
    day: Int = 1,
    kind: ObligationKind = .rentMortgage,
    confidence: ObligationConfidence = .declared
) -> Obligation {
    Obligation(name: name, amount: Money(amount), dayOfMonth: day,
               kind: kind, confidence: confidence)
}

@MainActor
private func makeRepo() -> CoreDataObligationRepository {
    let ctrl = SolomonPersistenceController.makeInMemory()
    return CoreDataObligationRepository(context: ctrl.container.viewContext)
}

@Suite @MainActor struct ObligationRepositoryTests {

    @Test func saveAndFetchAll() throws {
        let repo = makeRepo()
        let ob = makeObligation()
        try repo.save(ob)
        let all = try repo.fetchAll()
        #expect(all.count == 1)
        #expect(all[0].name == "Chirie")
        #expect(all[0].amount == Money(1_500))
    }

    @Test func saveBatchAndCount() throws {
        let repo = makeRepo()
        try repo.save([
            makeObligation(name: "Chirie", day: 1),
            makeObligation(name: "Netflix", amount: 40, day: 15, kind: .subscription),
            makeObligation(name: "Mokka", amount: 240, day: 5, kind: .bnpl, confidence: .detected)
        ])
        #expect(try repo.count() == 3)
    }

    @Test func fetchByKindFiltersCorrectly() throws {
        let repo = makeRepo()
        try repo.save([
            makeObligation(name: "Chirie",  kind: .rentMortgage),
            makeObligation(name: "Netflix", kind: .subscription),
            makeObligation(name: "Mokka",   kind: .bnpl)
        ])
        let rents = try repo.fetch(kind: .rentMortgage)
        #expect(rents.count == 1)
        #expect(rents[0].name == "Chirie")
    }

    @Test func fetchDebtsReturnsBNPLAndLoansOnly() throws {
        let repo = makeRepo()
        try repo.save([
            makeObligation(name: "Chirie",  day: 1,  kind: .rentMortgage),
            makeObligation(name: "BCR",     day: 10, kind: .loanBank),
            makeObligation(name: "Mokka",   day: 5,  kind: .bnpl),
            makeObligation(name: "Credius", day: 18, kind: .loanIFN),
            makeObligation(name: "Enel",    day: 20, kind: .utility)
        ])
        let debts = try repo.fetchDebts()
        #expect(debts.count == 3)
        #expect(debts.allSatisfy { $0.isDebt })
    }

    @Test func fetchAllSortedByDayOfMonth() throws {
        let repo = makeRepo()
        try repo.save([
            makeObligation(name: "C", day: 25),
            makeObligation(name: "A", day: 1),
            makeObligation(name: "B", day: 10)
        ])
        let all = try repo.fetchAll()
        #expect(all[0].name == "A")
        #expect(all[1].name == "B")
        #expect(all[2].name == "C")
    }

    @Test func deleteRemovesObligation() throws {
        let repo = makeRepo()
        let ob = makeObligation()
        try repo.save(ob)
        try repo.delete(id: ob.id)
        #expect(try repo.count() == 0)
    }

    @Test func upsertUpdatesAmount() throws {
        let repo = makeRepo()
        let id = UUID()
        let original = Obligation(id: id, name: "Chirie", amount: Money(1_500),
                                  dayOfMonth: 1, kind: .rentMortgage, confidence: .declared)
        try repo.upsert(original)

        let updated = Obligation(id: id, name: "Chirie", amount: Money(1_700),
                                 dayOfMonth: 1, kind: .rentMortgage, confidence: .declared)
        try repo.upsert(updated)

        let all = try repo.fetchAll()
        #expect(all.count == 1)
        #expect(all[0].amount == Money(1_700))
    }

    @Test func allFieldsRoundtripThroughCoreData() throws {
        let repo = makeRepo()
        var c = DateComponents(); c.year = 2026; c.month = 1; c.day = 1
        let sinceDate = Calendar.gregorianRO.date(from: c)!

        let ob = Obligation(
            name: "Credit BCR",
            amount: Money(780),
            dayOfMonth: 15,
            kind: .loanBank,
            confidence: .detected,
            since: sinceDate
        )
        try repo.save(ob)
        let fetched = try repo.fetchAll().first!
        #expect(fetched.id == ob.id)
        #expect(fetched.name == "Credit BCR")
        #expect(fetched.amount == Money(780))
        #expect(fetched.dayOfMonth == 15)
        #expect(fetched.kind == .loanBank)
        #expect(fetched.confidence == .detected)
        #expect(fetched.since != nil)
    }
}
