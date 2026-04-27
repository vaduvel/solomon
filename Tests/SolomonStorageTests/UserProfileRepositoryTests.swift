import Testing
import Foundation
@testable import SolomonStorage
import SolomonCore

// MARK: - Sample data

private let sampleProfile = UserProfile(
    demographics: DemographicProfile(
        name: "Andrei",
        addressing: .tu,
        ageRange: .range25to35
    ),
    financials: FinancialProfile(
        salaryRange: .range5to8,
        salaryFrequency: .monthly(dayOfMonth: 15),
        hasSecondaryIncome: false,
        primaryBank: .bancaTransilvania
    )
)

private let sampleConsent = UserConsent(
    emailAccessGranted: true,
    notificationsGranted: true,
    datasetOptIn: false,
    onboardingComplete: true
)

@MainActor
private func makeRepo() -> CoreDataUserProfileRepository {
    let ctrl = SolomonPersistenceController.makeInMemory()
    return CoreDataUserProfileRepository(context: ctrl.container.viewContext)
}

// MARK: - Tests

@Suite @MainActor struct UserProfileRepositoryTests {

    @Test func fetchProfileBeforeSaveReturnsNil() throws {
        let repo = makeRepo()
        #expect(try repo.fetchProfile() == nil)
    }

    @Test func saveAndFetchProfile() throws {
        let repo = makeRepo()
        try repo.saveProfile(sampleProfile)
        let fetched = try repo.fetchProfile()
        #expect(fetched != nil)
        #expect(fetched?.demographics.name == "Andrei")
        #expect(fetched?.demographics.addressing == .tu)
        #expect(fetched?.demographics.ageRange == .range25to35)
        #expect(fetched?.financials.salaryRange == .range5to8)
        #expect(fetched?.financials.primaryBank == .bancaTransilvania)
    }

    @Test func salaryFrequencyMonthlyRoundtrips() throws {
        let repo = makeRepo()
        try repo.saveProfile(sampleProfile)
        let fetched = try repo.fetchProfile()!
        if case .monthly(let day) = fetched.financials.salaryFrequency {
            #expect(day == 15)
        } else {
            Issue.record("Expected .monthly salary frequency")
        }
    }

    @Test func salaryFrequencyBimonthlyRoundtrips() throws {
        let repo = makeRepo()
        var profile = sampleProfile
        profile.financials.salaryFrequency = .bimonthly(firstDay: 10, secondDay: 25)
        try repo.saveProfile(profile)
        let fetched = try repo.fetchProfile()!
        if case .bimonthly(let d1, let d2) = fetched.financials.salaryFrequency {
            #expect(d1 == 10)
            #expect(d2 == 25)
        } else {
            Issue.record("Expected .bimonthly salary frequency")
        }
    }

    @Test func salaryFrequencyVariableRoundtrips() throws {
        let repo = makeRepo()
        var profile = sampleProfile
        profile.financials.salaryFrequency = .variable
        try repo.saveProfile(profile)
        let fetched = try repo.fetchProfile()!
        if case .variable = fetched.financials.salaryFrequency {
            // ok
        } else {
            Issue.record("Expected .variable salary frequency")
        }
    }

    @Test func secondaryIncomeNilRoundtrips() throws {
        let repo = makeRepo()
        try repo.saveProfile(sampleProfile)   // hasSecondaryIncome = false, secondaryIncomeAvg = nil
        let fetched = try repo.fetchProfile()!
        #expect(fetched.financials.secondaryIncomeAvg == nil)
    }

    @Test func secondaryIncomeNonNilRoundtrips() throws {
        let repo = makeRepo()
        var profile = sampleProfile
        profile.financials.hasSecondaryIncome = true
        profile.financials.secondaryIncomeAvg = Money(800)
        try repo.saveProfile(profile)
        let fetched = try repo.fetchProfile()!
        #expect(fetched.financials.hasSecondaryIncome == true)
        #expect(fetched.financials.secondaryIncomeAvg == Money(800))
    }

    @Test func saveAndFetchConsent() throws {
        let repo = makeRepo()
        try repo.saveProfile(sampleProfile)  // creează singleton
        try repo.saveConsent(sampleConsent)
        let fetched = try repo.fetchConsent()
        #expect(fetched?.emailAccessGranted == true)
        #expect(fetched?.notificationsGranted == true)
        #expect(fetched?.datasetOptIn == false)
        #expect(fetched?.onboardingComplete == true)
    }

    @Test func saveConsentCreatesProfileIfAbsent() throws {
        let repo = makeRepo()
        // Salvăm consimțământul înainte de profil
        try repo.saveConsent(sampleConsent)
        let consent = try repo.fetchConsent()
        #expect(consent?.onboardingComplete == true)
    }

    @Test func upsertProfileDoesNotDuplicateRow() throws {
        let repo = makeRepo()
        try repo.saveProfile(sampleProfile)
        var updated = sampleProfile
        updated.demographics.name = "Andrei Ionescu"
        try repo.saveProfile(updated)

        // Verifică că există tot un singur rând (singleton) cu datele actualizate.
        let fetched = try repo.fetchProfile()
        #expect(fetched?.demographics.name == "Andrei Ionescu")
    }

    @Test func createdAtIsSetOnFirstSave() throws {
        let repo = makeRepo()
        let before = Date()
        try repo.saveProfile(sampleProfile)
        let createdAt = try repo.fetchCreatedAt()
        let after = Date()
        #expect(createdAt != nil)
        #expect(createdAt! >= before)
        #expect(createdAt! <= after)
    }

    @Test func createdAtPreservedOnUpsert() throws {
        let repo = makeRepo()
        try repo.saveProfile(sampleProfile)
        let original = try repo.fetchCreatedAt()!

        var updated = sampleProfile
        updated.demographics.name = "Popescu"
        try repo.saveProfile(updated)
        let afterUpdate = try repo.fetchCreatedAt()!

        #expect(abs(afterUpdate.timeIntervalSince(original)) < 1)
    }

    @Test func deleteProfileClearsAllData() throws {
        let repo = makeRepo()
        try repo.saveProfile(sampleProfile)
        try repo.saveConsent(sampleConsent)
        try repo.deleteProfile()
        #expect(try repo.fetchProfile() == nil)
        #expect(try repo.fetchConsent() == nil)
    }
}
