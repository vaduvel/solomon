import SwiftUI
import Observation
import SolomonCore
import SolomonStorage

// MARK: - SettingsView (HIG aligned — insetGrouped Form)
//
// Refactor Faza 27: convert la nativ Form/.insetGrouped pattern Apple
// (ce vezi în Settings.app iOS).

struct SettingsView: View {

    @State private var vm = SettingsViewModel()
    @State private var showShortcutSetup = false
    @State private var showProfileEdit = false
    @State private var showGoalsList = false
    @State private var showSpiralAlert = false
    @State private var showEmailParser = false
    @State private var showModelDownload = false
    @State private var showDebugAlert: DebugAlertKind?

    enum DebugAlertKind: Identifiable {
        case demoGenerated, dataCleared, onboardingReset
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
            Form {
                profileSection
                connectionsSection
                notificationsSection
                subscriptionSection
                aboutSection
                #if DEBUG
                debugSection
                #endif
            }
            .scrollContentBackground(.hidden)
            .background(Color.solCanvas)
            .navigationTitle("Setări")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showShortcutSetup) { ShortcutSetupView().solStandardSheet() }
            .sheet(isPresented: $showProfileEdit) { ProfileEditView().solStandardSheet() }
            .sheet(isPresented: $showGoalsList) { GoalsListView().solStandardSheet() }
            .sheet(isPresented: $showSpiralAlert) { SpiralAlertView().solStandardSheet() }
            .sheet(isPresented: $showEmailParser) { EmailParserSheet().solStandardSheet() }
            .sheet(isPresented: $showModelDownload) { ModelDownloadView().solStandardSheet() }
            .onAppear {
                vm.configure(persistence: SolomonPersistenceController.shared)
            }
            .alert(item: $showDebugAlert) { kind in
                switch kind {
                case .demoGenerated:
                    return Alert(title: Text("Demo data generat"),
                                 message: Text("6 luni de tranzacții, obligații și abonamente."))
                case .dataCleared:
                    return Alert(title: Text("Date șterse"),
                                 message: Text("Toate datele financiare au fost șterse."))
                case .onboardingReset:
                    return Alert(title: Text("Onboarding resetat"),
                                 message: Text("Repornește app-ul ca să intri în onboarding."))
                case .error(let msg):
                    return Alert(title: Text("Eroare"), message: Text(msg))
                }
            }
        }
    }

    // MARK: - Sections (Apple Form pattern)

    @ViewBuilder
    private var profileSection: some View {
        Section {
            // Avatar + Name + Plan
            HStack(spacing: SolSpacing.md) {
                ZStack {
                    Circle()
                        .fill(LinearGradient.solHero)
                        .frame(width: 52, height: 52)
                    Text(String(vm.userName.prefix(1)).uppercased())
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.solCanvas)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(vm.userName)
                        .font(.headline)
                        .foregroundStyle(Color.solForeground)
                    Text(vm.userPlan)
                        .font(.footnote)
                        .foregroundStyle(Color.solPrimary)
                }
                Spacer()
            }
            .padding(.vertical, SolSpacing.xs)
            .listRowBackground(Color.solCard)

            navRow(icon: "person.fill", iconColor: .solCyan, label: "Profil financiar") {
                showProfileEdit = true
            }

            navRow(icon: "target", iconColor: .solPrimary, label: "Obiective") {
                showGoalsList = true
            }
        } header: {
            Text("Profil")
        }
    }

    @ViewBuilder
    private var connectionsSection: some View {
        Section {
            navRow(icon: "app.badge", iconColor: .solPrimary, label: "Conectează banca", value: vm.connectedBanksLabel) {
                showShortcutSetup = true
            }
            navRow(icon: "tray.and.arrow.down.fill", iconColor: .solCyan, label: "Importă din email") {
                showEmailParser = true
            }
            Toggle(isOn: $vm.notificationsEnabled) {
                Label("Notificări push", systemImage: "bell.fill")
                    .symbolRenderingMode(.hierarchical)
            }
            .tint(Color.solPrimary)
            .listRowBackground(Color.solCard)
        } header: {
            Text("Conectări")
        } footer: {
            Text("Datele tale rămân pe telefon. Solomon e privat.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var notificationsSection: some View {
        Section {
            navRow(icon: "shield.lefthalf.filled", iconColor: .solWarning, label: "Verificare spirală") {
                showSpiralAlert = true
            }
        } header: {
            Text("Sănătate financiară")
        }
    }

    @ViewBuilder
    private var subscriptionSection: some View {
        Section {
            Button {
                Haptics.light()
                openURL("https://apps.apple.com/account/subscriptions")
            } label: {
                HStack(spacing: SolSpacing.md) {
                    Image(systemName: "crown.fill")
                        .font(.body)
                        .foregroundStyle(Color.solPrimary)
                        .symbolRenderingMode(.hierarchical)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(vm.userPlan)
                            .font(.body)
                            .foregroundStyle(Color.solForeground)
                        Text(vm.subscriptionStatusLabel)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                }
            }
            .listRowBackground(Color.solCard)
        } header: {
            Text("Abonament")
        }
    }

    @ViewBuilder
    private var aboutSection: some View {
        Section {
            navRow(icon: "cpu.fill", iconColor: .solCyan, label: "Modelul LLM") {
                showModelDownload = true
            }
            navRow(icon: "info.circle.fill", iconColor: .secondary, label: "Despre Solomon", value: "v1.0.0") {
                openURL("https://solomon.ro/despre")
            }
            navRow(icon: "lock.shield.fill", iconColor: .secondary, label: "Confidențialitate") {
                openURL("https://solomon.ro/privacy")
            }
            navRow(icon: "doc.text.fill", iconColor: .secondary, label: "Termeni de utilizare") {
                openURL("https://solomon.ro/terms")
            }
            Toggle(isOn: $vm.trainingOptIn) {
                Label("Contribuie la training", systemImage: "brain.head.profile")
                    .symbolRenderingMode(.hierarchical)
            }
            .tint(Color.solPrimary)
            .listRowBackground(Color.solCard)
        } header: {
            Text("Despre")
        }
    }

    @ViewBuilder
    private var debugSection: some View {
        Section {
            Button {
                Haptics.light()
                runDemoGenerate()
            } label: {
                Label("Generează demo data", systemImage: "wand.and.stars")
            }
            .listRowBackground(Color.solCard)

            Button(role: .destructive) {
                Haptics.warning()
                runClearData()
            } label: {
                Label("Șterge toate datele", systemImage: "trash")
            }
            .listRowBackground(Color.solCard)

            Button {
                Haptics.warning()
                OnboardingState.resetForDebug()
                showDebugAlert = .onboardingReset
            } label: {
                Label("Reset onboarding", systemImage: "arrow.counterclockwise")
            }
            .listRowBackground(Color.solCard)
        } header: {
            Text("Debug")
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func navRow(
        icon: String,
        iconColor: Color,
        label: String,
        value: String? = nil,
        action: (() -> Void)? = nil
    ) -> some View {
        if let action {
            Button {
                Haptics.light()
                action()
            } label: {
                HStack(spacing: SolSpacing.md) {
                    Image(systemName: icon)
                        .font(.body)
                        .foregroundStyle(iconColor)
                        .symbolRenderingMode(.hierarchical)
                        .frame(width: 28)
                    Text(label)
                        .font(.body)
                        .foregroundStyle(Color.solForeground)
                    Spacer()
                    if let value {
                        Text(value)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Image(systemName: "chevron.right")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                }
            }
            .listRowBackground(Color.solCard)
        } else {
            HStack(spacing: SolSpacing.md) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(iconColor)
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 28)
                Text(label)
                    .font(.body)
                    .foregroundStyle(Color.solForeground)
                Spacer()
                if let value {
                    Text(value)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .listRowBackground(Color.solCard)
        }
    }

    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
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
            Haptics.success()
        } catch {
            showDebugAlert = .error(error.localizedDescription)
            Haptics.error()
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
            Haptics.success()
        } catch {
            showDebugAlert = .error(error.localizedDescription)
            Haptics.error()
        }
    }
}

// MARK: - SettingsViewModel

@Observable @MainActor
final class SettingsViewModel {
    var userName: String = "..."
    var userPlan: String = "Solomon Plus · Activ"
    var isGmailConnected: Bool = false {
        didSet { persistConsent() }
    }
    var notificationsEnabled: Bool = false {
        didSet { persistConsent() }
    }
    var trainingOptIn: Bool = false {
        didSet { persistConsent() }
    }
    var connectedBanks: [String] = []

    private var userProfileRepo: (any UserProfileRepository)?
    private var isLoading: Bool = false

    /// Detalii abonament — la lansare afișăm prețul standard; când StoreKit e integrat
    /// se va actualiza dinamic din Product.subscription.status.
    var subscriptionStatusLabel: String {
        let cal = Calendar.current
        let now = Date()
        // Găsim ziua de 15 a lunii viitoare (sau a celei curente dacă e după 15)
        let day = cal.component(.day, from: now)
        let renewMonth: Date
        if day <= 15 {
            renewMonth = cal.date(bySetting: .day, value: 15, of: now) ?? now
        } else {
            let nextMonth = cal.date(byAdding: .month, value: 1, to: now) ?? now
            renewMonth = cal.date(bySetting: .day, value: 15, of: nextMonth) ?? nextMonth
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ro_RO")
        formatter.dateFormat = "d MMMM"
        return "39 RON/lună · Reînnoire pe \(formatter.string(from: renewMonth))"
    }

    var connectedBanksLabel: String {
        if connectedBanks.isEmpty { return "Setup" }
        if connectedBanks.count == 1 { return connectedBanks[0] }
        return "\(connectedBanks.count) bănci"
    }

    func configure(persistence: SolomonPersistenceController) {
        guard userProfileRepo == nil else { return }  // evită re-configurare la fiecare tab switch
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
