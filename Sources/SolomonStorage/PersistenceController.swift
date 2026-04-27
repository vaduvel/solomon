import Foundation
import CoreData

/// Stiva Core Data Solomon — model definit programatic (fără `.xcdatamodeld`),
/// compatibil nativ cu Swift Package Manager.
///
/// - `shared`      : instanța principală, persistent pe disk (SQLite)
/// - `makeInMemory()` : instanță in-memory pentru unit-teste
///
/// Toate repository-urile sunt `@MainActor` și folosesc `viewContext`.
/// Pe viitor, operațiunile de batch import din email vor folosi
/// `newBackgroundContext()` cu mergePolicy corespunzătoare.
public final class SolomonPersistenceController: @unchecked Sendable {

    // MARK: - Singleton / factory

    public static let shared = SolomonPersistenceController()

    public static func makeInMemory() -> SolomonPersistenceController {
        SolomonPersistenceController(inMemory: true)
    }

    // MARK: - Container

    /// Modelul este singleton pentru a evita eroarea
    /// "Multiple NSEntityDescriptions claim the same NSManagedObject subclass"
    /// la crearea mai multor containere (common în unit tests).
    // nonisolated(unsafe): NSManagedObjectModel nu este Sendable, dar e tratată
    // ca read-only după prima inițializare lazy — thread-safe în practică.
    public nonisolated(unsafe) static let sharedModel: NSManagedObjectModel = makeModel()

    public let container: NSPersistentContainer

    public init(inMemory: Bool = false) {
        let c = NSPersistentContainer(name: "Solomon", managedObjectModel: Self.sharedModel)
        if inMemory {
            let desc = NSPersistentStoreDescription()
            desc.url = URL(fileURLWithPath: "/dev/null")
            desc.type = NSInMemoryStoreType
            c.persistentStoreDescriptions = [desc]
        }
        var loadError: Error?
        c.loadPersistentStores { _, error in loadError = error }
        if let error = loadError {
            fatalError("Solomon Core Data failed to load: \(error)")
        }
        c.viewContext.automaticallyMergesChangesFromParent = true
        c.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        self.container = c
    }

    // MARK: - Programmatic model

    static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        model.entities = [
            makeTransactionEntity(),
            makeObligationEntity(),
            makeSubscriptionEntity(),
            makeGoalEntity(),
            makeUserProfileEntity()
        ]
        return model
    }

    // MARK: - Entity builders

    private static func makeTransactionEntity() -> NSEntityDescription {
        let e = NSEntityDescription()
        e.name = "CDTransaction"
        e.managedObjectClassName = "SolomonStorage.CDTransaction"
        e.properties = [
            attr("id",                        .UUIDAttributeType),
            attr("date",                      .dateAttributeType),
            attr("amountRON",                 .integer64AttributeType),
            attr("directionRaw",              .stringAttributeType),
            attr("categoryRaw",               .stringAttributeType),
            attr("merchant",                  .stringAttributeType,  optional: true),
            attr("txDescription",             .stringAttributeType,  optional: true),
            attr("sourceRaw",                 .stringAttributeType),
            attr("categorizationConfidence",  .doubleAttributeType,  defaultValue: 1.0)
        ]
        let idxElem = NSFetchIndexElementDescription(
            property: e.propertiesByName["date"]!,
            collationType: .binary
        )
        idxElem.isAscending = false
        e.indexes = [NSFetchIndexDescription(name: "byDate", elements: [idxElem])]
        return e
    }

    private static func makeObligationEntity() -> NSEntityDescription {
        let e = NSEntityDescription()
        e.name = "CDObligation"
        e.managedObjectClassName = "SolomonStorage.CDObligation"
        e.properties = [
            attr("id",            .UUIDAttributeType),
            attr("name",          .stringAttributeType),
            attr("amountRON",     .integer64AttributeType),
            attr("dayOfMonth",    .integer16AttributeType),
            attr("kindRaw",       .stringAttributeType),
            attr("confidenceRaw", .stringAttributeType),
            attr("since",         .dateAttributeType,    optional: true),
            attr("nextDueDate",   .dateAttributeType,    optional: true)
        ]
        return e
    }

    private static func makeSubscriptionEntity() -> NSEntityDescription {
        let e = NSEntityDescription()
        e.name = "CDSubscription"
        e.managedObjectClassName = "SolomonStorage.CDSubscription"
        e.properties = [
            attr("id",                        .UUIDAttributeType),
            attr("name",                      .stringAttributeType),
            attr("amountMonthlyRON",          .integer64AttributeType),
            attr("lastUsedDaysAgoValue",      .integer32AttributeType, optional: true),
            attr("cancellationDifficultyRaw", .stringAttributeType,   defaultValue: "medium"),
            attr("cancellationUrl",           .stringAttributeType,   optional: true),
            attr("cancellationStepsSummary",  .stringAttributeType,   optional: true),
            attr("alternativeSuggestion",     .stringAttributeType,   optional: true),
            attr("cancellationWarning",       .stringAttributeType,   optional: true)
        ]
        return e
    }

    private static func makeGoalEntity() -> NSEntityDescription {
        let e = NSEntityDescription()
        e.name = "CDGoal"
        e.managedObjectClassName = "SolomonStorage.CDGoal"
        e.properties = [
            attr("id",              .UUIDAttributeType),
            attr("kindRaw",         .stringAttributeType),
            attr("destination",     .stringAttributeType,  optional: true),
            attr("amountTargetRON", .integer64AttributeType),
            attr("amountSavedRON",  .integer64AttributeType, defaultValue: 0),
            attr("deadline",        .dateAttributeType)
        ]
        return e
    }

    private static func makeUserProfileEntity() -> NSEntityDescription {
        let e = NSEntityDescription()
        e.name = "CDUserProfile"
        e.managedObjectClassName = "SolomonStorage.CDUserProfile"
        e.properties = [
            attr("name",                 .stringAttributeType),
            attr("addressingRaw",        .stringAttributeType,   defaultValue: "tu"),
            attr("ageRangeRaw",          .stringAttributeType),
            attr("salaryRangeRaw",       .stringAttributeType),
            attr("salaryFreqType",       .stringAttributeType,   defaultValue: "variable"),
            attr("salaryFreqDay1",       .integer16AttributeType, defaultValue: 0),
            attr("salaryFreqDay2",       .integer16AttributeType, defaultValue: 0),
            attr("hasSecondaryIncome",   .booleanAttributeType,  defaultValue: false),
            attr("secondaryIncomeRON",   .integer64AttributeType, optional: true),
            attr("primaryBankRaw",       .stringAttributeType),
            attr("emailAccessGranted",   .booleanAttributeType,  defaultValue: false),
            attr("notificationsGranted", .booleanAttributeType,  defaultValue: false),
            attr("datasetOptIn",         .booleanAttributeType,  defaultValue: false),
            attr("onboardingComplete",   .booleanAttributeType,  defaultValue: false),
            attr("createdAt",            .dateAttributeType)
        ]
        return e
    }

    // MARK: - Helper

    private static func attr(
        _ name: String,
        _ type: NSAttributeType,
        optional: Bool = false,
        defaultValue: Any? = nil
    ) -> NSAttributeDescription {
        let a = NSAttributeDescription()
        a.name = name
        a.attributeType = type
        a.isOptional = optional
        a.defaultValue = defaultValue
        return a
    }
}
