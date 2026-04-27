import Foundation
import CoreData
import SolomonCore

// MARK: - CDGoal

@objc(CDGoal)
final class CDGoal: NSManagedObject {

    @NSManaged var id: UUID
    @NSManaged var kindRaw: String
    @NSManaged var destination: String?
    @NSManaged var amountTargetRON: Int64
    @NSManaged var amountSavedRON: Int64
    @NSManaged var deadline: Date

    // MARK: - Fetch request

    @nonobjc static func fetchRequest() -> NSFetchRequest<CDGoal> {
        NSFetchRequest<CDGoal>(entityName: "CDGoal")
    }

    // MARK: - Domain conversion

    func populate(from goal: Goal) {
        id = goal.id
        kindRaw = goal.kind.rawValue
        destination = goal.destination
        amountTargetRON = Int64(goal.amountTarget.amount)
        amountSavedRON = Int64(goal.amountSaved.amount)
        deadline = goal.deadline
    }

    func toDomain() -> Goal? {
        guard
            let kind = GoalKind(rawValue: kindRaw),
            amountTargetRON > 0
        else { return nil }

        return Goal(
            id: id,
            kind: kind,
            destination: destination,
            amountTarget: Money(Int(amountTargetRON)),
            amountSaved: Money(Int(amountSavedRON)),
            deadline: deadline
        )
    }
}
