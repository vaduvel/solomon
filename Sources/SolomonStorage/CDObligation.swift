import Foundation
import CoreData
import SolomonCore

// MARK: - CDObligation

@objc(CDObligation)
final class CDObligation: NSManagedObject {

    @NSManaged var id: UUID
    @NSManaged var name: String
    @NSManaged var amountRON: Int64
    @NSManaged var dayOfMonth: Int16
    @NSManaged var kindRaw: String
    @NSManaged var confidenceRaw: String
    @NSManaged var since: Date?
    @NSManaged var nextDueDate: Date?

    // MARK: - Fetch request

    @nonobjc static func fetchRequest() -> NSFetchRequest<CDObligation> {
        NSFetchRequest<CDObligation>(entityName: "CDObligation")
    }

    // MARK: - Domain conversion

    func populate(from ob: Obligation) {
        id = ob.id
        name = ob.name
        amountRON = Int64(ob.amount.amount)
        dayOfMonth = Int16(ob.dayOfMonth)
        kindRaw = ob.kind.rawValue
        confidenceRaw = ob.confidence.rawValue
        since = ob.since
        nextDueDate = ob.nextDueDate
    }

    func toDomain() -> Obligation? {
        guard
            let kind       = ObligationKind(rawValue: kindRaw),
            let confidence = ObligationConfidence(rawValue: confidenceRaw),
            (1...31).contains(Int(dayOfMonth))
        else { return nil }

        return Obligation(
            id: id,
            name: name,
            amount: Money(Int(amountRON)),
            dayOfMonth: Int(dayOfMonth),
            kind: kind,
            confidence: confidence,
            since: since,
            nextDueDate: nextDueDate
        )
    }
}
