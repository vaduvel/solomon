import Foundation

// MARK: - AgeRange

/// Intervale de vârstă declarate la onboarding (spec §4.1, §11 ecran 2).
public enum AgeRange: String, Codable, Sendable, Hashable, CaseIterable {
    case under25     = "<25"
    case range25to35 = "25-35"
    case range35to45 = "35-45"
    case over45      = "45+"

    public var displayNameRO: String {
        switch self {
        case .under25:     return "sub 25 ani"
        case .range25to35: return "25–35 ani"
        case .range35to45: return "35–45 ani"
        case .over45:      return "peste 45 ani"
        }
    }
}

// MARK: - SalaryRange

/// Intervale de salariu net declarate la onboarding (spec §4.1, §11 ecran 3).
public enum SalaryRange: String, Codable, Sendable, Hashable, CaseIterable {
    case under3k    = "<3k"
    case range3to5  = "3-5k"
    case range5to8  = "5-8k"
    case range8to15 = "8-15k"
    case over15k    = ">15k"

    /// Punct mediu folosit ca estimare de bază pentru calcule, în RON.
    public var midpointRON: Int {
        switch self {
        case .under3k:    return 2_500
        case .range3to5:  return 4_000
        case .range5to8:  return 6_500
        case .range8to15: return 11_500
        case .over15k:    return 18_000
        }
    }
}

// MARK: - SalaryFrequency

/// Frecvența cu care utilizatorul primește salariul (spec §4.1).
public enum SalaryFrequency: Codable, Sendable, Hashable {
    /// Lunar pe data X (1–31).
    case monthly(dayOfMonth: Int)
    /// Chenzină pe data X1 și X2 (1–31, X1 < X2).
    case bimonthly(firstDay: Int, secondDay: Int)
    /// Variabil — fără pattern fix.
    case variable

    public var isPredictable: Bool {
        switch self {
        case .monthly, .bimonthly: return true
        case .variable:            return false
        }
    }
}

// MARK: - Bank

/// Băncile principale active pe piața RO (spec §8.1).
public enum Bank: String, Codable, Sendable, Hashable, CaseIterable {
    case bancaTransilvania = "BT"
    case bcr               = "BCR"
    case ing               = "ING"
    case raiffeisen        = "Raiffeisen"
    case revolut           = "Revolut"
    case cec               = "CEC"
    case unicredit         = "UniCredit"
    case patria            = "Patria"
    case procredit         = "ProCredit"
    case libra             = "Libra"
    case garanti           = "Garanti"
    case firstBank         = "FirstBank"
    case alpha             = "Alpha"
    case otp               = "OTP"
    case idea              = "Idea"
    case other             = "Other"

    public var displayNameRO: String {
        switch self {
        case .bancaTransilvania: return "Banca Transilvania"
        case .bcr:               return "BCR"
        case .ing:               return "ING Bank"
        case .raiffeisen:        return "Raiffeisen Bank"
        case .revolut:           return "Revolut"
        case .cec:               return "CEC Bank"
        case .unicredit:         return "UniCredit Bank"
        case .patria:            return "Patria Bank"
        case .procredit:         return "ProCredit Bank"
        case .libra:             return "Libra Internet Bank"
        case .garanti:           return "Garanti BBVA"
        case .firstBank:         return "First Bank"
        case .alpha:             return "Alpha Bank"
        case .otp:               return "OTP Bank"
        case .idea:              return "Idea Bank"
        case .other:             return "Altă bancă"
        }
    }
}

// MARK: - DemographicProfile

/// Identitatea declarată la onboarding (spec §4.1, §11 ecranele 2–3).
public struct DemographicProfile: Codable, Sendable, Hashable {
    public var name: String
    public var addressing: Addressing
    public var ageRange: AgeRange

    public init(name: String, addressing: Addressing, ageRange: AgeRange) {
        self.name = name
        self.addressing = addressing
        self.ageRange = ageRange
    }
}

// MARK: - FinancialProfile

/// Profilul financiar declarat la onboarding (spec §4.1).
public struct FinancialProfile: Codable, Sendable, Hashable {
    public var salaryRange: SalaryRange
    public var salaryFrequency: SalaryFrequency
    public var hasSecondaryIncome: Bool
    public var secondaryIncomeAvg: Money?
    public var primaryBank: Bank

    public init(
        salaryRange: SalaryRange,
        salaryFrequency: SalaryFrequency,
        hasSecondaryIncome: Bool,
        secondaryIncomeAvg: Money? = nil,
        primaryBank: Bank
    ) {
        self.salaryRange = salaryRange
        self.salaryFrequency = salaryFrequency
        self.hasSecondaryIncome = hasSecondaryIncome
        self.secondaryIncomeAvg = secondaryIncomeAvg
        self.primaryBank = primaryBank
    }
}

// MARK: - UserProfile

/// Profilul complet al unui utilizator Solomon (combinația de mai sus).
public struct UserProfile: Codable, Sendable, Hashable {
    public var demographics: DemographicProfile
    public var financials: FinancialProfile

    public init(demographics: DemographicProfile, financials: FinancialProfile) {
        self.demographics = demographics
        self.financials = financials
    }
}
