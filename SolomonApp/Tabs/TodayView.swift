import SwiftUI
import SolomonCore
import SolomonStorage

// MARK: - TodayView (Tab 1 — v3 Editorial Premium)
//
// Design: Solomon DS · TodayView.v3.html (Claude Design)
// Layout: ambient mesh background → hero glass card → mint pill CTA →
//         editorial numbered sections (01 Solomon spune, 02 Obiectiv, 03 Istoric)

struct TodayView: View {

    @State private var vm = TodayViewModel()
    @State private var ingestion = NotificationIngestionService.shared
    @State private var showManualEntry = false
    @State private var showCanIAfford = false
    @State private var showAlerts = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Ambient mesh gradient — teal top-left, blue bottom-right (v3 design)
                ambientBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: SolSpacing.base) {

                        // Greeting (bună dimineața / Andrei)
                        greetingRow
                            .padding(.top, SolSpacing.xs)

                        // Hero — Safe to Spend (editorial glass card)
                        heroCard

                        // Tight budget banner (dacă e cazul)
                        if vm.isBudgetTight {
                            tightBudgetBanner
                        }

                        // CTA — Pot să-mi permit?
                        canIAffordCTA

                        // ─── 01 SOLOMON SPUNE ───────────────────────────
                        if vm.isLoadingMoment {
                            editorialSectionHeader(num: "01", label: "SOLOMON SPUNE", trailing: "")
                            momentLoadingPlaceholder
                        } else if let moment = vm.currentMoment {
                            editorialSectionHeader(
                                num: "01",
                                label: "SOLOMON SPUNE",
                                trailing: moment.timeAgoString
                            )
                            MomentCard(moment: moment)
                                .padding(.horizontal, SolSpacing.base)
                        } else {
                            editorialSectionHeader(num: "01", label: "SOLOMON SPUNE", trailing: "")
                            emptyMomentsState
                        }

                        // ─── 02 OBIECTIV ACTIV (dacă există) ─────────────
                        // (rezervat pentru viitor — GoalsEngine integration)

                        // ─── 03 ISTORIC ─────────────────────────────────
                        if vm.recentMoments.count > 1 {
                            editorialSectionHeader(num: "02", label: "ISTORIC", trailing: "Toate")
                            historicRail
                        }

                        Spacer(minLength: SolSpacing.xxxl)
                    }
                    .padding(.top, SolSpacing.base)
                }
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
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell")
                                .font(.body)
                                .foregroundStyle(Color.solForeground)
                            if vm.hasUnreadAlert {
                                Circle()
                                    .fill(Color.solPrimary)
                                    .frame(width: 8, height: 8)
                                    .shadow(color: Color.solPrimary, radius: 4)
                                    .offset(x: 4, y: -4)
                            }
                        }
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

    // MARK: - Ambient background (mesh gradient v3)

    @ViewBuilder
    private var ambientBackground: some View {
        ZStack {
            Color.solCanvas
            // Teal top-left
            RadialGradient(
                colors: [Color.solPrimary.opacity(0.08), Color.clear],
                center: .init(x: 0.08, y: 0.06),
                startRadius: 0,
                endRadius: 260
            )
            // Blue bottom-right
            RadialGradient(
                colors: [Color.blue.opacity(0.05), Color.clear],
                center: .init(x: 0.92, y: 0.94),
                startRadius: 0,
                endRadius: 240
            )
        }
    }

    // MARK: - Greeting

    @ViewBuilder
    private var greetingRow: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(vm.greetingText)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.solMuted)
                .textCase(.uppercase)
                .tracking(1.5)
            if !vm.userName.isEmpty {
                Text(vm.userName)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.solForeground)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, SolSpacing.base)
    }

    // MARK: - Hero Card (v3 editorial glass)

    @ViewBuilder
    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Eyebrow row ──
            HStack(spacing: SolSpacing.xs) {
                // Live dot pulsate
                Circle()
                    .fill(Color.solPrimary)
                    .frame(width: 6, height: 6)
                    .shadow(color: Color.solPrimary, radius: 4)
                Text("SAFE TO SPEND")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.solPrimary)
                    .tracking(1.8)
                Spacer()
                // Status pill
                Text(vm.safeToSpendStatus)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(vm.isBudgetTight ? Color.solWarning : Color.solPrimary)
                    .tracking(1.0)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        (vm.isBudgetTight ? Color.solWarning : Color.solPrimary).opacity(0.10)
                    )
                    .overlay(
                        Capsule()
                            .stroke(
                                (vm.isBudgetTight ? Color.solWarning : Color.solPrimary).opacity(0.40),
                                lineWidth: 0.5
                            )
                    )
                    .clipShape(Capsule())
            }
            .padding(.bottom, SolSpacing.lg)

            // ── Hero number ──
            VStack(alignment: .leading, spacing: 4) {
                Text(vm.safeToSpendAmountFormatted)
                    .font(.solHeroBig)
                    .foregroundStyle(LinearGradient.solHero)
                    .monospacedDigit()
                    .contentTransition(.numericText())

                Text("RON · DISPONIBIL")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.solPrimary.opacity(0.85))
                    .tracking(1.4)
            }

            // ── Caption ──
            Text(heroCaption)
                .font(.system(size: 13))
                .foregroundStyle(Color.solMuted)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, SolSpacing.md)
                .padding(.bottom, SolSpacing.lg)

            // ── Meta grid ── (hairline separator top)
            Divider()
                .background(Color.white.opacity(0.08))

            HStack(spacing: 0) {
                heroMetaCell(key: "PER ZI",
                             value: "\(vm.perDayRON) RON",
                             isMint: true)
                Spacer()
                heroMetaCell(key: "CHELTUIT",
                             value: vm.formatRON(vm.spentThisMonthRON),
                             isMint: false)
                Spacer()
                heroMetaCell(key: "SALARIU",
                             value: vm.paydayDateFormatted,
                             isMint: false)
            }
            .padding(.top, SolSpacing.md)
        }
        .padding(SolSpacing.xl)
        .solGlassCard()
        .overlay(
            // Mint border hairline
            RoundedRectangle(cornerRadius: SolRadius.xxl, style: .continuous)
                .stroke(Color.solPrimary.opacity(0.25), lineWidth: 0.5)
        )
        .overlay(alignment: .topLeading) {
            // Corner highlight glow (top-left mint radial)
            RadialGradient(
                colors: [Color.solPrimary.opacity(0.35), Color.clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 140
            )
            .blur(radius: 20)
            .clipShape(RoundedRectangle(cornerRadius: SolRadius.xxl, style: .continuous))
            .allowsHitTesting(false)
        }
        .shadow(color: Color.black.opacity(0.35), radius: 16, x: 0, y: 8)
        .padding(.horizontal, SolSpacing.base)
    }

    @ViewBuilder
    private func heroMetaCell(key: String, value: String, isMint: Bool) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(key)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Color.solMuted.opacity(0.7))
                .tracking(1.4)
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(isMint ? Color.solPrimary : Color.solForeground)
                .monospacedDigit()
        }
    }

    private var heroCaption: String {
        if vm.daysUntilPayday > 0 {
            return "Solomon a calculat după ce a scăzut obligațiile rămase și o rezervă pentru cele \(vm.daysUntilPayday) zile până la salariul următor."
        } else {
            return "Solomon calculează pe baza obligațiilor rămase din luna curentă."
        }
    }

    // MARK: - Tight budget banner

    @ViewBuilder
    private var tightBudgetBanner: some View {
        HStack(spacing: SolSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.solWarning)
                .font(.subheadline)
            Text("Buget strâns — atenție la cheltuielile mici")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.solWarning)
            Spacer()
        }
        .padding(.horizontal, SolSpacing.base)
        .padding(.vertical, SolSpacing.md)
        .background(Color.solWarning.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: SolRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: SolRadius.lg, style: .continuous)
                .stroke(Color.solWarning.opacity(0.30), lineWidth: 1)
        )
        .padding(.horizontal, SolSpacing.base)
    }

    // MARK: - CTA (pill mint cu blade glow)

    @ViewBuilder
    private var canIAffordCTA: some View {
        Button {
            Haptics.medium()
            showCanIAfford = true
        } label: {
            HStack(spacing: SolSpacing.md) {
                // Icon bubble — glass inner
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.20))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Circle().stroke(Color.white.opacity(0.40), lineWidth: 0.5)
                        )
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.solCanvas)
                }

                Text("Pot să-mi permit?")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.solCanvas)

                Spacer()

                // Arrow circle
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.18))
                        .frame(width: 30, height: 30)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.solCanvas)
                }
            }
            .padding(.horizontal, SolSpacing.base)
            .frame(height: SolSpacing.hh)
            .background(LinearGradient.solPrimaryCTA)
            .clipShape(Capsule())
            .shadow(color: Color.solPrimary.opacity(0.40), radius: 20, x: 0, y: 8)
            .shadow(color: Color.solPrimary.opacity(0.20), radius: 40, x: 0, y: 0)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, SolSpacing.base)
    }

    // MARK: - Editorial section header (01 · LABEL · trailing)

    @ViewBuilder
    private func editorialSectionHeader(num: String, label: String, trailing: String) -> some View {
        HStack(alignment: .center, spacing: SolSpacing.sm) {
            // Numbered badge
            Text(num)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.solPrimary)
                .tracking(0.8)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color.solPrimary.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.solPrimary.opacity(0.22), lineWidth: 0.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 4))

            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.solForeground)
                .tracking(1.8)

            Spacer()

            if !trailing.isEmpty {
                Text(trailing)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.solMuted)
                    .tracking(0.4)
            }
        }
        .padding(.horizontal, SolSpacing.base)
        .padding(.top, SolSpacing.sm)
        .padding(.bottom, SolSpacing.xs)
    }

    // MARK: - Moment loading

    @ViewBuilder
    private var momentLoadingPlaceholder: some View {
        HStack(spacing: SolSpacing.sm) {
            ProgressView()
                .tint(Color.solPrimary)
            Text("Analizez datele tale…")
                .font(.subheadline)
                .foregroundStyle(Color.solMuted)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: SolRadius.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: SolRadius.xl, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
        )
        .padding(.horizontal, SolSpacing.base)
    }

    // MARK: - Empty moments state

    @ViewBuilder
    private var emptyMomentsState: some View {
        VStack(spacing: SolSpacing.md) {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundStyle(Color.solPrimary)
                .symbolRenderingMode(.hierarchical)

            Text("Solomon ascultă, dar are nevoie de date.")
                .font(.headline)
                .foregroundStyle(Color.solForeground)
                .multilineTextAlignment(.center)

            Text("Adaugă manual prima ta tranzacție sau configurează Shortcut-ul ca să primesc automat notificările bancare. După câteva intrări, încep să-ți spun observații utile.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                Haptics.light()
                showManualEntry = true
            } label: {
                Label("Adaugă tranzacție", systemImage: "plus.circle.fill")
                    .font(.footnote.weight(.semibold))
                    .padding(.horizontal, SolSpacing.base)
                    .padding(.vertical, SolSpacing.sm)
                    .foregroundStyle(Color.solPrimary)
                    .background(Color.solPrimary.opacity(0.12), in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, SolSpacing.xs)
        }
        .frame(maxWidth: .infinity)
        .padding(SolSpacing.xl)
        .solAIInsightCard()
        .padding(.horizontal, SolSpacing.base)
    }

    // MARK: - Historic rail (horizontal scroll)

    @ViewBuilder
    private var historicRail: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: SolSpacing.sm) {
                ForEach(vm.recentMoments.dropFirst()) { moment in
                    historicCard(moment: moment)
                }
            }
            .padding(.horizontal, SolSpacing.base)
            .padding(.vertical, SolSpacing.xs)
        }
    }

    @ViewBuilder
    private func historicCard(moment: DisplayMoment) -> some View {
        VStack(alignment: .leading, spacing: SolSpacing.sm) {
            // Head — icon + when
            HStack(spacing: SolSpacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(moment.accentColor.opacity(0.18))
                        .frame(width: 26, height: 26)
                        .overlay(
                            RoundedRectangle(cornerRadius: 7)
                                .stroke(moment.accentColor.opacity(0.30), lineWidth: 0.5)
                        )
                    Image(systemName: moment.systemIconName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(moment.accentColor)
                }
                Text(moment.timeAgoString)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.solMuted)
                    .tracking(1.2)
                    .textCase(.uppercase)
            }

            Text(moment.title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.solForeground)
                .lineLimit(1)

            Text(moment.llmResponse)
                .font(.system(size: 12))
                .foregroundStyle(Color.solMuted)
                .lineLimit(3)
                .lineSpacing(1.5)
        }
        .padding(SolSpacing.md)
        .frame(width: 220, height: 156, alignment: .topLeading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: SolRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: SolRadius.lg, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
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
