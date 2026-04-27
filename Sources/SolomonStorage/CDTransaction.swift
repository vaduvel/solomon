import Foundation
import CoreData
import SolomonCore

// MARK: - CDTransaction

/// NSManagedObject pentru entitatea `CDTransaction`.
/// Intern modulului — codul consumator vede numai `Transaction` (value type).
@objc(CDTransaction)
final class CDTransaction: NSManagedObject {

    @NSManaged var id: UUID
    @NSManaged var date: Date
    @NSManaged var amountRON: Int64
    @NSManaged var directionRaw: String
    @NSManaged var categoryRaw: String
    @NSManaged var merchant: String?
    @NSManaged var txDescription: String?
    @NSManaged var sourceRaw: String
    @NSManaged var categorizationConfidence: Double

    // MARK: - Fetch request

    @nonobjc static func fetchRequest() -> NSFetchRequest<CDTransaction> {
        NSFetchRequest<CDTransaction>(entityName: "CDTransaction")
    }

    // MARK: - Domain conversion

    /// Populează obiectul Core Data dintr-un `Transaction` value type.
    func populate(from tx: Transaction) {
        id = tx.id
        date = tx.date
        amountRON = Int64(tx.amount.amount)
        directionRaw = tx.direction.rawValue
        categoryRaw = tx.category.rawValue
        merchant = tx.merchant
        txDescription = tx.description
        sourceRaw = tx.source.rawValue
        categorizationConfidence = tx.categorizationConfidence
    }

    /// Converteste obiectul Core Data înapoi în `Transaction` value type.
    func toDomain() -> Transaction? {
        guard
            let direction = FlowDirection(rawValue: directionRaw),
            let category  = TransactionCategory(rawValue: categoryRaw),
            let source    = TransactionSource(rawValue: sourceRaw)
        else { return nil }

        return Transaction(
            id: id,
            date: date,
            amount: Money(Int(amountRON)),
            direction: direction,
            category: category,
            merchant: merchant,
            description: txDescription,
            source: source,
            categorizationConfidence: categorizationConfidence
        )
    }
}
