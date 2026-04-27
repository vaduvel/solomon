import SwiftUI
import SolomonCore
import SolomonStorage

// MARK: - TodayView (Tab 1 — Azi)
//
// Ecranul principal Solomon. Afișează:
//  • Salut personalizat + balanță Safe-to-Spend
//  • Momentul Solomon curent (MomentCard)
//  • Buton „Pot să-mi permit?" — acces rapid la CanIAfford
//  • Feed scurt de momente recente

struct TodayView: View {

    // MARK: - View Model

    @StateObject private var vm = TodayViewModel()

    // MARK: - Notification ingestion (live transactions from Shortcuts)

    @ObservedObject private var ingestion = NotificationIngestionService.shared
    @State private var showManualEntry = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.solCanvas.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: SolSpacing.sectionGap) {

                        // Hero — Safe to Spend
                        heroSection

                        // Moment curent Solomon
                        if let moment = vm.currentMoment {
                            sectionHeader("Solomon spune")
                            MomentCard(moment: moment)
                                .padding(.horizontal, SolSpacing.screenHorizontal)
                        }

                        // Acțiune rapidă — Pot?
                        canIAffordQuickAction

                        // Momente recente
                        if !vm.recentMoments.isEmpty {
                            sectionHeader("Recent")
                            recentMomentsList
                        }

                        // Bottom spacer pentru tab bar
                        Spacer(minLength: SolSpacing.hh)
                    }
                    .padding(.top, SolSpacing.xl)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    addManualButton
                }
                ToolbarItem(placement: .principal) {
                    solomonWordmark
                }
                ToolbarItem(placement: .topBarTrailing) {
                    notificationButton
                }
            }
            .ingestionToast(transaction: ingestionBinding)
            .sheet(isPresented: $showManualEntry) {
                ManualTransactionView()
            }
        }
        .task {
            vm.configure(persistence: SolomonPersistenceController.shared)
            await vm.load()
        }
    }

    // MARK: - Ingestion binding (read service, write clears it)

    private var ingestionBinding: Binding<SolomonCore.Transaction?> {
        Binding(
            get: { ingestion.lastIngested },
            set: { newValue in
                if newValue == nil { ingestion.clearLastIngested() }
            }
        )
    }

    // MARK: - Sub-views

    @ViewBuilder
    private var heroSection: some View {
        VStack(spacing: SolSpacing.sm) {
            Text(vm.greetingText)
                .font(.solBodyMD)
                .foregroundStyle(Color.solTextSecondary)

            Text(vm.safeToSpendFormatted)
                .font(.solDisplayLG)
                .foregroundStyle(Color.solMint)
                .monospacedDigit()

            Text("disponibil azi")
                .font(.solCaption)
                .foregroundStyle(Color.solTextMuted)

            if let perDay = vm.perDayFormatted {
                Text(perDay)
                    .font(.solMonoSM)
                    .foregroundStyle(Color.solTextMuted)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, SolSpacing.xl)
    }

    @ViewBuilder
    private var canIAffordQuickAction: some View {
        VStack(spacing: SolSpacing.base) {
            sectionHeader("Vrei să cumperi ceva?")

            SolomonButton("Pot să-mi permit?") {
                vm.showCanIAfford = true
            }
            .padding(.horizontal, SolSpacing.screenHorizontal)
        }
        .sheet(isPresented: $vm.showCanIAfford) {
            CanIAffordSheet()
        }
    }

    @ViewBuilder
    private var recentMomentsList: some View {
        LazyVStack(spacing: SolSpacing.base) {
            ForEach(vm.recentMoments) { moment in
                MomentCard(moment: moment)
            }
        }
        .padding(.horizontal, SolSpacing.screenHorizontal)
    }

    @ViewBuilder
    private var solomonWordmark: some View {
        Text("Solomon")
            .font(.solHeadingMD)
            .foregroundStyle(Color.solTextPrimary)
    }

    @ViewBuilder
    private var notificationButton: some View {
        Button {
            // TODO: Navigate to notifications
        } label: {
            Image(systemName: vm.hasUnreadAlert ? "bell.badge.fill" : "bell")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(vm.hasUnreadAlert ? Color.solMint : Color.solTextSecondary)
        }
    }

    @ViewBuilder
    private var addManualButton: some View {
        Button {
            showManualEntry = true
        } label: {
            Image(systemName: "plus.circle")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color.solTextSecondary)
        }
    }

    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.solCaption)
                .foregroundStyle(Color.solTextMuted)
                .textCase(.uppercase)
                .tracking(1.2)
            Spacer()
        }
        .padding(.horizontal, SolSpacing.screenHorizontal)
    }
}

// MARK: - CanIAfford Quick Sheet (placeholder)

struct CanIAffordSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.solCanvas.ignoresSafeArea()
                VStack(spacing: SolSpacing.xl) {
                    Text("Cât costă?")
                        .font(.solHeadingXL)
                        .foregroundStyle(Color.solTextPrimary)

                    TextField("ex: pizza de la Glovo", text: $query)
                        .font(.solBodyLG)
                        .foregroundStyle(Color.solTextPrimary)
                        .padding(SolSpacing.base)
                        .solCard()
                        .padding(.horizontal, SolSpacing.screenHorizontal)

                    SolomonButton("Solomon, pot?") {
                        dismiss()
                    }
                    .padding(.horizontal, SolSpacing.screenHorizontal)

                    Spacer()
                }
                .padding(.top, SolSpacing.xxl)
            }
            .navigationTitle("Pot să-mi permit?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Anulează") { dismiss() }
                        .foregroundStyle(Color.solTextSecondary)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationBackground(Color.solSurface)
    }
}

// MARK: - Preview

#Preview {
    TodayView()
}
