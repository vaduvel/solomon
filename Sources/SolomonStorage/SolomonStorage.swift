import Foundation
import SolomonCore

/// Namespace marker pentru modulul `SolomonStorage`.
///
/// Modulul expune:
/// - `SolomonPersistenceController` — container Core Data cu model programatic
/// - 5 repository-uri (`@MainActor`) pentru cele 5 entități principale:
///   - `CoreDataTransactionRepository`
///   - `CoreDataObligationRepository`
///   - `CoreDataSubscriptionRepository`
///   - `CoreDataGoalRepository`
///   - `CoreDataUserProfileRepository`
/// - `UserConsent` — starea consimțămintelor separată de `UserProfile`
///
/// Schema versiune 1 — nicio migrare necesară până la v2.
public enum SolomonStorage {
    public static let moduleVersion = "1.0.0"
    public static let schemaVersion = 1
}
