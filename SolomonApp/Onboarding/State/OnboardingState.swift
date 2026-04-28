import Foundation
import SwiftUI
import Combine
import SolomonCore
import SolomonStorage

// MARK: - OnboardingState
//
// Single source-of-truth pentru flow-ul de onboarding (9 ecrane).
// Persistă draft-ul intermediar în UserDefaults pentru recovery la crash/exit.
// La final: salvează UserProfile + Goal + Obligations în CoreData.

@MainActor
final class OnboardingState: ObservableObject {

    // MARK: - First-run flag

    static let userDefaultsKey = "solomon.onboarding.completed"

    static var hasCompletedOnboarding: Bool {
        UserDefaults.standard.bool(forKey: userDefaultsKey)
    }

    static func markCompleted() {
        UserDefaults.standard.set(true, forKey: userDefaultsKey)
    }

    static func resetForDebug() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }

    // MARK: - Navigation

    @Published var currentStep: Int = 0   // 0...8 (9 ecrane)
    static let totalSteps = 9

    var canGoBack: Bool { currentStep > 0 && currentStep < 8 }
    var isLastStep: Bool { currentStep == 8 }

    func next() {
        guard currentStep < Self.totalSteps - 1 else { return }
        withAnimation { currentStep += 1 }
    }

    func back() {
        guard canGoBack else { return }
        withAnimation { currentStep -= 1 }
    }

    func jumpTo(_ step: Int) {
        guard step >= 0, step < Self.totalSteps else { return }
        withAnimation { currentStep = step }
    }

    // MARK: - Ecran 2 — Identitate

    @Published var name: String = ""
    @Published var addressing: Addressing = .tu

    // MARK: - Ecran 3 — Venit

    @Published var salaryRange: SalaryRange? = nil
    @Published var paydayDay: Int = 28
    @Published var hasSecondaryIncome: Bool = false
    @Published var secondaryIncomeApprox: Int = 0  // RON

    // MARK: - Ecran 4 — Bancă

    @Published var primaryBank: Bank? = nil

    // MARK: - Ecran 5 — Obligații cunoscute (draft)

    @Published var draftObligations: [DraftObligation] = []

    struct DraftObligation: Identifiable {
        let id = UUID()
        var name: String
        var amountRON: Int
        var dayOfMonth: Int
        var kind: ObligationKind
    }

    func addDraftObligation() {
        draftObligations.append(
            DraftObligation(name: "", amountRON: 0, dayOfMonth: 1, kind: .subscription)
        )
    }

    func removeDraftObligation(_ id: UUID) {
        draftObligations.removeAll { $0.id == id }
    }

    // MARK: - Ecran 6 — Obiective

    @Published var selectedGoals: Set<GoalChip> = []
    @Published var bigGoalText: String = ""

    enum GoalChip: String, CaseIterable, Hashable {
        case noZeroOn22       = "Să nu mai fiu pe zero pe 22"
        case saveForVacation  = "Să strâng pentru vacanță"
        case clearDebts       = "Să scap de datorii"
        case saveMonthly      = "Să economisesc lunar"
        case understandWhere  = "Să înțeleg unde se duc banii"
    }

    // MARK: - Ecran 7 — Permisiuni

    @Published var gmailConnected: Bool = false
    @Published var pushAllowed: Bool = false
    @Published var trainingOptIn: Bool = false

    // MARK: - Ecran 8 — Procesare

    @Published var processingTasks: [ProcessingTaskState] = [
        ProcessingTaskState(title: "Citesc emailurile financiare...",      state: .pending),
        ProcessingTaskState(title: "Identific tranzacții și abonamente...", state: .pending),
        ProcessingTaskState(title: "Caut pattern-uri...",                   state: .pending),
        ProcessingTaskState(title: "Pregătesc primul raport...",            state: .pending),
    ]

    struct ProcessingTaskState: Identifiable {
        let id = UUID()
        let title: String
        var state: ProcessingTaskRow.State
    }

    /// Simulează procesarea pas cu pas (pentru ecran 8).
    func runSimulatedProcessing() async {
        for index in processingTasks.indices {
            try? await Task.sleep(for: .milliseconds(100))
            processingTasks[index].state = .running
            try? await Task.sleep(for: .seconds(1.2))
            processingTasks[index].state = .done
        }
    }

    // MARK: - Ecran 9 — Wow Moment generation

    @Published var isGeneratingWow: Bool = false
    @Published var wowMomentText: String = ""

    // MARK: - Validation

    var canProceedFromCurrentStep: Bool {
        switch currentStep {
        case 0: return true                         // Welcome — always OK
        case 1: return !name.trimmingCharacters(in: .whitespaces).isEmpty
        case 2: return salaryRange != nil
        case 3: return primaryBank != nil
        case 4: return true                         // Obligații — opțional
        case 5: return !selectedGoals.isEmpty
        case 6: return true                         // Permisiuni — opțional
        case 7: return processingTasks.allSatisfy { $0.state == .done }
        case 8: return true                         // Wow — final
        default: return false
        }
    }

    // MARK: - Save final

    /// Construiește UserProfile + obligații + goal și le salvează prin repositories.
    /// Apelat la finalul onboarding-ului (pas 8 → continue).
    func persistFinalProfile(
        userProfileRepository: any UserProfileRepository,
        obligationRepository: any ObligationRepository,
        goalRepository: any GoalRepository
    ) throws {
        guard let salary = salaryRange, let bank = primaryBank else { return }

        let demographic = DemographicProfile(
            name: name.trimmingCharacters(in: .whitespaces),
            addressing: addressing,
            ageRange: .range25to35   // default — inferat ulterior
        )
        let financial = FinancialProfile(
            salaryRange: salary,
            salaryFrequency: .monthly(dayOfMonth: paydayDay),
            hasSecondaryIncome: hasSecondaryIncome,
            secondaryIncomeAvg: hasSecondaryIncome ? Money(secondaryIncomeApprox) : nil,
            primaryBank: bank
        )
        let profile = UserProfile(demographics: demographic, financials: financial)
        try userProfileRepository.saveProfile(profile)

        // Persist consents
        let consent = UserConsent(
            emailAccessGranted: gmailConnected,
            notificationsGranted: pushAllowed,
            datasetOptIn: trainingOptIn,
            onboardingComplete: true
        )
        try userProfileRepository.saveConsent(consent)

        // Obligații draft → Obligation
        for d in draftObligations where !d.name.isEmpty && d.amountRON > 0 {
            let obligation = Obligation(
                id: UUID(),
                name: d.name,
                amount: Money(d.amountRON),
                dayOfMonth: d.dayOfMonth,
                kind: d.kind,
                confidence: .declared,
                since: Date()
            )
            try obligationRepository.upsert(obligation)
        }

        // Goal — doar dacă bigGoalText e completat (Goal cere amountTarget > 0,
        // deci pentru free text fără sumă concretă, încă nu îl salvăm).
        // Fazele viitoare vor adăuga Q&A pentru sumă/deadline.
        // selectedGoals (chips) sunt salvate doar tematic în UserDefaults pentru analytics.
        let chipsRaw = selectedGoals.map { $0.rawValue }.joined(separator: "|")
        UserDefaults.standard.set(chipsRaw, forKey: "solomon.onboarding.selectedGoals")
        if !bigGoalText.isEmpty {
            UserDefaults.standard.set(bigGoalText, forKey: "solomon.onboarding.bigGoalText")
        }

        Self.markCompleted()
    }
}
