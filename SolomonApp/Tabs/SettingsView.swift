import SwiftUI
import SolomonCore
import SolomonStorage

// MARK: - SettingsView (Tab 4 — Setări)
//
// Profil user, permisiuni, abonament, about.
// Faza 10: layout complet cu date mock.

struct SettingsView: View {

    @StateObject private var vm = SettingsViewModel()
    @State private var showShortcutSetup = false
    @State private var showProfileEdit = false
    @State private var showGoalsList = false
    @State private var showSpiralAlert = false
    @State private var showEmailParser = false
    @State private var showDebugAlert: DebugAlertKind?

    enum DebugAlertKind: Identifiable {
        case demoGenerated
        case dataCleared
        case onboardingReset
        case error(String)

        var id: String {
            switch self {
            case .demoGenerated: return "demo"
            case .dataCleared: return "clear"
            case .onboardingReset: return "onboarding"
            case .error(let m): return "error:\(m)"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.solCanvas.ignoresSafeArea()

                List {
                    // Profil
                    profileSection

                    // Conectări
                    connectionsSection

                    // Notificări
                    notificationsSection

                    // Abonament
                    subscriptionSection

                    // About
                    aboutSection

                    // Debug (doar build Debug)
                    #if DEBUG
                    debugSection
                    #endif
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Setări")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showShortcutSetup) {
                ShortcutSetupView()
            }
            .sheet(isPresented: $showProfileEdit) {
                ProfileEditView()
            }
            .sheet(isPresented: $showGoalsList) {
                GoalsListView()
            }
            .sheet(isPresented: $showSpiralAlert) {
                SpiralAlertView()
            }
            .sheet(isPresented: $showEmailParser) {
                EmailParserSheet()
            }
            .onAppear {
                vm.configure(persistence: SolomonPersistenceController.shared)
            }
            .alert(item: $showDebugAlert) { kind in
                switch kind {
                case .demoGenerated:
                    return Alert(title: Text("✅ Demo data"),
                                 message: Text("Am generat 6 luni de tranzacții, obligații și abonamente."))
                case .dataCleared:
                    return Alert(title: Text("🗑 Date șterse"),
                                 message: Text("Toate tranzacțiile, obligațiile și abonamentele au fost șterse."))
                case .onboardingReset:
                    return Alert(title: Text("♻️ Onboarding resetat"),
                                 message: Text("Repornește app-ul ca să intri în onboarding."))
                case .error(let msg):
                    return Alert(title: Text("⚠️ Eroare"), message: Text(msg))
                }
            }
        }
    }

    @ViewBuilder
    private var debugSection: some View {
        Section {
            settingsRow(icon: "wand.and.stars", label: "Generează demo data", value: "6 luni") {
                runDemoGenerate()
            }
            settingsRow(icon: "trash", label: "Șterge toate datele", value: nil) {
                runClearData()
            }
            settingsRow(icon: "arrow.counterclockwise", label: "Reset onboarding", value: nil) {
                OnboardingState.resetForDebug()
                showDebugAlert = .onboardingReset
            }
        } header: {
            sectionHeader("DEBUG (DEV BUILD)")
        }
    }

    private func runDemoGenerate() {
        let ctx = SolomonPersistenceController.shared.container.viewContext
        let txRepo = CoreDataTransactionRepository(context: ctx)
        let oblRepo = CoreDataObligationRepository(context: ctx)
        let subRepo = CoreDataSubscriptionRepository(context: ctx)
        let userRepo = CoreDataUserProfileRepository(context: ctx)
        do {
            try DemoDataGenerator.populate(
                transactionRepo: txRepo,
                obligationRepo: oblRepo,
                subscriptionRepo: subRepo,
                userProfileRepo: userRepo
            )
            showDebugAlert = .demoGenerated
        } catch {
            showDebugAlert = .error(error.localizedDescription)
        }
    }

    private func runClearData() {
        let ctx = SolomonPersistenceController.shared.container.viewContext
        let txRepo = CoreDataTransactionRepository(context: ctx)
        let oblRepo = CoreDataObligationRepository(context: ctx)
        let subRepo = CoreDataSubscriptionRepository(context: ctx)
        do {
            try DemoDataGenerator.clearAll(
                transactionRepo: txRepo,
                obligationRepo: oblRepo,
                subscriptionRepo: subRepo
            )
            showDebugAlert = .dataCleared
        } catch {
            showDebugAlert = .error(error.localizedDescription)
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var profileSection: some View {
        Section {
            HStack(spacing: SolSpacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.solMint.opacity(0.15))
                        .frame(width: 52, height: 52)
                    Text("A")
                        .font(.solHeadingXL)
                        .foregroundStyle(Color.solMint)
                }

                VStack(alignment: .leading, spacing: SolSpacing.xs) {
                    Text(vm.userName)
                        .font(.solHeadingSM)
                        .foregroundStyle(Color.solTextPrimary)
                    Text(vm.userPlan)
                        .font(.solCaption)
                        .foregroundStyle(Color.solMint)
                }
            }
            .listRowBackground(Color.solSurface)
            .listRowSeparatorTint(Color.solBorder)

            settingsRow(icon: "person.fill", label: "Profil financiar", value: nil) {
                showProfileEdit = true
            }

            settingsRow(icon: "target", label: "Obiective", value: nil) {
                showGoalsList = true
            }
        } header: {
            sectionHeader("PROFIL")
        }
    }

    @ViewBuilder
    private var connectionsSection: some View {
        Section {
            // Hero row — conectează banca via Shortcuts
            Button(action: { showShortcutSetup = true }) {
                HStack(spacing: SolSpacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: SolRadius.sm, style: .continuous)
                            .fill(Color.solMint.opacity(0.15))
                            .frame(width: 32, height: 32)
                        Image(systemName: "app.badge")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.solMint)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Conectează banca")
                            .font(.solBodyMD)
                            .foregroundStyle(Color.solTextPrimary)
                        Text(vm.connectedBanksLabel)
                            .font(.solCaption)
                            .foregroundStyle(Color.solMint)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.solTextMuted)
                }
            }
            .listRowBackground(Color.solSurface)
            .listRowSeparatorTint(Color.solBorder)

            settingsRow(icon: "tray.and.arrow.down.fill", label: "Importă din email manual", value: nil) {
                showEmailParser = true
            }

            settingsToggleRow(
                icon: "envelope.fill",
                iconColor: .solInfo,
                label: "Gmail conectat",
                isOn: $vm.isGmailConnected
            )

            settingsToggleRow(
                icon: "bell.fill",
                iconColor: .solMint,
                label: "Notificări push",
                isOn: $vm.notificationsEnabled
            )

            settingsToggleRow(
                icon: "calendar",
                iconColor: .solWarning,
                label: "Calendar (opțional)",
                isOn: $vm.calendarEnabled
            )
        } header: {
            sectionHeader("CONECTĂRI")
        }
    }

    @ViewBuilder
    private var notificationsSection: some View {
        Section {
            settingsRow(icon: "shield.lefthalf.filled", label: "Verificare spirală", value: nil) {
                showSpiralAlert = true
            }
            settingsRow(icon: "clock.fill", label: "Sumar săptămânal", value: "Duminică 20:00") {}
            settingsRow(icon: "exclamationmark.triangle.fill", label: "Alerte financiare", value: "Activate") {}
        } header: {
            sectionHeader("NOTIFICĂRI")
        }
    }

    @ViewBuilder
    private var subscriptionSection: some View {
        Section {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: SolRadius.sm, style: .continuous)
                        .fill(Color.solMint.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: "crown.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.solMint)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Solomon Plus")
                        .font(.solBodyMD)
                        .foregroundStyle(Color.solTextPrimary)
                    Text("39 RON/lună · Reînnoire pe 15 mai")
                        .font(.solCaption)
                        .foregroundStyle(Color.solTextMuted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.solTextMuted)
            }
            .listRowBackground(Color.solSurface)
        } header: {
            sectionHeader("ABONAMENT")
        }
    }

    @ViewBuilder
    private var aboutSection: some View {
        Section {
            settingsRow(icon: "info.circle.fill", label: "Despre Solomon", value: "v1.0.0") {}
            settingsRow(icon: "lock.shield.fill", label: "Confidențialitate", value: nil) {}
            settingsRow(icon: "doc.text.fill", label: "Termeni de utilizare", value: nil) {}

            settingsToggleRow(
                icon: "brain.head.profile",
                iconColor: .solTextMuted,
                label: "Contribuie la training (opt-in)",
                isOn: $vm.trainingOptIn
            )
        } header: {
            sectionHeader("DESPRE")
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func settingsRow(icon: String, label: String, value: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: SolSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.solTextSecondary)
                    .frame(width: 24)
                Text(label)
                    .font(.solBodyMD)
                    .foregroundStyle(Color.solTextPrimary)
                Spacer()
                if let value {
                    Text(value)
                        .font(.solCaption)
                        .foregroundStyle(Color.solTextMuted)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.solTextMuted)
            }
        }
        .listRowBackground(Color.solSurface)
        .listRowSeparatorTint(Color.solBorder)
    }

    @ViewBuilder
    private func settingsToggleRow(
        icon: String,
        iconColor: Color,
        label: String,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(spacing: SolSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(iconColor)
                .frame(width: 24)
            Text(label)
                .font(.solBodyMD)
                .foregroundStyle(Color.solTextPrimary)
            Spacer()
            Toggle("", isOn: isOn)
                .tint(Color.solMint)
        }
        .listRowBackground(Color.solSurface)
        .listRowSeparatorTint(Color.solBorder)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.solCaption)
            .foregroundStyle(Color.solTextMuted)
            .tracking(1.2)
    }
}

// MARK: - SettingsViewModel

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var userName: String = "..."
    @Published var userPlan: String = "Solomon Plus · Activ"
    @Published var isGmailConnected: Bool = false {
        didSet { persistConsent() }
    }
    @Published var notificationsEnabled: Bool = false {
        didSet { persistConsent() }
    }
    @Published var calendarEnabled: Bool = false  // Calendar EventKit nu e wired încă
    @Published var trainingOptIn: Bool = false {
        didSet { persistConsent() }
    }
    @Published var connectedBanks: [String] = []

    private var userProfileRepo: (any UserProfileRepository)?
    private var isLoading: Bool = false

    var connectedBanksLabel: String {
        if connectedBanks.isEmpty {
            return "Setup în Shortcuts"
        } else if connectedBanks.count == 1 {
            return connectedBanks[0]
        } else {
            return "\(connectedBanks.count) bănci conectate"
        }
    }

    func configure(persistence: SolomonPersistenceController) {
        let ctx = persistence.container.viewContext
        self.userProfileRepo = CoreDataUserProfileRepository(context: ctx)
        load()
    }

    func load() {
        isLoading = true
        defer { isLoading = false }
        guard let repo = userProfileRepo else { return }
        if let profile = try? repo.fetchProfile() {
            userName = profile.demographics.name
        }
        if let consent = try? repo.fetchConsent() {
            isGmailConnected = consent.emailAccessGranted
            notificationsEnabled = consent.notificationsGranted
            trainingOptIn = consent.datasetOptIn
        }
    }

    private func persistConsent() {
        guard !isLoading, let repo = userProfileRepo else { return }
        let consent = UserConsent(
            emailAccessGranted: isGmailConnected,
            notificationsGranted: notificationsEnabled,
            datasetOptIn: trainingOptIn,
            onboardingComplete: OnboardingState.hasCompletedOnboarding
        )
        try? repo.saveConsent(consent)
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
