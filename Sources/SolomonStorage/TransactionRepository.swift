import Foundation
import CoreData
import SolomonCore

// MARK: - Protocol

/// Contract pentru accesul la tranzacții — permite mock-uri în teste de rang superior.
@MainActor
public protocol TransactionRepository {
    /// Salvează (insert) o singură tranzacție.
    func save(_ transaction: Transaction) throws
    /// Salvează un batch de tranzacții într-un singur `context.save()`.
    func save(_ transactions: [Transaction]) throws
    /// Upsert: actualizează dacă `id`-ul există, inserează dacă nu.
    func upsert(_ transaction: Transaction) throws
    /// Șterge tranzacția cu `id`-ul dat (no-op dacă nu există).
    func delete(id: UUID) throws
    /// Returnează toate tranzacțiile, sortate descrescător după dată.
    func fetchAll() throws -> [Transaction]
    /// Returnează tranzacțiile dintr-un interval de date (ambele capete inclusive).
    func fetch(from startDate: Date, to endDate: Date) throws -> [Transaction]
    /// Returnează tranzacțiile dintr-o categorie, sortate descrescător după dată.
    func fetch(category: TransactionCategory) throws -> [Transaction]
    /// Returnează cele mai recente `limit` tranzacții.
    func fetchRecent(limit: Int) throws -> [Transaction]
    /// Numărul total de tranzacții stocate.
    func count() throws -> Int
}

// MARK: - Core Data implementation

@MainActor
public final class CoreDataTransactionRepository: TransactionRepository {

    private let context: NSManagedObjectContext

    public init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Write

    public func save(_ transaction: Transaction) throws {
        let obj = CDTransaction(context: context)
        obj.populate(from: transaction)
        try context.save()
    }

    public func save(_ transactions: [Transaction]) throws {
        for tx in transactions {
            let obj = CDTransaction(context: context)
            obj.populate(from: tx)
        }
        try context.save()
    }

    public func upsert(_ transaction: Transaction) throws {
        let req = CDTransaction.fetchRequest()
        req.predicate = NSPredicate(format: "id == %@", transaction.id as CVarArg)
        req.fetchLimit = 1
        let existing = try context.fetch(req).first
        let obj = existing ?? CDTransaction(context: context)
        obj.populate(from: transaction)
        try context.save()
    }

    public func delete(id: UUID) throws {
        let req = CDTransaction.fetchRequest()
        req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        let results = try context.fetch(req)
        results.forEach { context.delete($0) }
        if !results.isEmpty { try context.save() }
    }

    // MARK: - Read

    public func fetchAll() throws -> [Transaction] {
        let req = CDTransaction.fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        return try context.fetch(req).compactMap { $0.toDomain() }
    }

    public func fetch(from startDate: Date, to endDate: Date) throws -> [Transaction] {
        let req = CDTransaction.fetchRequest()
        req.predicate = NSPredicate(format: "date >= %@ AND date <= %@",
                                    startDate as CVarArg, endDate as CVarArg)
        req.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        return try context.fetch(req).compactMap { $0.toDomain() }
    }

    public func fetch(category: TransactionCategory) throws -> [Transaction] {
        let req = CDTransaction.fetchRequest()
        req.predicate = NSPredicate(format: "categoryRaw == %@", category.rawValue)
        req.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        return try context.fetch(req).compactMap { $0.toDomain() }
    }

    public func fetchRecent(limit: Int) throws -> [Transaction] {
        let req = CDTransaction.fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        req.fetchLimit = limit
        return try context.fetch(req).compactMap { $0.toDomain() }
    }

    public func count() throws -> Int {
        let req = CDTransaction.fetchRequest()
        return try context.count(for: req)
    }
}
