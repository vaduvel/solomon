import SwiftUI
import SolomonCore
import SolomonStorage

// MARK: - TodayView (Tab 1 — Editorial Premium v3)
//
// Transpunere 1:1 din Solomon DS / TodayView.v3.html (Claude Design)
// Layout editorial:
//   - NavRow (greeting + + / bell circular glass)
//   - Hero glass cu eyebrow + status pill + big number + caption + meta grid
//   - CTA pill mint mare cu icon bubble + arrow
//   - Section "01 SOLOMON SPUNE" + timestamp
//   - Moment card RICH (subscription audit cu sub-rows + RECUPEREZI + actions)
//   - Section "02 OBIECTIV ACTIV"
//   - Goal card cu progress + concluzie
//   - Footer math dashed
//   - Section "03 ISTORIC" + history rail

struct TodayView: View {

    @State private var vm = TodayViewModel()
    @State private var ingestion = NotificationIngestionService.shared
    @State private var showManualEntry = false
    @State private var showCanIAfford = false
    @State private var showAlerts = false
    @State private var showGoals = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                ambientBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: SolSpacing.base) {
                        navRow
                            .padding(.top, SolSpacing.sm)

                        heroCard

                        ctaPill

                        // ─── 01 SOLOMON SPUNE ─────────────────────────
                        section01Header

                        if vm.isLoadingMoment {
                            momentLoadingPlaceholder
                        } else if let moment = vm.currentMoment {
                            momentCard(moment: moment)
                        } else {
                            emptyMomentCard
                        }

                        // ─── 02 OBIECTIV ACTIV (dacă există) ──────────
                        if let goal = vm.activeGoal {
                            section02Header
                            goalCard(goal: goal)
                        }

                        // ─── Footer math ──────────────────────────────
                        footerMath

                        // ─── 03 ISTORIC ───────────────────────────────
                        if vm.recentMoments.count > 1 {
                            section03Header
                            historyRail
                        }

                        Spacer(minLength: SolSpacing.xxxl)
                    }
                    .padding(.horizontal, SolSpacing.base)
                    .padding(.bottom, SolSpacing.hh)
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
            .sheet(isPresented: $showGoals) {
                GoalsListView().solStandardSheet()
            }
        }
        .task {
            vm.configure(persistence: SolomonPersistenceController.shared)
            await vm.load()
        }
    }

    // MARK: - Ambient background (mesh teal+blue v3)

    @ViewBuilder
    private var ambientBackground: some View {
        ZStack {
            Color.solCanvasDark

            GeometryReader { geo in
                ZStack {
                    // Teal top-left mesh
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.solMintExact.opacity(0.08), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 220
                            )
                        )
                        .frame(width: 460, height: 460)
                        .blur(radius: 70)
                        .offset(x: -180, y: -180)

                    // Blue bottom-right mesh
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.solBlueExact.opacity(0.05), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 200
                            )
                        )
                        .frame(width: 420, height: 420)
                        .blur(radius: 60)
                        .offset(x: geo.size.width - 240, y: geo.size.height - 280)
                }
            }
            .allowsHitTesting(false)
        }
    }

    // MARK: - Nav row (greeting + actions)

    @ViewBuilder
    private var navRow: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(vm.greetingText.uppercased())
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .tracking(0.04 * 12)
                Text(vm.userName.isEmpty ? "Solomon" : vm.userName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.white)
                    .tracking(-0.01 * 22)
            }
            .padding(.leading, SolSpacing.xs)

            Spacer()

            HStack(spacing: SolSpacing.sm) {
                navCircleButton(systemName: "plus") {
                    showManualEntry = true
                }
                navCircleButton(systemName: "bell.fill", isAlert: true, hasDot: vm.hasUnreadAlert) {
                    showAlerts = true
                    vm.hasUnreadAlert = false
                }
            }
        }
        .padding(.horizontal, SolSpacing.xs)
    }

    @ViewBuilder
    private func navCircleButton(systemName: String, isAlert: Bool = false, hasDot: Bool = false, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.light()
            action()
        } label: {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Circle().stroke(
                            isAlert ? Color.solMintExact.opacity(0.45) : Color.white.opacity(0.12),
                            lineWidth: 0.5
                        )
                    )
                    .shadow(
                        color: isAlert ? Color.solMintExact.opacity(0.20) : .clear,
                        radius: 8
                    )

                Image(systemName: systemName)
                    .font(.system(size: 16, weight: isAlert ? .semibold : .medium))
                    .foregroundStyle(isAlert ? Color.solMintExact : Color.white)

                if hasDot {
                    Circle()
                        .fill(Color.solMintExact)
                        .frame(width: 8, height: 8)
                        .shadow(color: Color.solMintExact, radius: 4)
                        .offset(x: 12, y: -12)
                }
            }
            .frame(width: 40, height: 40)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Hero card (editorial v3)

    @ViewBuilder
    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Eyebrow row: ● SAFE TO SPEND (left) + status pill (right)
            HStack(alignment: .center) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.solMintExact)
                        .frame(width: 6, height: 6)
                        .shadow(color: Color.solMintExact, radius: 4)
                    Text("SAFE TO SPEND")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.solMintExact)
                        .tracking(0.18 * 10)
                }

                Spacer()

                Text(vm.safeToSpendStatus)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(vm.isBudgetTight ? Color.solAmberExact : Color.solMintExact)
                    .tracking(0.10 * 10)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        (vm.isBudgetTight ? Color.solAmberExact : Color.solMintExact).opacity(0.10)
                    )
                    .overlay(
                        Capsule().stroke(
                            (vm.isBudgetTight ? Color.solAmberExact : Color.solMintExact).opacity(0.40),
                            lineWidth: 0.5
                        )
                    )
                    .clipShape(Capsule())
            }
            .padding(.bottom, SolSpacing.lg)

            // Number stack: big + unit
            VStack(alignment: .leading, spacing: 4) {
                Text(vm.safeToSpendAmountFormatted)
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color.solMintLight, Color.solMintExact],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .monospacedDigit()
                    .tracking(-0.035 * 56)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Text("RON · DISPONIBIL")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.solMintExact.opacity(0.85))
                    .tracking(0.14 * 12)
            }

            // Caption with bold spans
            captionView
                .padding(.top, SolSpacing.md)
                .padding(.bottom, SolSpacing.lg)

            // Hairline + Meta grid
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 0.5)

            HStack(spacing: 0) {
                heroMetaCell(key: "PER ZI", value: "\(vm.perDayRON) RON", isMint: true)
                Spacer()
                heroMetaCell(key: "CHELTUIT", value: vm.formatRON(vm.spentThisMonthRON), isMint: false)
                Spacer()
                heroMetaCell(key: "SALARIU", value: vm.paydayDateFormatted, isMint: false)
            }
            .padding(.top, SolSpacing.md)
        }
        .padding(SolSpacing.lg)
        .background {
            ZStack {
                // Glass background
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)

                // Mint corner highlight (top-left)
                RadialGradient(
                    colors: [Color.solMintExact.opacity(0.45), .clear],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 180
                )
                .blur(radius: 30)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .allowsHitTesting(false)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.solMintExact.opacity(0.25), lineWidth: 0.5)
        )
        .overlay(alignment: .bottom) {
            // Bottom hairline mint glow
            LinearGradient(
                colors: [.clear, Color.solMintExact.opacity(0.6), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Color.black.opacity(0.55), radius: 25, x: 0, y: 16)
    }

    private var captionView: some View {
        let days = vm.daysUntilPayday
        var attr = AttributedString("Solomon a calculat după ce a scăzut ")
        var bold1 = AttributedString("obligațiile rămase")
        bold1.foregroundColor = .white
        bold1.font = .system(size: 13, weight: .semibold)
        attr += bold1
        attr += AttributedString(" și o rezervă pentru cele ")
        var bold2 = AttributedString("\(days) zile")
        bold2.foregroundColor = .white
        bold2.font = .system(size: 13, weight: .semibold)
        attr += bold2
        attr += AttributedString(" până la salariul următor.")
        return Text(attr)
            .font(.system(size: 13))
            .foregroundStyle(Color.white.opacity(0.55))
            .lineSpacing(3.5)
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private func heroMetaCell(key: String, value: String, isMint: Bool) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(key)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.32))
                .tracking(0.14 * 9)
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(isMint ? Color.solMintExact : Color.white)
                .monospacedDigit()
                .tracking(-0.01 * 14)
        }
    }

    // MARK: - CTA pill (mint big + side glow blade)

    @ViewBuilder
    private var ctaPill: some View {
        Button {
            Haptics.medium()
            showCanIAfford = true
        } label: {
            HStack(spacing: SolSpacing.md) {
                // Icon bubble (dark inner)
                ZStack {
                    Circle()
                        .fill(Color(red: 0x04/255, green: 0x14/255, blue: 0x0E/255).opacity(0.30))
                        .overlay(
                            Circle().stroke(Color.white.opacity(0.40), lineWidth: 0.5)
                        )
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(red: 0x04/255, green: 0x14/255, blue: 0x0E/255))
                }
                .frame(width: 36, height: 36)

                Text("Pot să-mi permit?")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(red: 0x04/255, green: 0x14/255, blue: 0x0E/255))
                    .tracking(-0.005 * 16)

                Spacer()

                // Arrow bubble (smaller, dark inner)
                ZStack {
                    Circle()
                        .fill(Color(red: 0x04/255, green: 0x14/255, blue: 0x0E/255).opacity(0.20))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color(red: 0x04/255, green: 0x14/255, blue: 0x0E/255))
                }
                .frame(width: 32, height: 32)
            }
            .padding(SolSpacing.base)
            .frame(minHeight: 60)
            .background(
                LinearGradient(
                    colors: [Color.solMintLight, Color.solMintExact, Color.solMintDeep],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                Capsule().stroke(Color.white.opacity(0.40), lineWidth: 0.5)
            )
            .clipShape(Capsule())
            .shadow(color: Color.solMintExact.opacity(0.4), radius: 24, x: 0, y: 12)
            .shadow(color: Color.solMintExact.opacity(0.2), radius: 50, x: 0, y: 0)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Editorial section headers (01 / 02 / 03)

    @ViewBuilder
    private func editorialHeader(num: String, label: String, trailing: String?) -> some View {
        HStack(alignment: .center, spacing: SolSpacing.sm) {
            Text(num)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.solMintExact)
                .tracking(0.08 * 10)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(Color.solMintExact.opacity(0.22), lineWidth: 0.5)
                )

            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.white)
                .tracking(0.18 * 11)

            Spacer()

            if let trailing {
                Text(trailing)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .tracking(0.04 * 11)
            }
        }
        .padding(.top, SolSpacing.base)
        .padding(.bottom, SolSpacing.xs)
    }

    private var section01Header: some View {
        editorialHeader(
            num: "01",
            label: "SOLOMON SPUNE",
            trailing: vm.currentMoment?.timeAgoString
        )
    }

    private var section02Header: some View {
        editorialHeader(
            num: "02",
            label: "OBIECTIV ACTIV",
            trailing: "Vezi toate →"
        )
    }

    private var section03Header: some View {
        editorialHeader(num: "03", label: "ISTORIC", trailing: "Toate")
    }

    // MARK: - Moment card (RICH — subscription audit + fallback)

    @ViewBuilder
    private func momentCard(moment: DisplayMoment) -> some View {
        if moment.momentTypeRaw == "subscription_audit" && !vm.subscriptions.isEmpty {
            subscriptionAuditCard(moment: moment, subs: vm.subscriptions)
        } else {
            simpleMomentCard(moment: moment)
        }
    }

    /// RICH subscription audit card cu sub-rows + RECUPEREZI footer + actions
    @ViewBuilder
    private func subscriptionAuditCard(moment: DisplayMoment, subs: [Subscription]) -> some View {
        let displayed = Array(subs.prefix(3))
        let monthlyTotal = displayed.reduce(0) { $0 + $1.amountMonthly.amount }
        let annualTotal = monthlyTotal * 12

        VStack(spacing: 0) {
            // Head
            HStack(alignment: .center, spacing: SolSpacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(SolAccent.mint.iconGradient)
                        .overlay(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .stroke(Color.solMintExact.opacity(0.40), lineWidth: 0.5)
                        )
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.solMintExact)
                }
                .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Audit abonamente")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color.white)
                        .tracking(-0.01 * 17)
                    Text("\(displayed.count) inactive · neutilizate luna asta")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.55))
                }

                Spacer()

                Text("−\(monthlyTotal) RON")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.solMintExact)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.solMintExact.opacity(0.14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6).stroke(Color.solMintExact.opacity(0.40), lineWidth: 0.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .padding(.horizontal, SolSpacing.lg)
            .padding(.top, SolSpacing.lg)
            .padding(.bottom, SolSpacing.md)

            // Sub-rows
            VStack(spacing: 0) {
                ForEach(Array(displayed.enumerated()), id: \.offset) { idx, sub in
                    Rectangle().fill(Color.white.opacity(0.08)).frame(height: 0.5)
                    subscriptionRow(sub: sub, animDelay: Double(idx) * 0.3)
                }
            }

            // Summary footer (mint dashed top + bg)
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.solMintExact.opacity(0.22))
                    .frame(height: 0.5)
                HStack {
                    Text("RECUPEREZI")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.55))
                        .tracking(0.14 * 10)
                    Spacer()
                    HStack(spacing: 6) {
                        Text("\(monthlyTotal) RON/lună")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.solMintExact)
                        Text("·")
                            .foregroundStyle(Color.white.opacity(0.32))
                        Text("\(annualTotal) RON/an")
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.55))
                    }
                }
                .padding(.horizontal, SolSpacing.lg)
                .padding(.vertical, SolSpacing.md)
                .background(Color.solMintExact.opacity(0.04))
            }

            // Action buttons
            HStack(spacing: SolSpacing.sm) {
                Button {
                    Haptics.success()
                } label: {
                    Text("Anulează tot")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color(red: 0x04/255, green: 0x14/255, blue: 0x0E/255))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color.solMintLight, Color.solMintExact],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: Color.solMintExact.opacity(0.35), radius: 16, x: 0, y: 6)
                }
                .buttonStyle(.plain)

                Button {
                    Haptics.light()
                } label: {
                    Text("Decid eu")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, SolSpacing.lg)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.04))
                        .overlay(
                            Capsule().stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, SolSpacing.lg)
            .padding(.top, SolSpacing.md)
            .padding(.bottom, SolSpacing.lg)
        }
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.04), Color.black.opacity(0.30)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .background(.ultraThinMaterial.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
        )
    }

    @ViewBuilder
    private func subscriptionRow(sub: Subscription, animDelay: Double) -> some View {
        HStack(alignment: .center, spacing: SolSpacing.sm) {
            // Icon mini (28×28 dark cu literă colorată + pulse dot)
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                    )

                Text(String(sub.name.prefix(1)).uppercased())
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(letterColor(for: sub.name))

                // Pulse dot top-right
                Circle()
                    .fill(Color.solMintExact)
                    .frame(width: 8, height: 8)
                    .shadow(color: Color.solMintExact, radius: 4)
                    .overlay(
                        Circle().stroke(Color.solCanvasDark, lineWidth: 1.5)
                    )
                    .offset(x: 11, y: -11)
            }
            .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 1) {
                Text(sub.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.white)
                HStack(spacing: 3) {
                    Text("De ce?")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.solMintExact)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(Color.solMintExact)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                Text("\(sub.amountMonthly.amount) RON")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.32))
                    .strikethrough(true, color: Color.white.opacity(0.32))
                Text("−\(sub.amountMonthly.amount) RON")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.solMintExact)
            }
        }
        .padding(.horizontal, SolSpacing.lg)
        .padding(.vertical, SolSpacing.md)
    }

    private func letterColor(for name: String) -> Color {
        let lowered = name.lowercased()
        if lowered.contains("netflix")  { return Color(red: 0xE5/255, green: 0x09/255, blue: 0x14/255) }
        if lowered.contains("hbo")      { return Color(red: 0x9B/255, green: 0x5C/255, blue: 0xF6/255) }
        if lowered.contains("spotify")  { return Color(red: 0x1E/255, green: 0xD7/255, blue: 0x60/255) }
        if lowered.contains("apple")    { return .white }
        if lowered.contains("youtube")  { return Color(red: 0xFF/255, green: 0x00/255, blue: 0x00/255) }
        if lowered.contains("disney")   { return Color(red: 0x11/255, green: 0x3C/255, blue: 0xCF/255) }
        return .solMintExact
    }

    // MARK: - Simple moment card (fallback for non-audit moments)

    @ViewBuilder
    private func simpleMomentCard(moment: DisplayMoment) -> some View {
        let accent = accentFor(moment: moment)
        VStack(alignment: .leading, spacing: SolSpacing.md) {
            HStack(spacing: SolSpacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(accent.iconGradient)
                        .overlay(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .stroke(accent.color.opacity(0.40), lineWidth: 0.5)
                        )
                    Image(systemName: moment.systemIconName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(accent.color)
                }
                .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 1) {
                    Text(moment.title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color.white)
                    Text(moment.subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.55))
                }

                Spacer()

                if let badge = moment.badge {
                    Text(badge)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(accent.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(accent.color.opacity(0.14))
                        .overlay(
                            Capsule().stroke(accent.color.opacity(0.40), lineWidth: 0.5)
                        )
                        .clipShape(Capsule())
                }
            }

            Text(moment.llmResponse)
                .font(.system(size: 14))
                .foregroundStyle(Color.white.opacity(0.85))
                .lineSpacing(2)
        }
        .padding(SolSpacing.lg)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.04), Color.black.opacity(0.30)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .background(.ultraThinMaterial.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
        )
    }

    private func accentFor(moment: DisplayMoment) -> SolAccent {
        switch moment.momentTypeRaw {
        case "spiral_alert":         return .rose
        case "upcoming_obligation":  return .amber
        case "can_i_afford":         return .blue
        default:                     return .mint
        }
    }

    // MARK: - Loading / empty states

    @ViewBuilder
    private var momentLoadingPlaceholder: some View {
        HStack(spacing: SolSpacing.sm) {
            ProgressView().tint(Color.solMintExact)
            Text("Analizez datele tale…")
                .font(.system(size: 14))
                .foregroundStyle(Color.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .background(.ultraThinMaterial.opacity(0.55))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder
    private var emptyMomentCard: some View {
        VStack(spacing: SolSpacing.md) {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundStyle(Color.solMintExact)

            Text("Solomon ascultă, dar are nevoie de date.")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.white)
                .multilineTextAlignment(.center)

            Text("Adaugă manual prima ta tranzacție sau configurează Shortcut-ul ca să primesc automat notificările bancare.")
                .font(.system(size: 13))
                .foregroundStyle(Color.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .lineSpacing(2)

            Button {
                Haptics.light()
                showManualEntry = true
            } label: {
                Label("Adaugă tranzacție", systemImage: "plus.circle.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.horizontal, SolSpacing.base)
                    .padding(.vertical, SolSpacing.sm)
                    .foregroundStyle(Color.solMintExact)
                    .background(Color.solMintExact.opacity(0.12), in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, SolSpacing.xs)
        }
        .padding(SolSpacing.xl)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial.opacity(0.55))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Goal card (section 02)

    @ViewBuilder
    private func goalCard(goal: Goal) -> some View {
        let progress = goal.amountTarget.amount > 0
            ? min(1.0, Double(goal.amountSaved.amount) / Double(goal.amountTarget.amount))
            : 0

        VStack(alignment: .leading, spacing: SolSpacing.md) {
            // Head: left (eyebrow + name + sub) | right (% + of)
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.kind.displayNameRO.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.32))
                        .tracking(0.14 * 10)
                    Text(goal.destination ?? goal.kind.displayNameRO)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color.white)
                        .tracking(-0.01 * 17)
                    Text("Țintă \(formatRON(goal.amountTarget.amount))")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.55))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(colors: [.white, Color.solMintExact], startPoint: .top, endPoint: .bottom)
                        )
                        .monospacedDigit()
                        .tracking(-0.025 * 32)
                    Text("\(formatNum(goal.amountSaved.amount)) / \(formatNum(goal.amountTarget.amount)) RON")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.32))
                        .tracking(0.04 * 10)
                }
            }

            // Progress bar with bright cap
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            Capsule().stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                        )

                    if progress > 0 {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.solMintDeep, Color.solMintExact, Color.solMintLight],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(0, geo.size.width * CGFloat(progress)))
                            .shadow(color: Color.solMintExact.opacity(0.55), radius: 7)
                            .overlay(alignment: .trailing) {
                                Circle()
                                    .fill(Color.solMintLight)
                                    .frame(width: 12, height: 12)
                                    .shadow(color: Color.solMintLight, radius: 8)
                                    .offset(x: 4)
                            }
                    }
                }
            }
            .frame(height: 6)

            HStack {
                Text("Continuă ritmul")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.solMintExact)
                Spacer()
                Text("Termin \(formatDeadline(goal.deadline))")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .monospacedDigit()
            }

            // Conclusion footer (dashed top)
            VStack(alignment: .leading, spacing: 6) {
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 0.5)
                    .padding(.top, SolSpacing.xs)

                Text("CONCLUZIE")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.solMintExact)
                    .tracking(0.14 * 10)
                Text(conclusionFor(goal: goal, progress: progress))
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(SolSpacing.lg)
        .background(.ultraThinMaterial.opacity(0.55))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func conclusionFor(goal: Goal, progress: Double) -> String {
        if progress >= 1 {
            return "Ai atins ținta. Bravo!"
        }
        let remaining = max(0, goal.amountTarget.amount - goal.amountSaved.amount)
        let months = Calendar.current.dateComponents([.month], from: Date(), to: goal.deadline).month ?? 0
        if months > 0 {
            let perMonth = remaining / max(1, months)
            return "Mai ai \(formatRON(remaining)) până la țintă. Cu ~\(formatRON(perMonth))/lună ajungi la timp."
        }
        return "Mai ai \(formatRON(remaining)) până la țintă."
    }

    // MARK: - Footer math (dashed mint)

    @ViewBuilder
    private var footerMath: some View {
        HStack {
            Text("CAP LUNA ASTA")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.solMintExact)
                .tracking(0.18 * 10)
            Spacer()
            HStack(spacing: 6) {
                Text("\(vm.safeToSpendAmountFormatted) RON")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.solMintExact)
                Text("·")
                    .foregroundStyle(Color.white.opacity(0.32))
                Text("~\(formatNum(vm.safeToSpendRON * 12)) RON/an")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.55))
            }
        }
        .padding(.horizontal, SolSpacing.lg)
        .padding(.vertical, SolSpacing.base)
        .background(Color.solMintExact.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    style: StrokeStyle(lineWidth: 0.5, dash: [3, 2])
                )
                .foregroundStyle(Color.solMintExact.opacity(0.22))
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.top, SolSpacing.xs)
    }

    // MARK: - History rail

    @ViewBuilder
    private var historyRail: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: SolSpacing.sm) {
                ForEach(vm.recentMoments.dropFirst()) { moment in
                    historyCard(moment: moment)
                }
            }
            .padding(.vertical, SolSpacing.xs)
        }
    }

    @ViewBuilder
    private func historyCard(moment: DisplayMoment) -> some View {
        let accent = accentFor(moment: moment)
        VStack(alignment: .leading, spacing: SolSpacing.sm) {
            HStack(spacing: SolSpacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(accent.color.opacity(0.18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .stroke(accent.color.opacity(0.30), lineWidth: 0.5)
                        )
                    Image(systemName: moment.systemIconName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(accent.color)
                }
                .frame(width: 26, height: 26)
                Text(moment.timeAgoString.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .tracking(0.12 * 9)
                Spacer()
            }
            Text(moment.title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.white)
                .lineLimit(1)
            Text(moment.llmResponse)
                .font(.system(size: 12))
                .foregroundStyle(Color.white.opacity(0.55))
                .lineLimit(3)
                .lineSpacing(1.5)
        }
        .padding(SolSpacing.md)
        .frame(width: 220, height: 156, alignment: .topLeading)
        .background(.ultraThinMaterial.opacity(0.55))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Format helpers

    private func formatNum(_ amount: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = "."
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }

    private func formatRON(_ amount: Int) -> String {
        formatNum(amount) + " RON"
    }

    private func formatDeadline(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ro_RO")
        f.dateFormat = "d MMM"
        return f.string(from: date)
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
