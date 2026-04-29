import SwiftUI
import SolomonCore
import SolomonStorage

// MARK: - TodayView (Tab 1 — Acasă)
//
// Transpunere 1:1 din Solomon DS / wallet.html (Claude Design)
// Layout: MeshBackground → AppBar → HeroCard (Safe to Spend) →
//         InsightCard (Solomon spune) → Stats grid → CONTURI list

struct TodayView: View {

    @State private var vm = TodayViewModel()
    @State private var ingestion = NotificationIngestionService.shared
    @State private var showManualEntry = false
    @State private var showCanIAfford = false
    @State private var showAlerts = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                MeshBackground(
                    topLeftAccent: .mint,
                    midRightAccent: .blue,
                    bottomLeftAccent: .violet
                )

                ScrollView {
                    VStack(spacing: SolSpacing.base) {

                        // ── App bar (brand + greeting + actions)
                        SolAppBar(
                            brand: "SOLOMON",
                            greeting: vm.userName.isEmpty ? "Bună" : "Bună, \(vm.userName)"
                        ) {
                            SolIconButton(systemName: "magnifyingglass") {
                                showCanIAfford = true
                            }
                            SolIconButton(
                                systemName: "bell",
                                hasDot: vm.hasUnreadAlert
                            ) {
                                showAlerts = true
                                vm.hasUnreadAlert = false
                            }
                        }

                        // ── Hero — Safe to Spend
                        heroCard

                        // ── Insight — Solomon spune (current moment)
                        if vm.isLoadingMoment {
                            insightLoadingPlaceholder
                        } else if let moment = vm.currentMoment {
                            momentInsightCard(moment: moment)
                        } else {
                            emptyInsightCard
                        }

                        // ── Stats grid (2x2) — Următoarea plată + Pattern
                        statsGrid

                        // ── Section: CONTURI
                        SolSectionHeaderRow("CONTURI", meta: "1 activ")
                        accountsList

                        // ── Recent moments rail
                        if vm.recentMoments.count > 1 {
                            SolSectionHeaderRow("ISTORIC", meta: "ultimele")
                            recentMomentsRail
                        }

                        Spacer(minLength: SolSpacing.xxxl)
                    }
                    .padding(.horizontal, SolSpacing.xl)
                    .padding(.top, SolSpacing.sm)
                }
                .scrollContentBackground(.hidden)
            }
            .toolbar(.hidden, for: .navigationBar)
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

    // MARK: - Hero Card

    @ViewBuilder
    private var heroCard: some View {
        SolHeroCard(accent: vm.isBudgetTight ? .amber : .mint) {
            VStack(alignment: .leading, spacing: 0) {
                SolHeroLabel("DISPONIBIL LIBER · \(vm.daysUntilPayday) ZILE")
                    .padding(.top, SolSpacing.xs)

                SolHeroAmount(
                    amount: vm.safeToSpendAmountFormatted,
                    decimals: ",00",
                    currency: "RON",
                    accent: vm.isBudgetTight ? .amber : .mint
                )
                .padding(.top, 6)

                HStack(spacing: 8) {
                    Text("≈ \(vm.perDayRON) RON/zi")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.white.opacity(0.55))
                    Circle().fill(Color.white.opacity(0.25)).frame(width: 3, height: 3)
                    Text("până \(vm.paydayDateFormatted)")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.white.opacity(0.55))
                }
                .padding(.top, 6)
                .padding(.bottom, 18)

                // Allocation bar (Obligații / Savings / Buffer / Rest)
                SolAllocationBar(
                    segments: allocationSegments,
                    height: 7
                )
                .padding(.bottom, 10)

                // Legend
                HStack(spacing: 0) {
                    legendItem(color: .solMintExact, label: "Obligații", value: 1500)
                    Spacer()
                    legendItem(color: .solBlueExact, label: "Liber", value: vm.safeToSpendRON)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } badge: {
            SolHeroBadge("SAFE TO SPEND", accent: vm.isBudgetTight ? .amber : .mint)
        }
    }

    /// Calculează segmentele alocației pe baza datelor din ViewModel.
    private var allocationSegments: [SolAllocationBar.Segment] {
        let total = max(1, vm.safeToSpendRON + vm.spentThisMonthRON + 1500)
        return [
            .init(
                fraction: CGFloat(1500) / CGFloat(total),
                gradient: SolAccent.mint.primaryButtonGradient,
                glowColor: .solMintExact.opacity(0.4)
            ),
            .init(
                fraction: CGFloat(vm.spentThisMonthRON) / CGFloat(total),
                gradient: SolAccent.amber.primaryButtonGradient,
                glowColor: nil
            ),
            .init(
                fraction: CGFloat(vm.safeToSpendRON) / CGFloat(total),
                gradient: SolAccent.blue.primaryButtonGradient,
                glowColor: nil
            )
        ]
    }

    @ViewBuilder
    private func legendItem(color: Color, label: String, value: Int) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 5, height: 5)
            Text("\(label) \(value)")
                .font(.system(size: 11))
                .foregroundStyle(Color.white.opacity(0.5))
                .monospacedDigit()
        }
    }

    // MARK: - Insight (current moment)

    @ViewBuilder
    private func momentInsightCard(moment: DisplayMoment) -> some View {
        SolInsightCard(
            icon: moment.systemIconName,
            label: "SOLOMON · INSIGHT",
            timestamp: moment.timeAgoString,
            accent: accentFor(moment: moment)
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text(moment.llmResponse)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.white.opacity(0.85))
                    .lineSpacing(2)
                    .lineLimit(4)

                HStack(spacing: 8) {
                    SolPrimaryButton("Vezi audit", accent: .mint) {
                        showAlerts = true
                    }
                    SolSecondaryButton("Mai târziu") {}
                }
            }
        }
    }

    private func accentFor(moment: DisplayMoment) -> SolAccent {
        switch moment.momentTypeRaw {
        case "spiral_alert":         return .rose
        case "upcoming_obligation":  return .amber
        case "can_i_afford":         return .blue
        default:                     return .mint
        }
    }

    @ViewBuilder
    private var insightLoadingPlaceholder: some View {
        SolInsightCard(
            icon: "sparkles",
            label: "SOLOMON · ANALIZEAZĂ",
            timestamp: nil,
            accent: .mint
        ) {
            HStack(spacing: 10) {
                ProgressView().tint(Color.solMintExact)
                Text("Caut tipare în datele tale…")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.white.opacity(0.7))
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private var emptyInsightCard: some View {
        SolInsightCard(
            icon: "sparkles",
            label: "SOLOMON · INSIGHT",
            timestamp: nil,
            accent: .mint
        ) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Solomon ascultă, dar are nevoie de date. Adaugă manual prima ta tranzacție sau configurează Shortcut-ul.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.white.opacity(0.85))
                    .lineSpacing(2)

                HStack(spacing: 8) {
                    SolPrimaryButton("Adaugă tranzacție") {
                        showManualEntry = true
                    }
                }
            }
        }
    }

    // MARK: - Stats Grid (2x2)

    @ViewBuilder
    private var statsGrid: some View {
        HStack(spacing: 10) {
            SolStatCard(
                label: "URM. PLATĂ",
                name: "Următoarea",
                value: "\(vm.formatRON(1500))",
                meta: vm.daysUntilPayday > 3 ? "în \(vm.daysUntilPayday) zile" : "în curând",
                metaAccent: .amber,
                icon: "calendar",
                iconAccent: .blue
            )

            SolStatCard(
                label: "CHELTUIT",
                name: "luna asta",
                value: "\(vm.formatRON(vm.spentThisMonthRON))",
                meta: vm.isBudgetTight ? "buget strâns" : "în limită",
                metaAccent: vm.isBudgetTight ? .rose : .mint,
                icon: "chart.line.uptrend.xyaxis",
                iconAccent: .amber
            )
        }
    }

    // MARK: - Accounts list

    @ViewBuilder
    private var accountsList: some View {
        SolListCard {
            SolListRow(
                title: "Solomon Wallet",
                subtitle: "estimat · \(vm.formatRON(vm.safeToSpendRON + vm.spentThisMonthRON))",
                onTap: {}
            ) {
                SolBrandLogo(.cash, size: 38)
            } trailing: {
                VStack(alignment: .trailing, spacing: 1) {
                    Text(vm.safeToSpendAmountFormatted)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .monospacedDigit()
                        .tracking(-0.3)
                    Text("RON")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.35))
                }
            }
        }
    }

    // MARK: - Recent moments rail (horizontal)

    @ViewBuilder
    private var recentMomentsRail: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(vm.recentMoments.dropFirst()) { moment in
                    historicCard(moment: moment)
                }
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private func historicCard(moment: DisplayMoment) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(accentFor(moment: moment).iconGradient)
                        .overlay(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .stroke(accentFor(moment: moment).color.opacity(0.3), lineWidth: 1)
                        )
                    Image(systemName: moment.systemIconName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(accentFor(moment: moment).color)
                }
                .frame(width: 28, height: 28)

                Text(moment.timeAgoString.uppercased())
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.4))
                    .tracking(1.2)
                Spacer()
            }

            Text(moment.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.white)
                .lineLimit(1)

            Text(moment.llmResponse)
                .font(.system(size: 12))
                .foregroundStyle(Color.white.opacity(0.55))
                .lineLimit(3)
                .lineSpacing(1.5)
        }
        .padding(14)
        .frame(width: 220, height: 156, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.035), Color.white.opacity(0.015)],
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
