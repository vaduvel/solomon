import Foundation
import CoreData
import SolomonCore

// MARK: - Protocol

@MainActor
public protocol GoalRepository {
    func save(_ goal: Goal) throws
    func save(_ goals: [Goal]) throws
    func upsert(_ goal: Goal) throws
    func delete(id: UUID) throws
    func fetchAll() throws -> [Goal]
    /// Returnează obiectivele care nu sunt încă atinse.
    func fetchActive() throws -> [Goal]
    func count() throws -> Int
}

// MARK: - Core Data implementation

@MainActor
public final class CoreDataGoalRepository: GoalRepository {

    private let context: NSManagedObjectContext

    public init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Write

    public func save(_ goal: Goal) throws {
        let obj = CDGoal(context: context)
        obj.populate(from: goal)
        try context.save()
    }

    public func save(_ goals: [Goal]) throws {
        for goal in goals {
            let obj = CDGoal(context: context)
            obj.populate(from: goal)
        }
        try context.save()
    }

    public func upsert(_ goal: Goal) throws {
        let req = CDGoal.fetchRequest()
        req.predicate = NSPredicate(format: "id == %@", goal.id as CVarArg)
        req.fetchLimit = 1
        let existing = try context.fetch(req).first
        let obj = existing ?? CDGoal(context: context)
        obj.populate(from: goal)
        try context.save()
    }

    public func delete(id: UUID) throws {
        let req = CDGoal.fetchRequest()
        req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        let results = try context.fetch(req)
        results.forEach { context.delete($0) }
        if !results.isEmpty { try context.save() }
    }

    // MARK: - Read

    public func fetchAll() throws -> [Goal] {
        let req = CDGoal.fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(key: "deadline", ascending: true)]
        return try context.fetch(req).compactMap { $0.toDomain() }
    }

    /// Returnează obiectivele la care `amountSavedRON < amountTargetRON`.
    public func fetchActive() throws -> [Goal] {
        let req = CDGoal.fetchRequest()
        req.predicate = NSPredicate(format: "amountSavedRON < amountTargetRON")
        req.sortDescriptors = [NSSortDescriptor(key: "deadline", ascending: true)]
        return try context.fetch(req).compactMap { $0.toDomain() }
    }

    public func count() throws -> Int {
        try context.count(for: CDGoal.fetchRequest())
    }
}
