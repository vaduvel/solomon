import Testing
import Foundation
@testable import SolomonStorage
import SolomonCore

// MARK: - Helpers

private let cal = Calendar.gregorianRO

private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
    var c = DateComponents(); c.year = y; c.month = m; c.day = d
    return cal.date(from: c) ?? Date()
}

private func makeTx(
    amount: Int = 100,
    direction: FlowDirection = .outgoing,
    category: TransactionCategory = .foodGrocery,
    on d: Date,
    merchant: String? = nil
) -> Transaction {
    Transaction(date: d, amount: Money(amount), direction: direction,
                category: category, merchant: merchant, source: .csvImport)
}

@MainActor
private func makeRepo() -> (SolomonPersistenceController, CoreDataTransactionRepository) {
    let ctrl = SolomonPersistenceController.makeInMemory()
    let repo = CoreDataTransactionRepository(context: ctrl.container.viewContext)
    return (ctrl, repo)
}

// MARK: - Tests

@Suite @MainActor struct TransactionRepositoryTests {

    // MARK: - Save & fetch all

    @Test func saveSingleAndFetchAll() throws {
        let (_, repo) = makeRepo()
        let tx = makeTx(on: date(2026, 4, 1))
        try repo.save(tx)
        let all = try repo.fetchAll()
        #expect(all.count == 1)
        #expect(all[0].id == tx.id)
        #expect(all[0].amount == tx.amount)
    }

    @Test func saveBatchAndFetchAll() throws {
        let (_, repo) = makeRepo()
        let txs = (1...5).map { makeTx(amount: $0 * 100, on: date(2026, 4, $0)) }
        try repo.save(txs)
        let all = try repo.fetchAll()
        #expect(all.count == 5)
    }

    @Test func fetchAllSortedDescendingByDate() throws {
        let (_, repo) = makeRepo()
        try repo.save([
            makeTx(on: date(2026, 4, 1)),
            makeTx(on: date(2026, 4, 25)),
            makeTx(on: date(2026, 4, 10))
        ])
        let all = try repo.fetchAll()
        #expect(all[0].date == date(2026, 4, 25))
        #expect(all[2].date == date(2026, 4, 1))
    }

    // MARK: - Fetch by date range

    @Test func fetchByDateRangeReturnsMidMonth() throws {
        let (_, repo) = makeRepo()
        try repo.save([
            makeTx(on: date(2026, 3, 28)),   // before window
            makeTx(on: date(2026, 4, 5)),    // inside
            makeTx(on: date(2026, 4, 20)),   // inside
            makeTx(on: date(2026, 5, 2))     // after window
        ])
        let result = try repo.fetch(from: date(2026, 4, 1), to: date(2026, 4, 30))
        #expect(result.count == 2)
    }

    // MARK: - Fetch by category

    @Test func fetchByCategoryFiltersCorrectly() throws {
        let (_, repo) = makeRepo()
        try repo.save([
            makeTx(category: .foodGrocery,  on: date(2026, 4, 1)),
            makeTx(category: .foodDelivery, on: date(2026, 4, 2)),
            makeTx(category: .foodGrocery,  on: date(2026, 4, 3))
        ])
        let groceries = try repo.fetch(category: .foodGrocery)
        #expect(groceries.count == 2)
        #expect(groceries.allSatisfy { $0.category == .foodGrocery })
    }

    // MARK: - fetchRecent

    @Test func fetchRecentRespectsLimit() throws {
        let (_, repo) = makeRepo()
        try repo.save((1...10).map { makeTx(on: date(2026, 4, $0)) })
        let recent = try repo.fetchRecent(limit: 3)
        #expect(recent.count == 3)
    }

    // MARK: - Count

    @Test func countReturnsCorrectNumber() throws {
        let (_, repo) = makeRepo()
        #expect(try repo.count() == 0)
        try repo.save([makeTx(on: date(2026, 4, 1)), makeTx(on: date(2026, 4, 2))])
        #expect(try repo.count() == 2)
    }

    // MARK: - Delete

    @Test func deleteRemovesTransaction() throws {
        let (_, repo) = makeRepo()
        let tx = makeTx(on: date(2026, 4, 1))
        try repo.save(tx)
        #expect(try repo.count() == 1)
        try repo.delete(id: tx.id)
        #expect(try repo.count() == 0)
    }

    @Test func deleteNonExistentIsNoOp() throws {
        let (_, repo) = makeRepo()
        try repo.save(makeTx(on: date(2026, 4, 1)))
        try repo.delete(id: UUID())    // UUID inexistent
        #expect(try repo.count() == 1)
    }

    // MARK: - Upsert

    @Test func upsertInsertsNewTransaction() throws {
        let (_, repo) = makeRepo()
        let tx = makeTx(amount: 200, on: date(2026, 4, 1))
        try repo.upsert(tx)
        #expect(try repo.count() == 1)
    }

    @Test func upsertUpdatesExistingTransaction() throws {
        let (_, repo) = makeRepo()
        let id = UUID()
        let original = Transaction(id: id, date: date(2026, 4, 1),
                                   amount: 200, direction: .outgoing,
                                   category: .foodGrocery, source: .csvImport)
        try repo.upsert(original)

        let updated = Transaction(id: id, date: date(2026, 4, 1),
                                  amount: 350, direction: .outgoing,
                                  category: .foodGrocery, source: .csvImport)
        try repo.upsert(updated)

        let all = try repo.fetchAll()
        #expect(all.count == 1)
        #expect(all[0].amount == Money(350))
    }

    // MARK: - Domain roundtrip

    @Test func allFieldsRoundtripThroughCoreData() throws {
        let (_, repo) = makeRepo()
        let tx = Transaction(
            date: date(2026, 4, 15),
            amount: Money(1_234),
            direction: .incoming,
            category: .savings,
            merchant: "AngajatorSRL",
            description: "Salariu aprilie",
            source: .emailParsed,
            categorizationConfidence: 0.97
        )
        try repo.save(tx)
        let fetched = try repo.fetchAll().first!
        #expect(fetched.id == tx.id)
        #expect(fetched.amount == Money(1_234))
        #expect(fetched.direction == .incoming)
        #expect(fetched.category == .savings)
        #expect(fetched.merchant == "AngajatorSRL")
        #expect(fetched.description == "Salariu aprilie")
        #expect(fetched.source == .emailParsed)
        #expect(abs(fetched.categorizationConfidence - 0.97) < 0.001)
    }
}
