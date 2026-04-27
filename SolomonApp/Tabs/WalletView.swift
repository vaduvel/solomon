import SwiftUI

// MARK: - WalletView (Tab 3 — Portofel)
//
// Afișează obligațiile active, abonamentele detectate, tranzacții recente.
// Faza 10: layout complet cu date mock. Faza 11+: SolomonStorage real.

struct WalletView: View {

    @StateObject private var vm = WalletViewModel()
    @State private var selectedSegment = 0

    var body: some View {
        NavigationStack {
            ZStack {
                Color.solCanvas.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Segment control
                    segmentControl
                        .padding(.horizontal, SolSpacing.screenHorizontal)
                        .padding(.vertical, SolSpacing.base)

                    // Conținut per segment
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: SolSpacing.sectionGap) {
                            switch selectedSegment {
                            case 0: obligationsSection
                            case 1: subscriptionsSection
                            default: transactionsSection
                            }
                            Spacer(minLength: SolSpacing.hh)
                        }
                        .padding(.top, SolSpacing.base)
                    }
                }
            }
            .navigationTitle("Portofel")
            .navigationBarTitleDisplayMode(.large)
        }
        .task { await vm.load() }
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
                        .font(.solBodyMD)
                        .foregroundStyle(selectedSegment == idx ? Color.solCanvas : Color.solTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, SolSpacing.sm)
                        .background(
                            selectedSegment == idx
                                ? Color.solMint
                                : Color.clear
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(SolSpacing.xs)
        .background(Color.solSurface)
        .clipShape(Capsule())
    }

    // MARK: - Obligații

    @ViewBuilder
    private var obligationsSection: some View {
        VStack(spacing: SolSpacing.base) {
            // Total obligații
            HStack {
                VStack(alignment: .leading, spacing: SolSpacing.xs) {
                    Text("Total lunar rezervat")
                        .font(.solCaption)
                        .foregroundStyle(Color.solTextMuted)
                    Text("2.295 RON")
                        .font(.solHeadingXL)
                        .foregroundStyle(Color.solTextPrimary)
                        .monospacedDigit()
                }
                Spacer()
                VStack(alignment: .trailing, spacing: SolSpacing.xs) {
                    Text("44% din venit")
                        .font(.solCaption)
                        .foregroundStyle(Color.solWarning)
                    Text("⚠ Monitorizez")
                        .font(.solCaption)
                        .foregroundStyle(Color.solWarning)
                }
            }
            .padding(SolSpacing.xl)
            .solCard()
            .padding(.horizontal, SolSpacing.screenHorizontal)

            // Lista obligații
            VStack(spacing: SolSpacing.sm) {
                ForEach(vm.obligations) { obl in
                    obligationRow(obl)
                }
            }
            .padding(.horizontal, SolSpacing.screenHorizontal)

            // Buton adăugare
            SolomonButton("+ Adaugă obligație", style: .secondary) {
                // TODO: Sheet add obligation
            }
            .padding(.horizontal, SolSpacing.screenHorizontal)
        }
    }

    @ViewBuilder
    private func obligationRow(_ obl: ObligationItem) -> some View {
        HStack(spacing: SolSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: SolRadius.sm, style: .continuous)
                    .fill(Color.solInfo.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: obl.iconName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.solInfo)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(obl.name)
                    .font(.solBodyMD)
                    .foregroundStyle(Color.solTextPrimary)
                Text(obl.dueDateFormatted)
                    .font(.solCaption)
                    .foregroundStyle(obl.isUrgent ? Color.solWarning : Color.solTextMuted)
            }

            Spacer()

            Text(obl.amountFormatted)
                .font(.solMonoSM)
                .foregroundStyle(Color.solTextPrimary)
        }
        .padding(SolSpacing.md)
        .solCard()
    }

    // MARK: - Abonamente

    @ViewBuilder
    private var subscriptionsSection: some View {
        VStack(spacing: SolSpacing.base) {
            // Total abonamente
            HStack {
                VStack(alignment: .leading, spacing: SolSpacing.xs) {
                    Text("Total abonamente / lună")
                        .font(.solCaption)
                        .foregroundStyle(Color.solTextMuted)
                    Text("320 RON")
                        .font(.solHeadingXL)
                        .foregroundStyle(Color.solMint)
                        .monospacedDigit()
                }
                Spacer()
                VStack(alignment: .trailing, spacing: SolSpacing.xs) {
                    Text("Potențial economii")
                        .font(.solCaption)
                        .foregroundStyle(Color.solTextMuted)
                    Text("104 RON/lună")
                        .font(.solMonoSM)
                        .foregroundStyle(Color.solMint)
                }
            }
            .padding(SolSpacing.xl)
            .solCard()
            .padding(.horizontal, SolSpacing.screenHorizontal)

            VStack(spacing: SolSpacing.sm) {
                ForEach(vm.subscriptions) { sub in
                    subscriptionRow(sub)
                }
            }
            .padding(.horizontal, SolSpacing.screenHorizontal)
        }
    }

    @ViewBuilder
    private func subscriptionRow(_ sub: SubscriptionItem) -> some View {
        HStack(spacing: SolSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: SolRadius.sm, style: .continuous)
                    .fill(sub.isGhost ? Color.solDanger.opacity(0.12) : Color.solMintDim.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(sub.isGhost ? Color.solDanger : Color.solMintDim)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: SolSpacing.xs) {
                    Text(sub.name)
                        .font(.solBodyMD)
                        .foregroundStyle(Color.solTextPrimary)
                    if sub.isGhost {
                        Text("GHOST")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color.solDanger)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.solDanger.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                Text(sub.lastUsedFormatted)
                    .font(.solCaption)
                    .foregroundStyle(Color.solTextMuted)
            }

            Spacer()

            Text(sub.amountFormatted)
                .font(.solMonoSM)
                .foregroundStyle(sub.isGhost ? Color.solDanger : Color.solTextPrimary)
        }
        .padding(SolSpacing.md)
        .solCard()
    }

    // MARK: - Tranzacții

    @ViewBuilder
    private var transactionsSection: some View {
        VStack(spacing: SolSpacing.base) {
            VStack(spacing: SolSpacing.sm) {
                ForEach(vm.transactions) { tx in
                    transactionRow(tx)
                }
            }
            .padding(.horizontal, SolSpacing.screenHorizontal)
        }
    }

    @ViewBuilder
    private func transactionRow(_ tx: TransactionItem) -> some View {
        HStack(spacing: SolSpacing.md) {
            ZStack {
                Circle()
                    .fill(Color.solSurface)
                    .frame(width: 36, height: 36)
                Text(tx.emoji)
                    .font(.system(size: 16))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(tx.merchant)
                    .font(.solBodyMD)
                    .foregroundStyle(Color.solTextPrimary)
                Text(tx.categoryFormatted)
                    .font(.solCaption)
                    .foregroundStyle(Color.solTextMuted)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(tx.amountFormatted)
                    .font(.solMonoSM)
                    .foregroundStyle(tx.isDebit ? Color.solTextPrimary : Color.solMint)
                Text(tx.dateFormatted)
                    .font(.solCaption)
                    .foregroundStyle(Color.solTextMuted)
            }
        }
        .padding(SolSpacing.md)
        .solCard()
    }
}

// MARK: - Supporting models (Faza 10 mock)

struct ObligationItem: Identifiable {
    let id = UUID()
    let name: String
    let amount: Double
    let dueDay: Int
    let iconName: String

    var isUrgent: Bool { dueDay <= 3 }
    var amountFormatted: String { "\(Int(amount)) RON" }
    var dueDateFormatted: String {
        isUrgent ? "Scadent în \(dueDay) zile ⚠" : "Scadent pe \(dueDay)"
    }
}

struct SubscriptionItem: Identifiable {
    let id = UUID()
    let name: String
    let amount: Double
    let lastUsedDaysAgo: Int
    let isGhost: Bool

    var amountFormatted: String { "\(Int(amount)) RON/lună" }
    var lastUsedFormatted: String {
        isGhost ? "Nefolosit de \(lastUsedDaysAgo)+ zile" : "Activ"
    }
}

struct TransactionItem: Identifiable {
    let id = UUID()
    let merchant: String
    let amount: Double
    let category: String
    let emoji: String
    let date: Date
    let isDebit: Bool

    var amountFormatted: String {
        (isDebit ? "- " : "+ ") + "\(Int(amount)) RON"
    }
    var categoryFormatted: String { category }
    var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        formatter.locale = Locale(identifier: "ro_RO")
        return formatter.string(from: date)
    }
}

// MARK: - WalletViewModel

@MainActor
final class WalletViewModel: ObservableObject {

    @Published var obligations: [ObligationItem] = []
    @Published var subscriptions: [SubscriptionItem] = []
    @Published var transactions: [TransactionItem] = []

    func load() async {
        obligations = [
            ObligationItem(name: "Chirie", amount: 1500, dueDay: 1, iconName: "house.fill"),
            ObligationItem(name: "Curent Enel (est.)", amount: 280, dueDay: 2, iconName: "bolt.fill"),
            ObligationItem(name: "Internet Digi", amount: 65, dueDay: 5, iconName: "wifi"),
            ObligationItem(name: "Sală fitness", amount: 150, dueDay: 10, iconName: "figure.run"),
            ObligationItem(name: "Asigurare CASCO", amount: 171, dueDay: 15, iconName: "car.fill"),
        ]

        subscriptions = [
            SubscriptionItem(name: "Netflix", amount: 40, lastUsedDaysAgo: 5, isGhost: false),
            SubscriptionItem(name: "Spotify", amount: 25, lastUsedDaysAgo: 2, isGhost: false),
            SubscriptionItem(name: "HBO Max", amount: 35, lastUsedDaysAgo: 62, isGhost: true),
            SubscriptionItem(name: "App Calm", amount: 29, lastUsedDaysAgo: 90, isGhost: true),
            SubscriptionItem(name: "YouTube Premium", amount: 19, lastUsedDaysAgo: 1, isGhost: false),
        ]

        transactions = [
            TransactionItem(merchant: "Glovo", amount: 87, category: "Livrare mâncare", emoji: "🛵", date: .now, isDebit: true),
            TransactionItem(merchant: "Kaufland", amount: 134, category: "Supermarket", emoji: "🛒", date: .now.addingTimeInterval(-86400), isDebit: true),
            TransactionItem(merchant: "Salariu", amount: 5200, category: "Venit", emoji: "💰", date: .now.addingTimeInterval(-172800), isDebit: false),
            TransactionItem(merchant: "Uber", amount: 23, category: "Transport", emoji: "🚗", date: .now.addingTimeInterval(-259200), isDebit: true),
            TransactionItem(merchant: "eMAG", amount: 319, category: "Shopping", emoji: "📦", date: .now.addingTimeInterval(-345600), isDebit: true),
        ]
    }
}

// MARK: - Preview

#Preview {
    WalletView()
}
