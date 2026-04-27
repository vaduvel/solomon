import Foundation
import CoreData
import SolomonCore

// MARK: - CDSubscription

@objc(CDSubscription)
final class CDSubscription: NSManagedObject {

    @NSManaged var id: UUID
    @NSManaged var name: String
    @NSManaged var amountMonthlyRON: Int64
    /// `NSNumber?` deoarece Core Data nu suportă opționale pentru tipuri scalare.
    /// `nil` înseamnă „nu avem semnal de utilizare".
    @NSManaged var lastUsedDaysAgoValue: NSNumber?
    @NSManaged var cancellationDifficultyRaw: String
    @NSManaged var cancellationUrl: String?
    @NSManaged var cancellationStepsSummary: String?
    @NSManaged var alternativeSuggestion: String?
    @NSManaged var cancellationWarning: String?

    // MARK: - Fetch request

    @nonobjc static func fetchRequest() -> NSFetchRequest<CDSubscription> {
        NSFetchRequest<CDSubscription>(entityName: "CDSubscription")
    }

    // MARK: - Domain conversion

    func populate(from sub: Subscription) {
        id = sub.id
        name = sub.name
        amountMonthlyRON = Int64(sub.amountMonthly.amount)
        lastUsedDaysAgoValue = sub.lastUsedDaysAgo.map { NSNumber(value: $0) }
        cancellationDifficultyRaw = sub.cancellationDifficulty.rawValue
        cancellationUrl = sub.cancellationUrl?.absoluteString
        cancellationStepsSummary = sub.cancellationStepsSummary
        alternativeSuggestion = sub.alternativeSuggestion
        cancellationWarning = sub.cancellationWarning
    }

    func toDomain() -> Subscription? {
        guard
            let difficulty = CancellationDifficulty(rawValue: cancellationDifficultyRaw)
        else { return nil }

        let cancelUrl: URL? = cancellationUrl.flatMap { URL(string: $0) }
        let daysAgo: Int? = lastUsedDaysAgoValue.map { Int(truncating: $0) }

        return Subscription(
            id: id,
            name: name,
            amountMonthly: Money(Int(amountMonthlyRON)),
            lastUsedDaysAgo: daysAgo,
            cancellationDifficulty: difficulty,
            cancellationUrl: cancelUrl,
            cancellationStepsSummary: cancellationStepsSummary,
            alternativeSuggestion: alternativeSuggestion,
            cancellationWarning: cancellationWarning
        )
    }
}
