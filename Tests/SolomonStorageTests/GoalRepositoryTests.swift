import Testing
import Foundation
@testable import SolomonStorage
import SolomonCore

private let cal = Calendar.gregorianRO

private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
    var c = DateComponents(); c.year = y; c.month = m; c.day = d
    return cal.date(from: c) ?? Date()
}

private func makeGoal(
    kind: GoalKind = .vacation,
    destination: String? = "Grecia",
    target: Int = 4_500,
    saved: Int = 0,
    deadline: Date? = nil
) -> Goal {
    Goal(kind: kind, destination: destination,
         amountTarget: Money(target), amountSaved: Money(saved),
         deadline: deadline ?? date(2026, 12, 31))
}

@MainActor
private func makeRepo() -> CoreDataGoalRepository {
    let ctrl = SolomonPersistenceController.makeInMemory()
    return CoreDataGoalRepository(context: ctrl.container.viewContext)
}

@Suite @MainActor struct GoalRepositoryTests {

    @Test func saveAndFetchAll() throws {
        let repo = makeRepo()
        let goal = makeGoal()
        try repo.save(goal)
        let all = try repo.fetchAll()
        #expect(all.count == 1)
        #expect(all[0].kind == .vacation)
    }

    @Test func fetchAllSortedByDeadlineAscending() throws {
        let repo = makeRepo()
        try repo.save([
            makeGoal(kind: .vacation,      deadline: date(2026, 12, 1)),
            makeGoal(kind: .car,           deadline: date(2027, 6, 1)),
            makeGoal(kind: .emergencyFund, deadline: date(2026, 7, 1))
        ])
        let all = try repo.fetchAll()
        #expect(all[0].kind == .emergencyFund)
        #expect(all[1].kind == .vacation)
        #expect(all[2].kind == .car)
    }

    @Test func fetchActiveExcludesReachedGoals() throws {
        let repo = makeRepo()
        try repo.save([
            makeGoal(kind: .vacation,      target: 4_500, saved: 4_500), // reached
            makeGoal(kind: .emergencyFund, target: 5_000, saved: 2_000), // active
            makeGoal(kind: .car,           target: 30_000, saved: 0)     // active
        ])
        let active = try repo.fetchActive()
        #expect(active.count == 2)
        #expect(active.allSatisfy { !$0.isReached })
    }

    @Test func deleteGoal() throws {
        let repo = makeRepo()
        let goal = makeGoal()
        try repo.save(goal)
        try repo.delete(id: goal.id)
        #expect(try repo.count() == 0)
    }

    @Test func upsertUpdatesSavedAmount() throws {
        let repo = makeRepo()
        let id = UUID()
        let original = Goal(id: id, kind: .vacation, amountTarget: Money(4_500),
                            amountSaved: Money(500), deadline: date(2026, 12, 31))
        try repo.upsert(original)

        let updated = Goal(id: id, kind: .vacation, amountTarget: Money(4_500),
                           amountSaved: Money(1_200), deadline: date(2026, 12, 31))
        try repo.upsert(updated)

        let all = try repo.fetchAll()
        #expect(all.count == 1)
        #expect(all[0].amountSaved == Money(1_200))
    }

    @Test func countReturnsCorrectNumber() throws {
        let repo = makeRepo()
        #expect(try repo.count() == 0)
        try repo.save(makeGoal())
        try repo.save(makeGoal(kind: .car, destination: nil, target: 20_000))
        #expect(try repo.count() == 2)
    }

    @Test func allFieldsRoundtripThroughCoreData() throws {
        let repo = makeRepo()
        let goal = Goal(
            kind: .vacation,
            destination: "Maldive",
            amountTarget: Money(8_000),
            amountSaved: Money(1_200),
            deadline: date(2026, 8, 15)
        )
        try repo.save(goal)
        let fetched = try repo.fetchAll().first!
        #expect(fetched.id == goal.id)
        #expect(fetched.kind == .vacation)
        #expect(fetched.destination == "Maldive")
        #expect(fetched.amountTarget == Money(8_000))
        #expect(fetched.amountSaved == Money(1_200))
        #expect(abs(fetched.deadline.timeIntervalSince(goal.deadline)) < 1)
        #expect(!fetched.isReached)
        #expect(fetched.progressFraction > 0.14 && fetched.progressFraction < 0.16)
    }
}
