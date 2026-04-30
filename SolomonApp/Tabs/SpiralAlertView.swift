import SwiftUI
import SolomonCore
import SolomonStorage
import SolomonAnalytics
import SolomonMoments
import SolomonLLM

// MARK: - SpiralAlertView (Claude Design v3 — spiral.html 1:1)
//
// Redesign editorial premium 1:1 cu `spiral.html`:
//   - MeshBackground rose+amber pentru tema critică
//   - Hero rose cu spiral score (display "+X RON") + 7-day declin bars + CRITIC badge
//   - Insight rose cu pattern detectat + butoane Blochează / Văd, rezolv
//   - Listă tranzacții problematice (factori contributing)
//   - Insight mint cu plan recuperare 3 zile
//   - CSALB CTA când severity high+critical
//
// Business logic preservat: SpiralAlertContext + MomentEngine + CSALBDeeplink + decode.

struct SpiralAlertView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var moment: MomentOutput?
    @State private var spiralContext: SpiralAlertContext?
    @State private var isLoading = true

    private let engine = MomentEngine()

    var body: some View {
        ZStack {
            MeshBackground(
                topLeftAccent: .rose,
                midRightAccent: .amber,
                bottomLeftAccent: .rose
            )

            if isLoading {
                ProgressView()
                    .tint(Color.solRoseExact)
            } else if let ctx = spiralContext {
                contentScroll(ctx: ctx)
            } else {
                emptyState
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task { await load() }
    }

    // MARK: - Top bar (back + brand + page title)

    @ViewBuilder
    private var topBar: some View {
        HStack(alignment: .center, spacing: 12) {
            SolBackButton(action: { dismiss() })
            VStack(alignment: .center, spacing: 2) {
                Text("⚠ SOLOMON · ALERTĂ")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.solRoseExact)
                    .tracking(1.4)
                    .textCase(.uppercase)
                Text("Spirală detectată")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .tracking(-0.4)
            }
            .frame(maxWidth: .infinity)
            // Right spacer to balance back button
            Color.clear.frame(width: 38, height: 38)
        }
        .padding(.top, SolSpacing.sm)
        .padding(.bottom, SolSpacing.xl)
    }

    // MARK: - Scroll content

    @ViewBuilder
    private func contentScroll(ctx: SpiralAlertContext) -> some View {
        ScrollView {
            VStack(spacing: SolSpacing.base) {
                topBar

                heroCard(ctx: ctx)

                patternInsight(ctx: ctx)

                if !ctx.factorsDetected.isEmpty {
                    SolSectionHeaderRow(
                        "TRANZACȚIILE PROBLEMATICE",
                        meta: "\(ctx.factorsDetected.count) detectate"
                    )

                    factorsList(ctx: ctx)
                }

                recoveryInsight(plan: ctx.recoveryPlan)

                if ctx.csalbRelevant {
                    csalbCard
                }

                if let resp = moment?.llmResponse, !resp.isEmpty {
                    solomonNarrative(resp)
                }
            }
            .padding(.horizontal, SolSpacing.xl)
            .padding(.bottom, SolSpacing.hh)
        }
    }

    // MARK: - Hero (rose) cu spiral score + 7-day bars

    @ViewBuilder
    private func heroCard(ctx: SpiralAlertContext) -> some View {
        SolHeroCard(accent: .rose) {
            VStack(alignment: .leading, spacing: 0) {
                SolHeroLabel(heroLabel(for: ctx))
                    .padding(.bottom, 6)

                // Display amount (ex "+847 RON") — folosim spiralScore × 200 ca proxy când nu avem amount real,
                // dar dacă există factor.amount preferăm acel agregat.
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(spiralAmountDisplay(ctx: ctx))
                        .font(.system(size: 42, weight: .semibold))
                        .foregroundStyle(Color.solRoseExact)
                        .tracking(-1.5)
                        .monospacedDigit()
                        .shadow(color: Color.solRoseExact.opacity(0.25), radius: 30)

                    Text("RON")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.4))
                        .padding(.leading, 6)
                }
                .padding(.top, 0)

                // Sub-amount meta (rose tendință)
                HStack(spacing: 8) {
                    Text(spiralTrendText(ctx: ctx))
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(Color.solRoseExact)
                }
                .padding(.top, 6)
                .padding(.bottom, 18)

                // 7-day spiral bars
                spiralBars(score: ctx.spiralScore)

                // Bar labels (L M M J V S↑ D↑)
                HStack {
                    let labels = ["L", "M", "M", "J", "V", "S ↑", "D ↑"]
                    ForEach(labels.indices, id: \.self) { i in
                        Text(labels[i])
                            .font(.system(size: 10))
                            .foregroundStyle(Color.white.opacity(0.35))
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.top, 8)
            }
        } badge: {
            SolHeroBadge("CRITIC", accent: .rose)
        }
    }

    /// 7-day declin bars — calm pe primele zile, peak ultimele 2.
    @ViewBuilder
    private func spiralBars(score: Int) -> some View {
        // Heights and "calm/peak" mapping din spiral.html
        let bars: [(height: CGFloat, kind: BarKind)] = [
            (0.35, .calm),
            (0.42, .calm),
            (0.55, .normal),
            (0.68, .normal),
            (0.78, .normal),
            (0.92, .peak),
            (1.00, .peak)
        ]

        HStack(alignment: .bottom, spacing: 4) {
            ForEach(bars.indices, id: \.self) { i in
                let bar = bars[i]
                spiralBar(heightFraction: bar.height, kind: bar.kind)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 80)
    }

    private enum BarKind {
        case calm, normal, peak
    }

    @ViewBuilder
    private func spiralBar(heightFraction: CGFloat, kind: BarKind) -> some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(barFill(kind))
                    .overlay(
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .stroke(barStroke(kind), lineWidth: 1)
                    )
                    .frame(height: max(2, geo.size.height * heightFraction))
                    .shadow(color: kind == .peak ? Color.solRoseExact.opacity(0.5) : .clear, radius: 12)
            }
        }
    }

    private func barFill(_ kind: BarKind) -> LinearGradient {
        switch kind {
        case .calm:
            return LinearGradient(
                colors: [Color.white.opacity(0.06), Color.white.opacity(0.06)],
                startPoint: .top, endPoint: .bottom
            )
        case .normal:
            return LinearGradient(
                colors: [Color.solRoseExact.opacity(0.4), Color.solRoseExact.opacity(0.4)],
                startPoint: .top, endPoint: .bottom
            )
        case .peak:
            return LinearGradient(
                colors: [Color.solRoseExact, Color.solRoseExact.opacity(0.3)],
                startPoint: .top, endPoint: .bottom
            )
        }
    }

    private func barStroke(_ kind: BarKind) -> Color {
        switch kind {
        case .calm:   return Color.white.opacity(0.10)
        case .normal: return Color.solRoseExact.opacity(0.4)
        case .peak:   return Color.solRoseExact.opacity(0.6)
        }
    }

    // MARK: - Pattern detected insight (rose) — replaces "BLOCK 48h / Văd, rezolv"

    @ViewBuilder
    private func patternInsight(ctx: SpiralAlertContext) -> some View {
        SolInsightCard(
            icon: "sparkles",
            label: "PATTERN DETECTAT",
            timestamp: "acum 12 min",
            accent: .rose
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text(ctx.narrativeSummary)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.white.opacity(0.85))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    SolPrimaryButton("Blochează 48h", accent: .rose) {
                        // Behavior hook — în prezent un placeholder; payload e captat în SpiralAlertContext
                    }
                    SolSecondaryButton("Văd, rezolv") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Factors list (transactions / contributing factors)

    @ViewBuilder
    private func factorsList(ctx: SpiralAlertContext) -> some View {
        SolListCard {
            ForEach(Array(ctx.factorsDetected.enumerated()), id: \.offset) { idx, factor in
                if idx > 0 { SolHairlineDivider() }
                SolListRow(
                    title: factorName(factor.factor),
                    subtitle: factor.evidence
                ) {
                    factorIcon(factor.factor)
                } trailing: {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(factorTrailingValue(factor))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.solRoseExact)
                            .monospacedDigit()
                            .tracking(-0.3)
                        Text(factorTrailingUnit(factor))
                            .font(.system(size: 10))
                            .foregroundStyle(Color.white.opacity(0.35))
                    }
                }
            }
        }
    }

    // MARK: - Recovery plan insight (mint, no accent)

    @ViewBuilder
    private func recoveryInsight(plan: RecoveryPlan) -> some View {
        SolInsightCard(
            icon: "checkmark",
            label: "RECUPERARE · PLAN",
            timestamp: "3 zile",
            accent: .mint
        ) {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    recoveryStepLine(number: 1, step: plan.step1)
                    recoveryStepLine(number: 2, step: plan.step2)
                    recoveryStepLine(number: 3, step: plan.step3)
                }

                if let totalSaving = totalRecoverySaving(plan: plan) {
                    Text("Recuperezi ≈ \(totalSaving) RON până luni.")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.solMintExact)
                        .padding(.top, 2)
                }

                SolPrimaryButton("Activează modul recuperare", accent: .mint, fullWidth: true) {
                    // Recovery mode activation hook
                }
            }
        }
    }

    @ViewBuilder
    private func recoveryStepLine(number: Int, step: RecoveryStep) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(number).")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.solMintLight)
                .frame(width: 16, alignment: .leading)
                .monospacedDigit()
            VStack(alignment: .leading, spacing: 2) {
                Text(step.action)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 6) {
                    SolChip(complexityLabel(step.complexity), kind: complexityChipKind(step.complexity))
                    if let tool = step.tool {
                        SolChip(toolLabel(tool), kind: .blue)
                    }
                    if let saving = step.monthlySaving, !saving.isZero {
                        Text("≈ \(abs(saving.amount)) RON/lună")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.solMintExact)
                    }
                }
            }
        }
    }

    // MARK: - CSALB card

    @ViewBuilder
    private var csalbCard: some View {
        SolInsightCard(
            icon: "scalemass.fill",
            label: "CSALB POATE AJUTA",
            timestamp: nil,
            accent: .blue
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Centrul de Soluționare Alternativă a Litigiilor Bancare e o instituție gratuită care mediază dispute cu băncile și IFN-urile. Procesul durează 30–90 zile.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.white.opacity(0.85))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

                SolPrimaryButton("Începe procedura CSALB", accent: .blue, fullWidth: true) {
                    CSALBDeeplink.openStartProcedure()
                }
            }
        }
    }

    // MARK: - Optional Solomon narrative (LLM)

    @ViewBuilder
    private func solomonNarrative(_ text: String) -> some View {
        SolInsightCard(
            icon: "sparkles",
            label: "SOLOMON SPUNE",
            timestamp: nil,
            accent: .violet
        ) {
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(Color.white.opacity(0.85))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Empty state

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: SolSpacing.base) {
            Spacer(minLength: 0)
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Color.solMintExact)
                .shadow(color: Color.solMintExact.opacity(0.3), radius: 16)
            Text("Niciun semn de spirală")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color.white)
                .tracking(-0.4)
            Text("Solomon nu detectează presiune financiară pe baza datelor curente.")
                .font(.system(size: 14))
                .foregroundStyle(Color.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .padding(.horizontal, SolSpacing.lg)
            SolSecondaryButton("Închide", fullWidth: false) { dismiss() }
                .padding(.top, SolSpacing.sm)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, SolSpacing.xl)
    }

    // MARK: - Logic (preservat 1:1 din versiunea anterioară)

    private func load() async {
        let ctx = SolomonPersistenceController.shared.container.viewContext
        let txRepo = CoreDataTransactionRepository(context: ctx)
        let oblRepo = CoreDataObligationRepository(context: ctx)
        let subRepo = CoreDataSubscriptionRepository(context: ctx)
        let goalRepo = CoreDataGoalRepository(context: ctx)
        let userRepo = CoreDataUserProfileRepository(context: ctx)

        let snapshot = MomentEngine.Snapshot(
            userProfile: try? userRepo.fetchProfile(),
            transactions: (try? txRepo.fetchAll()) ?? [],
            obligations: (try? oblRepo.fetchAll()) ?? [],
            subscriptions: (try? subRepo.fetchAll()) ?? [],
            goals: (try? goalRepo.fetchAll()) ?? []
        )

        do {
            if let output = try await engine.generateSpiralAlert(snapshot: snapshot) {
                moment = output
                if let data = output.contextJSON.data(using: .utf8) {
                    spiralContext = try? SolomonContextCoder.decoder().decode(SpiralAlertContext.self, from: data)
                }
            }
        } catch {
            // Silent fail — show empty state
        }
        isLoading = false
    }

    // MARK: - Display helpers

    private func heroLabel(for ctx: SpiralAlertContext) -> String {
        switch ctx.severity {
        case .none, .low:
            return "PRESIUNE FINANCIARĂ · 7 ZILE"
        case .medium:
            return "PRESIUNE CRESCUTĂ · 7 ZILE"
        case .high, .critical:
            return "PESTE BUGET · 7 ZILE CONSECUTIVE"
        }
    }

    /// Sumă afișată în hero. Preferăm `monthlyGap` dacă există; altfel agregăm `factor.amount`;
    /// fallback la spiralScore × 200.
    private func spiralAmountDisplay(ctx: SpiralAlertContext) -> String {
        if let gap = ctx.factorsDetected.compactMap({ $0.monthlyGap?.amount }).first,
           gap != 0 {
            return "+\(abs(gap))"
        }
        let agg = ctx.factorsDetected.compactMap { $0.amount?.amount }.reduce(0, +)
        if agg != 0 {
            return "+\(abs(agg))"
        }
        return "+\(ctx.spiralScore * 200)"
    }

    private func spiralTrendText(ctx: SpiralAlertContext) -> String {
        if let monthlyGap = ctx.factorsDetected.compactMap({ $0.monthlyGap?.amount }).first {
            let perDay = max(1, abs(monthlyGap) / 7)
            return "↑ +\(perDay) RON/zi peste limită"
        }
        return "↑ Tendință crescătoare detectată"
    }

    @ViewBuilder
    private func factorIcon(_ f: SpiralFactorKind) -> some View {
        // Brand-stil icon container 36×36 cu gradient
        let (system, gradientColors): (String, [Color]) = {
            switch f {
            case .balanceDeclining:
                return ("arrow.down.right", [Color(red: 0xFF/255, green: 0xC2/255, blue: 0x44/255), Color(red: 0xFF/255, green: 0xA2/255, blue: 0x00/255)])
            case .cardCreditIncreasing:
                return ("creditcard.fill", [Color(red: 0x3B/255, green: 0x82/255, blue: 0xF6/255), Color(red: 0x25/255, green: 0x63/255, blue: 0xEB/255)])
            case .ifnActive:
                return ("exclamationmark.octagon.fill", [Color.solRoseExact, Color.solRoseDeep])
            case .obligationsExceedIncome:
                return ("scalemass.fill", [Color.solAmberExact, Color.solAmberDeep])
            case .bnplStacking:
                return ("rectangle.stack.fill", [Color.solVioletExact, Color.solVioletDeep])
            case .overdraftFrequent:
                return ("minus.circle.fill", [Color.solRoseExact, Color.solRoseDeep])
            }
        }()

        ZStack {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
            Image(systemName: system)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.white)
        }
        .frame(width: 36, height: 36)
        .shadow(color: Color.black.opacity(0.4), radius: 4, x: 0, y: 2)
    }

    private func factorName(_ f: SpiralFactorKind) -> String {
        switch f {
        case .balanceDeclining:        return "Sold în scădere"
        case .cardCreditIncreasing:    return "Card credit în creștere"
        case .ifnActive:               return "IFN activ"
        case .obligationsExceedIncome: return "Obligații peste venit"
        case .bnplStacking:            return "BNPL stack"
        case .overdraftFrequent:       return "Descoperit frecvent"
        }
    }

    private func factorTrailingValue(_ f: SpiralFactor) -> String {
        if let amt = f.amount?.amount, amt != 0 {
            return "−\(abs(amt))"
        }
        if let gap = f.monthlyGap?.amount, gap != 0 {
            return "−\(abs(gap))"
        }
        if let avg = f.monthlyIncreaseAvg?.amount, avg != 0 {
            return "+\(abs(avg))"
        }
        return "—"
    }

    private func factorTrailingUnit(_ f: SpiralFactor) -> String {
        if f.monthlyGap != nil || f.monthlyIncreaseAvg != nil {
            return "RON/lună"
        }
        return "RON"
    }

    private func complexityLabel(_ c: RecoveryComplexity) -> String {
        switch c {
        case .easy:        return "ușor"
        case .medium:      return "mediu"
        case .hard:        return "dificil"
        case .behavioral:  return "comportament"
        }
    }

    private func complexityChipKind(_ c: RecoveryComplexity) -> SolChip.Kind {
        switch c {
        case .easy:        return .mint
        case .medium:      return .warn
        case .hard:        return .rose
        case .behavioral:  return .violet
        }
    }

    private func toolLabel(_ tool: RecoveryTool) -> String {
        switch tool {
        case .csalb:         return "CSALB"
        case .anpc:          return "ANPC"
        case .bankNegotiate: return "negociere"
        case .selfService:   return "self-service"
        }
    }

    private func totalRecoverySaving(plan: RecoveryPlan) -> Int? {
        let total = [plan.step1, plan.step2, plan.step3]
            .compactMap { $0.monthlySaving?.amount }
            .map { abs($0) }
            .reduce(0, +)
        return total > 0 ? total : nil
    }
}

