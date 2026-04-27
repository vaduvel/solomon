import Foundation
import CoreData
import SolomonCore

// MARK: - Protocol

@MainActor
public protocol SubscriptionRepository {
    func save(_ subscription: Subscription) throws
    func save(_ subscriptions: [Subscription]) throws
    func upsert(_ subscription: Subscription) throws
    func delete(id: UUID) throws
    func fetchAll() throws -> [Subscription]
    func fetchGhosts() throws -> [Subscription]
    func count() throws -> Int
}

// MARK: - Core Data implementation

@MainActor
public final class CoreDataSubscriptionRepository: SubscriptionRepository {

    private let context: NSManagedObjectContext

    public init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Write

    public func save(_ subscription: Subscription) throws {
        let obj = CDSubscription(context: context)
        obj.populate(from: subscription)
        try context.save()
    }

    public func save(_ subscriptions: [Subscription]) throws {
        for sub in subscriptions {
            let obj = CDSubscription(context: context)
            obj.populate(from: sub)
        }
        try context.save()
    }

    public func upsert(_ subscription: Subscription) throws {
        let req = CDSubscription.fetchRequest()
        req.predicate = NSPredicate(format: "id == %@", subscription.id as CVarArg)
        req.fetchLimit = 1
        let existing = try context.fetch(req).first
        let obj = existing ?? CDSubscription(context: context)
        obj.populate(from: subscription)
        try context.save()
    }

    public func delete(id: UUID) throws {
        let req = CDSubscription.fetchRequest()
        req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        let results = try context.fetch(req)
        results.forEach { context.delete($0) }
        if !results.isEmpty { try context.save() }
    }

    // MARK: - Read

    public func fetchAll() throws -> [Subscription] {
        let req = CDSubscription.fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(key: "amountMonthlyRON", ascending: false)]
        return try context.fetch(req).compactMap { $0.toDomain() }
    }

    /// Returnează abonamentele „ghost" (>30 zile fără utilizare), ordonate descrescător
    /// după cost lunar.
    public func fetchGhosts() throws -> [Subscription] {
        let req = CDSubscription.fetchRequest()
        // lastUsedDaysAgoValue > 30 AND lastUsedDaysAgoValue != nil
        req.predicate = NSPredicate(format: "lastUsedDaysAgoValue != nil AND lastUsedDaysAgoValue > 30")
        req.sortDescriptors = [NSSortDescriptor(key: "amountMonthlyRON", ascending: false)]
        return try context.fetch(req).compactMap { $0.toDomain() }
    }

    public func count() throws -> Int {
        try context.count(for: CDSubscription.fetchRequest())
    }
}
