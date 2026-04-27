import Foundation
import CoreData
import SolomonCore

// MARK: - Protocol

@MainActor
public protocol ObligationRepository {
    func save(_ obligation: Obligation) throws
    func save(_ obligations: [Obligation]) throws
    func upsert(_ obligation: Obligation) throws
    func delete(id: UUID) throws
    func fetchAll() throws -> [Obligation]
    func fetch(kind: ObligationKind) throws -> [Obligation]
    func fetchDebts() throws -> [Obligation]
    func count() throws -> Int
}

// MARK: - Core Data implementation

@MainActor
public final class CoreDataObligationRepository: ObligationRepository {

    private let context: NSManagedObjectContext

    public init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Write

    public func save(_ obligation: Obligation) throws {
        let obj = CDObligation(context: context)
        obj.populate(from: obligation)
        try context.save()
    }

    public func save(_ obligations: [Obligation]) throws {
        for ob in obligations {
            let obj = CDObligation(context: context)
            obj.populate(from: ob)
        }
        try context.save()
    }

    public func upsert(_ obligation: Obligation) throws {
        let req = CDObligation.fetchRequest()
        req.predicate = NSPredicate(format: "id == %@", obligation.id as CVarArg)
        req.fetchLimit = 1
        let existing = try context.fetch(req).first
        let obj = existing ?? CDObligation(context: context)
        obj.populate(from: obligation)
        try context.save()
    }

    public func delete(id: UUID) throws {
        let req = CDObligation.fetchRequest()
        req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        let results = try context.fetch(req)
        results.forEach { context.delete($0) }
        if !results.isEmpty { try context.save() }
    }

    // MARK: - Read

    public func fetchAll() throws -> [Obligation] {
        let req = CDObligation.fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(key: "dayOfMonth", ascending: true)]
        return try context.fetch(req).compactMap { $0.toDomain() }
    }

    public func fetch(kind: ObligationKind) throws -> [Obligation] {
        let req = CDObligation.fetchRequest()
        req.predicate = NSPredicate(format: "kindRaw == %@", kind.rawValue)
        req.sortDescriptors = [NSSortDescriptor(key: "dayOfMonth", ascending: true)]
        return try context.fetch(req).compactMap { $0.toDomain() }
    }

    /// Returnează obligațiile care sunt „datorii" (credit, IFN, BNPL).
    public func fetchDebts() throws -> [Obligation] {
        let debtKinds = [ObligationKind.loanBank, .loanIFN, .bnpl].map(\.rawValue)
        let req = CDObligation.fetchRequest()
        req.predicate = NSPredicate(format: "kindRaw IN %@", debtKinds)
        req.sortDescriptors = [NSSortDescriptor(key: "amountRON", ascending: false)]
        return try context.fetch(req).compactMap { $0.toDomain() }
    }

    public func count() throws -> Int {
        try context.count(for: CDObligation.fetchRequest())
    }
}
