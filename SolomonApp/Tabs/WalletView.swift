import SwiftUI
import SolomonCore
import SolomonStorage
import SolomonAnalytics

// MARK: - WalletView (Tab 3 — Portofel)
//
// Faza 17B: WIRED la repositories CoreData (Obligation, Subscription, Transaction).
// Afișează obligațiile active, abonamentele detectate, tranzacții recente.

struct WalletView: View {

    @StateObject private var vm = WalletViewModel()
    @State private var selectedSegment = 0
    @State private var showSubscriptionAudit = false
    @State private var showSuspiciousTransactions = false
    @State private var showManualEntry = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented Picker NATIV iOS HIG
                Picker("Selecție", selection: $selectedSegment) {
                    Text("Obligații").tag(0)
                    Text("Abonamente").tag(1)
                    Text("Tranzacții").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, SolSpacing.lg)
                .padding(.vertical, SolSpacing.sm)
                .onChange(of: selectedSegment) { _, _ in Haptics.selection() }

                ScrollView {
                    VStack(spacing: SolSpacing.xl) {
                        switch selectedSegment {
                        case 0: obligationsSection
                        case 1: subscriptionsSection
                        default: transactionsSection
                        }
                        Spacer(minLength: SolSpacing.xxxl)
                    }
                    .padding(.top, SolSpacing.base)
                }
            }
            .background(Color.solCanvas)
            .navigationTitle("Portofel")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.light()
                        showManualEntry = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color.solPrimary)
                    }
                }
            }
            .sheet(isPresented: $showSubscriptionAudit, onDismiss: { Task { await vm.load() } }) {
                SubscriptionAuditView().solStandardSheet()
            }
            .sheet(isPresented: $showSuspiciousTransactions, onDismiss: { Task { await vm.load() } }) {
                SuspiciousTransactionsView().solStandardSheet()
            }
            .sheet(isPresented: $showManualEntry, onDismiss: { Task { await vm.load() } }) {
                ManualTransactionView().solStandardSheet()
            }
        }
        .task {
            vm.configure(persistence: SolomonPersistenceController.shared)
            await vm.load()
        }
    }

    // MARK: - Segment Control

    @ViewBuilder
    private var segmentControl: some View {
        HStack(spacing: 0) {
            ForEach(["Obligații", "Abonamente", "Tranzacții"].indices, id: \.self) { idx in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        selectedSegment = idx
                    }
                } label: {
                    Text(["Obligații", "Abonamente", "Tranzacții"][idx])
                        .font(.solBodyBold)
                        .foregroundStyle(selectedSegment == idx ? Color.solCanvas : Color.solTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, SolSpacing.sm)
                        .background(
                            selectedSegment == idx
                                ? AnyShapeStyle(LinearGradient.solPrimaryCTA)
                                : AnyShapeStyle(Color.clear)
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(SolSpacing.xs)
        .background(Color.solCard)
        .clipShape(Capsule())
    }

    // MARK: - Obligații

    @ViewBuilder
    private var obligationsSection: some View {
        VStack(spacing: SolSpacing.base) {
            // Total
            HStack {
                VStack(alignment: .leading, spacing: SolSpacing.xs) {
                    Text("Total lunar rezervat")
                        .font(.solCaption)
                        .foregroundStyle(Color.solMuted)
                    Text(vm.obligationsTotalFormatted)
                        .font(.solH1)
                        .foregroundStyle(Color.solForeground)
                        .monospacedDigit()
                }
                Spacer()
                if !vm.obligationsPercentText.isEmpty {
                    StatusBadge(title: vm.obligationsPercentText, kind: vm.obligationsKind)
                }
            }
            .padding(SolSpacing.cardStandard)
            .solCard()
            .padding(.horizontal, SolSpacing.screenHorizontal)

            // Lista
            if vm.obligations.isEmpty {
                emptyState(icon: "house.fill", title: "Nicio obligație", subtitle: "Adaugă chiria, ratele și abonamentele tale.")
                    .padding(.horizontal, SolSpacing.screenHorizontal)
            } else {
                VStack(spacing: SolSpacing.sm) {
                    ForEach(vm.obligations) { obl in
                        ObligationRow(obligation: obl)
                    }
                }
                .padding(.horizontal, SolSpacing.screenHorizontal)
            }
        }
    }

    @ViewBuilder
    private var subscriptionsSection: some View {
        VStack(spacing: SolSpacing.base) {
            HStack {
                VStack(alignment: .leading, spacing: SolSpacing.xs) {
                    Text("Total abonamente / lună")
                        .font(.solCaption)
                        .foregroundStyle(Color.solMuted)
                    Text(vm.subscriptionsTotalFormatted)
                        .font(.solH1)
                        .foregroundStyle(LinearGradient.solHero)
                        .monospacedDigit()
                }
                Spacer()
                if vm.ghostSavingsPotential > 0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Potențial economii")
                            .font(.solCaption)
                            .foregroundStyle(Color.solMuted)
                        Text("\(vm.ghostSavingsPotential) RON/lună")
                            .font(.solMonoSM)
                            .foregroundStyle(Color.solPrimary)
                    }
                }
            }
            .padding(SolSpacing.cardStandard)
            .solCard()
            .padding(.horizontal, SolSpacing.screenHorizontal)

            if vm.subscriptions.isEmpty {
                emptyState(icon: "play.rectangle.fill", title: "Niciun abonament", subtitle: "Solomon le va detecta automat din email-uri.")
                    .padding(.horizontal, SolSpacing.screenHorizontal)
            } else {
                if vm.ghostSavingsPotential > 0 {
                    Button {
                        showSubscriptionAudit = true
                    } label: {
                        HStack {
                            IconContainer(systemName: "scissors", variant: .neon, size: 36, iconSize: 14)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Anulează abonamentele fantomă")
                                    .font(.solBodyBold)
                                    .foregroundStyle(Color.solForeground)
                                Text("Economisești \(vm.ghostSavingsPotential) RON/lună")
                                    .font(.solCaption)
                                    .foregroundStyle(Color.solPrimary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.solMuted)
                        }
                        .padding(SolSpacing.base)
                        .solAIInsightCard()
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, SolSpacing.screenHorizontal)
                }

                VStack(spacing: SolSpacing.sm) {
                    ForEach(vm.subscriptions) { sub in
                        SubscriptionRow(subscription: sub)
                    }
                }
                .padding(.horizontal, SolSpacing.screenHorizontal)
            }
        }
    }

    @ViewBuilder
    private var transactionsSection: some View {
        VStack(spacing: SolSpacing.base) {
            if vm.transactions.isEmpty {
                emptyState(icon: "list.bullet.rectangle", title: "Nicio tranzacție", subtitle: "Conectează banca via Shortcuts sau adaugă manual.")
                    .padding(.horizontal, SolSpacing.screenHorizontal)
            } else {
                Button {
                    showSuspiciousTransactions = true
                } label: {
                    HStack {
                        IconContainer(systemName: "exclamationmark.shield.fill", variant: .warn, size: 36, iconSize: 14)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Verifică tranzacțiile suspecte")
                                .font(.solBodyBold)
                                .foregroundStyle(Color.solForeground)
                            Text("Solomon detectează automat sume mari, burst-uri și plăți de noapte.")
                                .font(.solCaption)
                                .foregroundStyle(Color.solMuted)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.solMuted)
                    }
                    .padding(SolSpacing.base)
                    .solCard()
                }
                .buttonStyle(.plain)
                .padding(.horizontal, SolSpacing.screenHorizontal)

                VStack(spacing: SolSpacing.sm) {
                    ForEach(vm.transactions) { tx in
                        TransactionRow(transaction: tx)
                    }
                }
                .padding(.horizontal, SolSpacing.screenHorizontal)
            }
        }
    }

    // MARK: - Empty state

    @ViewBuilder
    private func emptyState(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: SolSpacing.sm) {
            IconContainer(systemName: icon, variant: .tinted, size: 56, iconSize: 22)
            Text(title)
                .font(.solBodyBold)
                .foregroundStyle(Color.solForeground)
            Text(subtitle)
                .font(.solCaption)
                .foregroundStyle(Color.solMuted)
                .multilineTextAlignment(.center)
        }
        .padding(SolSpacing.xl)
        .frame(maxWidth: .infinity)
        .solCard()
    }
}

// MARK: - Row components (separate for reuse)

struct ObligationRow: View {
    let obligation: Obligation

    var body: some View {
        HStack(spacing: SolSpacing.md) {
            IconContainer(
                systemName: iconForKind(obligation.kind),
                variant: variantForKind(obligation.kind),
                size: 36,
                iconSize: 14
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(obligation.name)
                    .font(.solBody)
                    .foregroundStyle(Color.solForeground)
                Text(dueDateText)
                    .font(.solCaption)
                    .foregroundStyle(isUrgent ? Color.solWarning : Color.solMuted)
            }

            Spacer()

            Text("\(obligation.amount.amount) RON")
                .font(.solMonoMD)
                .foregroundStyle(Color.solForeground)
        }
        .padding(SolSpacing.base)
        .solCard()
    }

    private var dayOfMonth: Int {
        Calendar.current.component(.day, from: Date())
    }

    private var daysUntil: Int {
        let due = obligation.dayOfMonth
        return due > dayOfMonth ? (due - dayOfMonth) : (30 - dayOfMonth + due)
    }

    private var isUrgent: Bool { daysUntil <= 3 }

    private var dueDateText: String {
        if isUrgent { return "Scadent în \(daysUntil) zile ⚠" }
        return "Scadent pe \(obligation.dayOfMonth)"
    }

    private func iconForKind(_ kind: ObligationKind) -> String {
        switch kind {
        case .rentMortgage: return "house.fill"
        case .utility:      return "bolt.fill"
        case .subscription: return "play.rectangle.fill"
        case .loanBank:     return "building.columns.fill"
        case .loanIFN:      return "exclamationmark.octagon.fill"
        case .bnpl:         return "creditcard.fill"
        case .insurance:    return "shield.fill"
        case .other:        return "doc.text.fill"
        }
    }

    private func variantForKind(_ kind: ObligationKind) -> IconContainer.Variant {
        switch kind {
        case .rentMortgage: return .cyan
        case .utility:      return .neon
        case .subscription: return .tinted
        case .loanBank:     return .warn
        case .loanIFN:      return .danger
        case .bnpl:         return .danger
        case .insurance:    return .cyan
        case .other:        return .tinted
        }
    }
}

struct SubscriptionRow: View {
    let subscription: Subscription

    var body: some View {
        HStack(spacing: SolSpacing.md) {
            IconContainer(
                systemName: "play.rectangle.fill",
                variant: subscription.isGhost ? .danger : .neon,
                size: 36,
                iconSize: 14
            )

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: SolSpacing.xs) {
                    Text(subscription.name)
                        .font(.solBody)
                        .foregroundStyle(Color.solForeground)
                    if subscription.isGhost {
                        LabelBadge(title: "GHOST", color: .solDestructive)
                    }
                }
                Text(lastUsedText)
                    .font(.solCaption)
                    .foregroundStyle(subscription.isGhost ? Color.solDestructive : Color.solMuted)
            }

            Spacer()

            Text("\(subscription.amountMonthly.amount) RON/lună")
                .font(.solMonoMD)
                .foregroundStyle(subscription.isGhost ? Color.solDestructive : Color.solForeground)
        }
        .padding(SolSpacing.base)
        .solCard()
    }

    private var lastUsedText: String {
        guard let days = subscription.lastUsedDaysAgo else {
            return "Activ"
        }
        if days == 0 { return "Folosit azi" }
        if days < 7 { return "Folosit acum \(days) zile" }
        if subscription.isGhost { return "Nefolosit de \(days) zile" }
        return "Folosit acum \(days / 7) săptămâni"
    }
}

struct TransactionRow: View {
    let transaction: SolomonCore.Transaction

    var body: some View {
        HStack(spacing: SolSpacing.md) {
            ZStack {
                Circle()
                    .fill(Color.solSecondary)
                    .frame(width: 36, height: 36)
                Text(emoji)
                    .font(.system(size: 16))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.merchant ?? "Tranzacție")
                    .font(.solBody)
                    .foregroundStyle(Color.solForeground)
                Text(transaction.category.displayNameRO)
                    .font(.solCaption)
                    .foregroundStyle(Color.solMuted)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(amountText)
                    .font(.solMonoMD)
                    .foregroundStyle(transaction.isOutgoing ? Color.solForeground : Color.solPrimary)
                Text(dateText)
                    .font(.solCaption)
                    .foregroundStyle(Color.solMuted)
            }
        }
        .padding(SolSpacing.base)
        .solCard()
    }

    private var amountText: String {
        let prefix = transaction.isOutgoing ? "−" : "+"
        return "\(prefix)\(transaction.amount.amount) RON"
    }

    private var emoji: String {
        switch transaction.category {
        case .foodDelivery: return "🛵"
        case .foodDining:   return "🍽"
        case .foodGrocery:  return "🛒"
        case .transport:    return "🚗"
        case .utilities:    return "⚡️"
        case .rentMortgage: return "🏠"
        case .subscriptions: return "📺"
        case .shoppingOnline: return "📦"
        case .shoppingOffline: return "🛍"
        case .entertainment: return "🎬"
        case .health:       return "🏥"
        case .loansIFN, .loansBank, .bnpl: return "💳"
        case .travel:       return "✈️"
        case .savings:      return "🐷"
        case .unknown:      return transaction.isIncoming ? "💰" : "💸"
        }
    }

    private var dateText: String {
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        f.locale = Locale(identifier: "ro_RO")
        return f.string(from: transaction.date)
    }
}

// MARK: - WalletViewModel (CoreData wired)

@MainActor
final class WalletViewModel: ObservableObject {

    @Published var obligations: [Obligation] = []
    @Published var subscriptions: [Subscription] = []
    @Published var transactions: [SolomonCore.Transaction] = []

    private var transactionRepo: (any TransactionRepository)?
    private var obligationRepo: (any ObligationRepository)?
    private var subscriptionRepo: (any SubscriptionRepository)?
    private let usageDetector = SubscriptionUsageDetector()

    func configure(persistence: SolomonPersistenceController) {
        let ctx = persistence.container.viewContext
        self.transactionRepo  = CoreDataTransactionRepository(context: ctx)
        self.obligationRepo   = CoreDataObligationRepository(context: ctx)
        self.subscriptionRepo = CoreDataSubscriptionRepository(context: ctx)
    }

    func load() async {
        obligations  = (try? obligationRepo?.fetchAll()) ?? []
        let allTx = (try? transactionRepo?.fetchAll()) ?? []
        let rawSubs = (try? subscriptionRepo?.fetchAll()) ?? []
        // Auto-enrich lastUsedDaysAgo prin matching tranzacții
        subscriptions = usageDetector.enrichWithUsage(subscriptions: rawSubs, transactions: allTx)
        transactions = (try? transactionRepo?.fetchRecent(limit: 50)) ?? []
    }

    // MARK: - Computed totals

    var obligationsTotalRON: Int {
        obligations.reduce(0) { $0 + $1.amount.amount }
    }

    var obligationsTotalFormatted: String {
        RomanianMoneyFormatter.format(Money(obligationsTotalRON))
    }

    var obligationsPercentText: String {
        // Heuristic: assuming midpoint salary ~5000 RON
        guard obligationsTotalRON > 0 else { return "" }
        let pct = Int(Double(obligationsTotalRON) / 5000.0 * 100)
        return "\(pct)% din venit"
    }

    var obligationsKind: StatusBadge.Kind {
        guard obligationsTotalRON > 0 else { return .neutral }
        let pct = Double(obligationsTotalRON) / 5000.0
        if pct < 0.4 { return .success }
        if pct < 0.6 { return .warning }
        return .danger
    }

    var subscriptionsTotalRON: Int {
        subscriptions.reduce(0) { $0 + $1.amountMonthly.amount }
    }

    var subscriptionsTotalFormatted: String {
        RomanianMoneyFormatter.format(Money(subscriptionsTotalRON))
    }

    var ghostSavingsPotential: Int {
        subscriptions.filter { $0.isGhost }.reduce(0) { $0 + $1.amountMonthly.amount }
    }
}

// MARK: - Preview

#Preview {
    WalletView()
}
