import SwiftUI
import Observation
import SolomonCore
import SolomonStorage

// MARK: - SettingsView (Solomon DS — Claude Design v3)
//
// Redesign Faza 33: aliniat 1:1 cu Solomon DS / screens/settings.html.
// MeshBackground + AppBar + Profile card + 4 secțiuni cu ListCard + #if DEBUG.

struct SettingsView: View {

    @State private var vm = SettingsViewModel()
    @State private var showShortcutSetup = false
    @State private var showProfileEdit = false
    @State private var showGoalsList = false
    @State private var showSpiralAlert = false
    @State private var showEmailParser = false
    @State private var showModelDownload = false
    @State private var showDebugAlert: DebugAlertKind?

    // Toggles care nu există încă în VM — local state pentru pilot
    @State private var faceIDEnabled: Bool = true
    @State private var weeklyInsights: Bool = true
    @State private var paymentReminders: Bool = false

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
            ZStack {
                MeshBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        SolAppBar(brand: "SOLOMON · PROFIL", greeting: "Setări") {
                            EmptyView()
                        }

                        profileCard
                            .padding(.bottom, 16)

                        SolSectionHeaderRow("Date & Securitate")
                        dataSecurityCard
                            .padding(.bottom, 16)

                        SolSectionHeaderRow("Notificări")
                        notificationsCard
                            .padding(.bottom, 16)

                        SolSectionHeaderRow("Preferințe")
                        preferencesCard
                            .padding(.bottom, 16)

                        SolSectionHeaderRow("Despre")
                        aboutCard
                            .padding(.bottom, 16)

                        #if DEBUG
                        SolSectionHeaderRow("Debug")
                        debugCard
                            .padding(.bottom, 16)
                        #endif
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 100)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
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

    // MARK: - Profile Card

    private var profileCard: some View {
        HStack(spacing: 14) {
            // Avatar 54×54 rounded sq 18, gradient mint
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.solMintExact, .solMintDeep],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            .blendMode(.plusLighter)
                    )
                    .shadow(color: Color.solMintExact.opacity(0.4), radius: 10, x: 0, y: 8)
                Text(initials(from: vm.userName))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color(red: 0x05/255, green: 0x2E/255, blue: 0x16/255))
                    .tracking(-0.5)
            }
            .frame(width: 54, height: 54)

            VStack(alignment: .leading, spacing: 0) {
                Text(vm.userName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.white)
                Text(vm.connectedBanksLabel.isEmpty ? "Conturi: ING + BT · 47 lună activ" : "Conturi: \(vm.connectedBanksLabel) · 47 lună activ")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.5))
                    .padding(.top, 2)
                HStack(spacing: 6) {
                    SolChip("Pro", kind: .mint)
                    SolChip("→ Plan", kind: .muted)
                }
                .padding(.top, 8)
            }
            Spacer()
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.04), Color.white.opacity(0.015)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .background(.ultraThinMaterial.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
    }

    // MARK: - Data & Security

    private var dataSecurityCard: some View {
        SolListCard {
            SettingsRow(
                icon: "faceid",
                accent: .mint,
                title: "Face ID",
                kind: .toggle(isOn: $faceIDEnabled)
            )
            SolHairlineDivider()
            SettingsRow(
                icon: "creditcard.fill",
                accent: .blue,
                title: "Conturi conectate",
                kind: .valueChevron(value: vm.connectedBanksLabel.isEmpty ? "0 active" : "\(vm.connectedBanks.count) active"),
                onTap: { showShortcutSetup = true }
            )
            SolHairlineDivider()
            SettingsRow(
                icon: "person.text.rectangle.fill",
                accent: .violet,
                title: "Date personale",
                kind: .chevron,
                onTap: { showProfileEdit = true }
            )
            SolHairlineDivider()
            SettingsRow(
                icon: "tray.and.arrow.down.fill",
                accent: .blue,
                title: "Importă din email",
                kind: .chevron,
                onTap: { showEmailParser = true }
            )
        }
    }

    // MARK: - Notifications

    private var notificationsCard: some View {
        SolListCard {
            SettingsRow(
                icon: "bell.fill",
                accent: .amber,
                title: "Alerte critice",
                kind: .toggle(isOn: $vm.notificationsEnabled)
            )
            SolHairlineDivider()
            SettingsRow(
                icon: "chart.line.uptrend.xyaxis",
                accent: .mint,
                title: "Insights săptămânale",
                kind: .toggle(isOn: $weeklyInsights)
            )
            SolHairlineDivider()
            SettingsRow(
                icon: "clock.fill",
                accent: .gray,
                title: "Reminder plăți",
                kind: .toggle(isOn: $paymentReminders)
            )
            SolHairlineDivider()
            SettingsRow(
                icon: "shield.lefthalf.filled",
                accent: .amber,
                title: "Verificare spirală",
                kind: .chevron,
                onTap: { showSpiralAlert = true }
            )
        }
    }

    // MARK: - Preferences

    private var preferencesCard: some View {
        SolListCard {
            SettingsRow(
                icon: "dollarsign.circle.fill",
                accent: .gray,
                title: "Monedă",
                kind: .valueChevron(value: "RON"),
                onTap: { Haptics.light() }
            )
            SolHairlineDivider()
            SettingsRow(
                icon: "globe",
                accent: .gray,
                title: "Limbă",
                kind: .valueChevron(value: "Română"),
                onTap: { Haptics.light() }
            )
            SolHairlineDivider()
            SettingsRow(
                icon: "calendar",
                accent: .gray,
                title: "Început lună salarială",
                kind: .valueChevron(value: "ziua 1"),
                onTap: { Haptics.light() }
            )
            SolHairlineDivider()
            SettingsRow(
                icon: "brain.head.profile",
                accent: .gray,
                title: "Contribuie la training",
                kind: .toggle(isOn: $vm.trainingOptIn)
            )
        }
    }

    // MARK: - About

    private var aboutCard: some View {
        SolListCard {
            SettingsRow(
                icon: "crown.fill",
                accent: .amber,
                title: vm.userPlan,
                kind: .valueChevron(value: "Gestionează"),
                onTap: { openURL("https://apps.apple.com/account/subscriptions") }
            )
            SolHairlineDivider()
            SettingsRow(
                icon: "cpu.fill",
                accent: .blue,
                title: "Modelul LLM",
                kind: .chevron,
                onTap: { showModelDownload = true }
            )
            SolHairlineDivider()
            SettingsRow(
                icon: "lock.shield.fill",
                accent: .gray,
                title: "Confidențialitate",
                kind: .chevron,
                onTap: { openURL("https://solomon.ro/privacy") }
            )
            SolHairlineDivider()
            SettingsRow(
                icon: "doc.text.fill",
                accent: .gray,
                title: "Termeni de utilizare",
                kind: .chevron,
                onTap: { openURL("https://solomon.ro/terms") }
            )
            SolHairlineDivider()
            SettingsRow(
                icon: "info.circle.fill",
                accent: .gray,
                title: "Versiune",
                kind: .value(value: versionString)
            )
            SolHairlineDivider()
            SettingsRow(
                icon: "xmark",
                accent: .rose,
                title: "Deconectare",
                titleColor: .solRoseExact,
                kind: .none,
                onTap: {
                    Haptics.warning()
                    OnboardingState.resetForDebug()
                    showDebugAlert = .onboardingReset
                }
            )
        }
    }

    // MARK: - Debug

    #if DEBUG
    private var debugCard: some View {
        SolListCard {
            SettingsRow(
                icon: "wand.and.stars",
                accent: .violet,
                title: "Generează demo data",
                kind: .chevron,
                onTap: {
                    Haptics.light()
                    runDemoGenerate()
                }
            )
            SolHairlineDivider()
            SettingsRow(
                icon: "trash.fill",
                accent: .rose,
                title: "Șterge toate datele",
                titleColor: .solRoseExact,
                kind: .chevron,
                onTap: {
                    Haptics.warning()
                    runClearData()
                }
            )
            SolHairlineDivider()
            SettingsRow(
                icon: "arrow.counterclockwise",
                accent: .amber,
                title: "Reset onboarding",
                kind: .chevron,
                onTap: {
                    Haptics.warning()
                    OnboardingState.resetForDebug()
                    showDebugAlert = .onboardingReset
                }
            )
        }
    }
    #endif

    // MARK: - Helpers

    private var versionString: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(v) · build \(b)"
    }

    private func initials(from name: String) -> String {
        let parts = name.split(separator: " ").prefix(2)
        let letters = parts.compactMap { $0.first.map { String($0) } }.joined()
        let result = letters.uppercased()
        return result.isEmpty ? "S" : result
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

// MARK: - SettingsRow (custom row 1:1 cu .set-row din settings.html)

private struct SettingsRow: View {
    enum Accent {
        case mint, blue, violet, amber, rose, gray

        var color: Color {
            switch self {
            case .mint:   return .solMintExact
            case .blue:   return .solBlueExact
            case .violet: return .solVioletExact
            case .amber:  return .solAmberExact
            case .rose:   return .solRoseExact
            case .gray:   return Color.white.opacity(0.7)
            }
        }

        var iconBackground: AnyView {
            switch self {
            case .gray:
                return AnyView(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                )
            default:
                let c = color
                return AnyView(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [c.opacity(0.18), c.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(c.opacity(0.2), lineWidth: 1)
                        )
                )
            }
        }
    }

    enum Kind {
        case toggle(isOn: Binding<Bool>)
        case valueChevron(value: String)
        case chevron
        case value(value: String)
        case none
    }

    let icon: String
    let accent: Accent
    let title: String
    var titleColor: Color = .white
    let kind: Kind
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button {
            if case .toggle = kind { return }
            if let onTap {
                Haptics.light()
                onTap()
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    accent.iconBackground
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(accent.color)
                }
                .frame(width: 30, height: 30)

                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(titleColor)

                Spacer()

                trailing
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(disableButton)
    }

    private var disableButton: Bool {
        if case .toggle = kind { return true }
        return onTap == nil
    }

    @ViewBuilder
    private var trailing: some View {
        switch kind {
        case .toggle(let isOn):
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Color.solMintExact)
                .scaleEffect(0.9)
        case .valueChevron(let value):
            Text(value)
                .font(.system(size: 12))
                .foregroundStyle(Color.white.opacity(0.4))
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.3))
        case .chevron:
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.3))
        case .value(let value):
            Text(value)
                .font(.system(size: 12))
                .foregroundStyle(Color.white.opacity(0.4))
        case .none:
            EmptyView()
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
        let day = cal.component(.day, from: now)
        let renewMonth: Date
        if day <= 15 {
            renewMonth = cal.safeDate(dayOfMonth: 15, in: now)
        } else {
            let nextMonth = cal.date(byAdding: .month, value: 1, to: now) ?? now
            renewMonth = cal.safeDate(dayOfMonth: 15, in: nextMonth)
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
        guard userProfileRepo == nil else { return }
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
