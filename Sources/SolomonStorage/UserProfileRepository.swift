import Foundation
import CoreData
import SolomonCore

// MARK: - Protocol

@MainActor
public protocol UserProfileRepository {
    /// Salvează (upsert) profilul — înlocuiește dacă există, inserează dacă nu.
    func saveProfile(_ profile: UserProfile) throws
    /// Actualizează câmpurile de consimțământ fără să atingă profilul.
    func saveConsent(_ consent: UserConsent) throws
    /// Returnează profilul utilizatorului, sau `nil` dacă onboardingul nu a fost completat.
    func fetchProfile() throws -> UserProfile?
    /// Returnează starea consimțămintelor.
    func fetchConsent() throws -> UserConsent?
    /// Returnează data creării contului Solomon al utilizatorului.
    func fetchCreatedAt() throws -> Date?
    /// Șterge tot profilul (ex: la logout / ștergere cont).
    func deleteProfile() throws
}

// MARK: - Core Data implementation

@MainActor
public final class CoreDataUserProfileRepository: UserProfileRepository {

    private let context: NSManagedObjectContext

    public init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Write

    public func saveProfile(_ profile: UserProfile) throws {
        let obj = try fetchOrCreateSingleton()
        obj.populateProfile(from: profile)
        try context.save()
    }

    public func saveConsent(_ consent: UserConsent) throws {
        let obj = try fetchOrCreateSingleton()
        obj.populateConsent(from: consent)
        try context.save()
    }

    // MARK: - Read

    public func fetchProfile() throws -> UserProfile? {
        try fetchSingleton()?.toDomainProfile()
    }

    public func fetchConsent() throws -> UserConsent? {
        try fetchSingleton().map { $0.toDomainConsent() }
    }

    public func fetchCreatedAt() throws -> Date? {
        try fetchSingleton()?.createdAt
    }

    // MARK: - Delete

    public func deleteProfile() throws {
        let req = CDUserProfile.fetchRequest()
        let results = try context.fetch(req)
        results.forEach { context.delete($0) }
        if !results.isEmpty { try context.save() }
    }

    // MARK: - Private helpers

    private func fetchSingleton() throws -> CDUserProfile? {
        let req = CDUserProfile.fetchRequest()
        req.fetchLimit = 1
        return try context.fetch(req).first
    }

    /// Returnează entitatea existentă sau creează una nouă cu toate câmpurile
    /// required inițializate la valori implicite valide pentru Core Data validation.
    private func fetchOrCreateSingleton() throws -> CDUserProfile {
        if let existing = try fetchSingleton() { return existing }
        let obj = CDUserProfile(context: context)
        obj.createdAt = Date()
        // Profile fields — default-uri neutre; vor fi suprascrișe de saveProfile
        obj.name = ""
        obj.addressingRaw = Addressing.tu.rawValue
        obj.ageRangeRaw = AgeRange.range25to35.rawValue
        obj.salaryRangeRaw = SalaryRange.range3to5.rawValue
        obj.salaryFreqType = "variable"
        obj.salaryFreqDay1 = 0
        obj.salaryFreqDay2 = 0
        obj.hasSecondaryIncome = false
        obj.secondaryIncomeRON = nil
        obj.primaryBankRaw = Bank.other.rawValue
        // Consent fields
        obj.emailAccessGranted = false
        obj.notificationsGranted = false
        obj.datasetOptIn = false
        obj.onboardingComplete = false
        return obj
    }
}
