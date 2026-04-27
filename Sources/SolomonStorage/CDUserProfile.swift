import Foundation
import CoreData
import SolomonCore

// MARK: - UserConsent

/// Starea consimțămintelor utilizatorului. Separată de `UserProfile`
/// pentru că se actualizează independent (onboarding multi-step).
public struct UserConsent: Codable, Sendable, Hashable {
    public var emailAccessGranted: Bool
    public var notificationsGranted: Bool
    public var datasetOptIn: Bool
    public var onboardingComplete: Bool

    public init(
        emailAccessGranted: Bool = false,
        notificationsGranted: Bool = false,
        datasetOptIn: Bool = false,
        onboardingComplete: Bool = false
    ) {
        self.emailAccessGranted = emailAccessGranted
        self.notificationsGranted = notificationsGranted
        self.datasetOptIn = datasetOptIn
        self.onboardingComplete = onboardingComplete
    }
}

// MARK: - CDUserProfile

/// NSManagedObject pentru profilul utilizatorului — singleton în BD.
@objc(CDUserProfile)
final class CDUserProfile: NSManagedObject {

    // Profile fields
    @NSManaged var name: String
    @NSManaged var addressingRaw: String
    @NSManaged var ageRangeRaw: String
    @NSManaged var salaryRangeRaw: String
    @NSManaged var salaryFreqType: String       // "monthly" | "bimonthly" | "variable"
    @NSManaged var salaryFreqDay1: Int16
    @NSManaged var salaryFreqDay2: Int16
    @NSManaged var hasSecondaryIncome: Bool
    @NSManaged var secondaryIncomeRON: NSNumber? // nil = fără venit secundar
    @NSManaged var primaryBankRaw: String

    // Consent fields
    @NSManaged var emailAccessGranted: Bool
    @NSManaged var notificationsGranted: Bool
    @NSManaged var datasetOptIn: Bool
    @NSManaged var onboardingComplete: Bool

    // Metadata
    @NSManaged var createdAt: Date

    // MARK: - Fetch request

    @nonobjc static func fetchRequest() -> NSFetchRequest<CDUserProfile> {
        NSFetchRequest<CDUserProfile>(entityName: "CDUserProfile")
    }

    // MARK: - Domain conversion — profile

    func populateProfile(from profile: UserProfile) {
        name = profile.demographics.name
        addressingRaw = profile.demographics.addressing.rawValue
        ageRangeRaw = profile.demographics.ageRange.rawValue
        salaryRangeRaw = profile.financials.salaryRange.rawValue
        Self.encodeSalaryFrequency(
            profile.financials.salaryFrequency,
            typeOut: &salaryFreqType,
            day1Out: &salaryFreqDay1,
            day2Out: &salaryFreqDay2
        )
        hasSecondaryIncome = profile.financials.hasSecondaryIncome
        secondaryIncomeRON = profile.financials.secondaryIncomeAvg
            .map { NSNumber(value: $0.amount) }
        primaryBankRaw = profile.financials.primaryBank.rawValue
    }

    func toDomainProfile() -> UserProfile? {
        guard
            let addressing  = Addressing(rawValue: addressingRaw),
            let ageRange    = AgeRange(rawValue: ageRangeRaw),
            let salaryRange = SalaryRange(rawValue: salaryRangeRaw),
            let bank        = Bank(rawValue: primaryBankRaw)
        else { return nil }

        let frequency = Self.decodeSalaryFrequency(
            type: salaryFreqType, day1: salaryFreqDay1, day2: salaryFreqDay2)
        let secondaryIncome = secondaryIncomeRON.map { Money(Int(truncating: $0)) }

        return UserProfile(
            demographics: DemographicProfile(
                name: name,
                addressing: addressing,
                ageRange: ageRange
            ),
            financials: FinancialProfile(
                salaryRange: salaryRange,
                salaryFrequency: frequency,
                hasSecondaryIncome: hasSecondaryIncome,
                secondaryIncomeAvg: secondaryIncome,
                primaryBank: bank
            )
        )
    }

    // MARK: - Domain conversion — consent

    func populateConsent(from consent: UserConsent) {
        emailAccessGranted = consent.emailAccessGranted
        notificationsGranted = consent.notificationsGranted
        datasetOptIn = consent.datasetOptIn
        onboardingComplete = consent.onboardingComplete
    }

    func toDomainConsent() -> UserConsent {
        UserConsent(
            emailAccessGranted: emailAccessGranted,
            notificationsGranted: notificationsGranted,
            datasetOptIn: datasetOptIn,
            onboardingComplete: onboardingComplete
        )
    }

    // MARK: - SalaryFrequency encoding helpers

    private static func encodeSalaryFrequency(
        _ freq: SalaryFrequency,
        typeOut: inout String,
        day1Out: inout Int16,
        day2Out: inout Int16
    ) {
        switch freq {
        case .monthly(let day):
            typeOut = "monthly"; day1Out = Int16(day); day2Out = 0
        case .bimonthly(let d1, let d2):
            typeOut = "bimonthly"; day1Out = Int16(d1); day2Out = Int16(d2)
        case .variable:
            typeOut = "variable"; day1Out = 0; day2Out = 0
        }
    }

    static func decodeSalaryFrequency(type: String, day1: Int16, day2: Int16) -> SalaryFrequency {
        switch type {
        case "monthly":   return .monthly(dayOfMonth: Int(day1))
        case "bimonthly": return .bimonthly(firstDay: Int(day1), secondDay: Int(day2))
        default:          return .variable
        }
    }
}
