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
    @State private var showAlerts = false

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

                    // Budget tight warning
                    if vm.isBudgetTight {
                        tightBudgetBanner
                    }

                    // Current moment (Solomon AI insight)
                    if vm.isLoadingMoment {
                        momentLoadingPlaceholder
                    } else if let moment = vm.currentMoment {
                        VStack(alignment: .leading, spacing: SolSpacing.sm) {
                            Text("Solomon spune")
                                .solSectionHeader()
                                .padding(.horizontal, SolSpacing.lg)

                            MomentCard(moment: moment)
                                .padding(.horizontal, SolSpacing.lg)
                        }
                    }

                    // Recent moments history
                    if vm.recentMoments.count > 1 {
                        recentMomentsSection
                    }

                    Spacer(minLength: SolSpacing.xxxl)
                }
                .padding(.top, SolSpacing.base)
            }
            .background(Color.solCanvas)
            .navigationTitle("Solomon")
            .navigationBarTitleDisplayMode(.large)
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
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.light()
                        showAlerts = true
                        vm.hasUnreadAlert = false
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
            .sheet(isPresented: $showAlerts) {
                AlertsSheet(moments: vm.recentMoments, currentMoment: vm.currentMoment)
                    .solStandardSheet()
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

    // MARK: - Budget tight banner

    @ViewBuilder
    private var tightBudgetBanner: some View {
        HStack(spacing: SolSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.solWarning)
                .font(.subheadline)
            Text("Buget strâns — grijă la cheltuieli mici")
                .font(.footnote.weight(.medium))
                .foregroundStyle(Color.solWarning)
            Spacer()
        }
        .padding(.horizontal, SolSpacing.base)
        .padding(.vertical, SolSpacing.sm)
        .background(Color.solWarning.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: SolRadius.lg, style: .continuous))
        .padding(.horizontal, SolSpacing.lg)
    }

    // MARK: - Moment loading placeholder

    @ViewBuilder
    private var momentLoadingPlaceholder: some View {
        VStack(alignment: .leading, spacing: SolSpacing.sm) {
            Text("Solomon spune")
                .solSectionHeader()
                .padding(.horizontal, SolSpacing.lg)

            RoundedRectangle(cornerRadius: SolRadius.xl, style: .continuous)
                .fill(Color.solCard)
                .frame(height: 120)
                .overlay(
                    HStack(spacing: SolSpacing.sm) {
                        ProgressView()
                            .tint(Color.solPrimary)
                        Text("Analizez datele tale…")
                            .font(.subheadline)
                            .foregroundStyle(Color.solMuted)
                    }
                )
                .padding(.horizontal, SolSpacing.lg)
        }
    }

    // MARK: - Recent moments

    @ViewBuilder
    private var recentMomentsSection: some View {
        VStack(alignment: .leading, spacing: SolSpacing.sm) {
            Text("Istoric")
                .solSectionHeader()
                .padding(.horizontal, SolSpacing.lg)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: SolSpacing.sm) {
                    ForEach(vm.recentMoments.dropFirst()) { moment in
                        VStack(alignment: .leading, spacing: SolSpacing.xs) {
                            HStack(spacing: SolSpacing.xs) {
                                Image(systemName: moment.systemIconName)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(moment.accentColor)
                                Text(moment.timeAgoString)
                                    .font(.caption)
                                    .foregroundStyle(Color.solMuted)
                            }
                            Text(moment.title)
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(Color.solForeground)
                                .lineLimit(1)
                            Text(moment.llmResponse)
                                .font(.caption)
                                .foregroundStyle(Color.solMuted)
                                .lineLimit(2)
                        }
                        .padding(SolSpacing.base)
                        .frame(width: 200)
                        .background(Color.solCard)
                        .clipShape(RoundedRectangle(cornerRadius: SolRadius.lg, style: .continuous))
                    }
                }
                .padding(.horizontal, SolSpacing.lg)
            }
        }
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
