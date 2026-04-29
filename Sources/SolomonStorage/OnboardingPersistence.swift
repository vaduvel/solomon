import Foundation
import CoreData
import SolomonCore

// MARK: - OnboardingPersistence
//
// FAZA A5: Salvare ATOMICĂ a profilului final după onboarding.
//
// Înainte: persistFinalProfile() apela individual saveProfile(), saveConsent(), apoi
// upsert pentru fiecare obligație — fiecare cu propriu context.save(). Dacă pica la
// jumătate (storage full, validation error pe a 3-a obligație), rămâneam cu
// profil + consent + 2 obligații salvate, restul orfane, markCompleted neapelat
// → user reia onboardingul și creează profil duplicat.
//
// Acum: TOATE schimbările sunt acumulate într-un singur context, apoi un singur
// context.save() la final. Pe error: context.rollback() șterge tot ce am acumulat
// → state-ul rămâne consistent.

@MainActor
public final class OnboardingPersistence {

    private let context: NSManagedObjectContext

    public init(context: NSManagedObjectContext) {
        self.context = context
    }

    /// Salvează profil + consent + obligații atomic, într-o singură tranzacție Core Data.
    ///
    /// - Throws: orice eroare Core Data; pe error context-ul e rollback automat.
    public func persistOnboardingFinal(
        profile: UserProfile,
        consent: UserConsent,
        obligations: [Obligation]
    ) throws {
        do {
            // 1. Profil + consent în același CDUserProfile singleton
            let profileObj = try fetchOrCreateUserProfile()
            profileObj.populateProfile(from: profile)
            profileObj.populateConsent(from: consent)

            // 2. Obligații (upsert după id)
            for obligation in obligations {
                let req = CDObligation.fetchRequest()
                req.predicate = NSPredicate(format: "id == %@", obligation.id as CVarArg)
                req.fetchLimit = 1
                let existing = try context.fetch(req).first
                let oblObj = existing ?? CDObligation(context: context)
                oblObj.populate(from: obligation)
            }

            // 3. Single atomic save — totul sau nimic
            try context.save()
        } catch {
            // Rollback toate schimbările acumulate dacă apare orice eroare
            context.rollback()
            throw error
        }
    }

    // MARK: - Private helpers (oglindă din CoreDataUserProfileRepository)

    private func fetchOrCreateUserProfile() throws -> CDUserProfile {
        let req = CDUserProfile.fetchRequest()
        req.fetchLimit = 1
        if let existing = try context.fetch(req).first {
            return existing
        }
        let obj = CDUserProfile(context: context)
        obj.createdAt = Date()
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
        obj.emailAccessGranted = false
        obj.notificationsGranted = false
        obj.datasetOptIn = false
        obj.onboardingComplete = false
        return obj
    }
}
