import Foundation
import CoreData
import os

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
        } else {
            // Activăm migrare automată — esențial când schema evoluează între versiuni.
            // Fără aceste opțiuni, orice atribut nou adăugat corupe store-ul existent.
            if let desc = c.persistentStoreDescriptions.first {
                desc.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
                desc.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
            }
        }

        var loadError: Error?
        c.loadPersistentStores { _, error in loadError = error }

        if let error = loadError {
            // FAZA B2: Migrarea automată a eșuat — păstrăm un BACKUP înainte să
            // ștergem store-ul, ca să recuperabil datele financiare istorice
            // (manual din Files dacă e nevoie). Apoi facem fallback la reset.
            let logger = Logger(subsystem: "ro.solomon.app", category: "Persistence")
            logger.error("CoreData store load failed: \(error.localizedDescription, privacy: .public). Backing up + recreating store.")

            if let storeURL = c.persistentStoreDescriptions.first?.url {
                Self.backupCorruptedStore(at: storeURL, logger: logger)
                let base = storeURL.deletingLastPathComponent()
                let name = storeURL.deletingPathExtension().lastPathComponent
                for ext in ["sqlite", "sqlite-shm", "sqlite-wal"] {
                    let fileURL = base.appendingPathComponent("\(name).\(ext)")
                    do {
                        if FileManager.default.fileExists(atPath: fileURL.path) {
                            try FileManager.default.removeItem(at: fileURL)
                        }
                    } catch {
                        logger.error("Failed to remove store file \(fileURL.lastPathComponent, privacy: .public): \(error.localizedDescription, privacy: .public)")
                    }
                }
            }
            c.loadPersistentStores { _, retryError in
                if let retryError {
                    fatalError("Solomon CoreData unrecoverable after reset: \(retryError)")
                }
            }
        }

        c.viewContext.automaticallyMergesChangesFromParent = true
        c.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        self.container = c
    }

    // MARK: - Backup helper (FAZA B2)

    /// Copiază fișierele SQLite ale unui store corupt într-un folder de backup
    /// timestamped, înainte de delete-on-fail. Permite recuperare manuală a datelor
    /// financiare istorice (export din Files / Finder pe Mac).
    ///
    /// Backupurile sunt stocate în `Application Support/Solomon/CorruptStoreBackups/<timestamp>/`.
    private static func backupCorruptedStore(at storeURL: URL, logger: Logger) {
        let base = storeURL.deletingLastPathComponent()
        let storeName = storeURL.deletingPathExtension().lastPathComponent
        let fm = FileManager.default

        do {
            let appSupport = try fm.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let timestamp = ISO8601DateFormatter().string(from: Date())
                .replacingOccurrences(of: ":", with: "-")
            let backupDir = appSupport
                .appendingPathComponent("Solomon", isDirectory: true)
                .appendingPathComponent("CorruptStoreBackups", isDirectory: true)
                .appendingPathComponent(timestamp, isDirectory: true)
            try fm.createDirectory(at: backupDir, withIntermediateDirectories: true)

            for ext in ["sqlite", "sqlite-shm", "sqlite-wal"] {
                let src = base.appendingPathComponent("\(storeName).\(ext)")
                if fm.fileExists(atPath: src.path) {
                    let dst = backupDir.appendingPathComponent("\(storeName).\(ext)")
                    try fm.copyItem(at: src, to: dst)
                }
            }

            // Limităm la cel mult 5 backupuri ca să nu umflăm disk-ul user-ului
            Self.pruneOldBackups(in: backupDir.deletingLastPathComponent(), keep: 5, logger: logger)

            logger.notice("Backup corrupt store created at \(backupDir.path, privacy: .public)")
        } catch {
            logger.error("Backup of corrupt store FAILED: \(error.localizedDescription, privacy: .public). Proceeding with reset (data loss).")
        }
    }

    private static func pruneOldBackups(in dir: URL, keep: Int, logger: Logger) {
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.creationDateKey]) else { return }
        let sorted = contents.sorted { lhs, rhs in
            let lDate = (try? lhs.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            let rDate = (try? rhs.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            return lDate > rDate   // newest first
        }
        if sorted.count > keep {
            for url in sorted.dropFirst(keep) {
                try? fm.removeItem(at: url)
            }
        }
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
