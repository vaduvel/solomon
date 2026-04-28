import SwiftUI
import SolomonCore
import SolomonStorage

// MARK: - TodayView (Tab 1 — HIG aligned)
//
// Pattern HIG: NavigationStack cu .large title display, ScrollView cu hero +
// glass card + insights, toolbar cu manual entry + notifications.

struct TodayView: View {

    @StateObject private var vm = TodayViewModel()
    @ObservedObject private var ingestion = NotificationIngestionService.shared
    @State private var showManualEntry = false
    @State private var showCanIAfford = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SolSpacing.xl) {

                    // Greeting
                    greetingHeader

                    // Hero — Safe to Spend
                    heroCard

                    // Quick action — Pot?
                    canIAffordCTA

                    // Current moment (Solomon AI insight)
                    if let moment = vm.currentMoment {
                        VStack(alignment: .leading, spacing: SolSpacing.sm) {
                            Text("Solomon spune")
                                .solSectionHeader()
                                .padding(.horizontal, SolSpacing.lg)

                            MomentCard(moment: moment)
                                .padding(.horizontal, SolSpacing.lg)
                        }
                    }

                    Spacer(minLength: SolSpacing.xxxl)
                }
                .padding(.top, SolSpacing.sm)
            }
            .background(Color.solCanvas)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Haptics.light()
                        showManualEntry = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.body.weight(.medium))
                            .foregroundStyle(Color.solForeground)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("Solomon")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.solForeground)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.light()
                    } label: {
                        Image(systemName: vm.hasUnreadAlert ? "bell.badge.fill" : "bell")
                            .font(.body)
                            .foregroundStyle(vm.hasUnreadAlert ? Color.solPrimary : Color.solForeground)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
            .ingestionToast(transaction: ingestionBinding)
            .sheet(isPresented: $showManualEntry) {
                ManualTransactionView().solStandardSheet()
            }
            .sheet(isPresented: $showCanIAfford) {
                CanIAffordSheet().solStandardSheet()
            }
        }
        .task {
            vm.configure(persistence: SolomonPersistenceController.shared)
            await vm.load()
        }
    }

    // MARK: - Greeting

    @ViewBuilder
    private var greetingHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(vm.greetingText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if !vm.userName.isEmpty {
                Text(vm.userName)
                    .font(.title.weight(.bold))
                    .foregroundStyle(Color.solForeground)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, SolSpacing.lg)
    }

    // MARK: - Hero Safe-to-Spend

    @ViewBuilder
    private var heroCard: some View {
        VStack(spacing: SolSpacing.xs) {
            Text("Safe to Spend")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)

            Text(vm.safeToSpendFormatted)
                .font(.solHero)
                .foregroundStyle(LinearGradient.solHero)
                .monospacedDigit()
                .contentTransition(.numericText())

            if let perDay = vm.perDayFormatted {
                Text(perDay)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, SolSpacing.xl)
        .solGlassCard()
        .padding(.horizontal, SolSpacing.lg)
    }

    // MARK: - CanIAfford CTA

    @ViewBuilder
    private var canIAffordCTA: some View {
        Button {
            Haptics.medium()
            showCanIAfford = true
        } label: {
            HStack(spacing: SolSpacing.md) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.solCanvas)
                    .symbolRenderingMode(.hierarchical)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Pot să-mi permit?")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.solCanvas)
                    Text("Întreabă Solomon înainte să cumperi")
                        .font(.footnote)
                        .foregroundStyle(Color.solCanvas.opacity(0.7))
                }
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.solCanvas)
            }
            .padding(.horizontal, SolSpacing.base)
            .frame(height: 64)
            .background(LinearGradient.solPrimaryCTA)
            .clipShape(RoundedRectangle(cornerRadius: SolRadius.xl, style: .continuous))
            .shadow(color: Color.solPrimary.opacity(0.30), radius: 16, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, SolSpacing.lg)
    }

    // MARK: - Ingestion binding

    private var ingestionBinding: Binding<SolomonCore.Transaction?> {
        Binding(
            get: { ingestion.lastIngested },
            set: { newValue in
                if newValue == nil { ingestion.clearLastIngested() }
            }
        )
    }
}

#Preview {
    TodayView()
        .preferredColorScheme(.dark)
}
