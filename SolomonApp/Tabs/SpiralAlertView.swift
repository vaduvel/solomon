import SwiftUI
import SolomonCore
import SolomonStorage
import SolomonAnalytics
import SolomonMoments
import SolomonLLM

// MARK: - SpiralAlertView
//
// Vizualizează un Spiral Alert: scor + factori detectați + plan recuperare 3 pași.
// CSALB CTA când severitatea e high+critical și sunt IFN/BNPL active.

struct SpiralAlertView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var moment: MomentOutput?
    @State private var spiralContext: SpiralAlertContext?
    @State private var isLoading = true

    private let engine = MomentEngine()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.solCanvas.ignoresSafeArea()

                if isLoading {
                    ProgressView()
                        .tint(Color.solPrimary)
                } else if let ctx = spiralContext {
                    ScrollView {
                        VStack(spacing: SolSpacing.lg) {
                            heroCard(ctx: ctx)
                            factorsSection(ctx: ctx)
                            recoveryPlanSection(plan: ctx.recoveryPlan)
                            if ctx.csalbRelevant {
                                csalbCard
                            }
                            if let resp = moment?.llmResponse {
                                solomonNarrative(resp)
                            }
                        }
                        .padding(.horizontal, SolSpacing.screenHorizontal)
                        .padding(.top, SolSpacing.lg)
                        .padding(.bottom, SolSpacing.hh)
                    }
                } else {
                    emptyState
                }
            }
            .navigationTitle("Verificare spirală")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Închide") { dismiss() }
                        .foregroundStyle(Color.solMuted)
                }
            }
            .task { await load() }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private func heroCard(ctx: SpiralAlertContext) -> some View {
        VStack(spacing: SolSpacing.sm) {
            IconContainer(
                systemName: severityIcon(ctx.severity),
                variant: severityVariant(ctx.severity),
                size: 64,
                iconSize: 28
            )

            Text(severityTitle(ctx.severity))
                .font(.solH1)
                .foregroundStyle(severityColor(ctx.severity))

            Text("Scor spirală: \(ctx.spiralScore) / 4")
                .font(.solBodyBold)
                .foregroundStyle(Color.solForeground)

            Text(ctx.narrativeSummary)
                .font(.solBody)
                .foregroundStyle(Color.solMuted)
                .multilineTextAlignment(.center)
                .padding(.top, SolSpacing.sm)
        }
        .padding(SolSpacing.cardHero)
        .frame(maxWidth: .infinity)
        .solGlassCard()
    }

    @ViewBuilder
    private func factorsSection(ctx: SpiralAlertContext) -> some View {
        VStack(alignment: .leading, spacing: SolSpacing.sm) {
            Text("FACTORI DETECTAȚI")
                .font(.solMicro)
                .foregroundStyle(Color.solMuted)
                .tracking(1.2)

            ForEach(Array(ctx.factorsDetected.enumerated()), id: \.offset) { _, factor in
                HStack(alignment: .top, spacing: SolSpacing.md) {
                    IconContainer(
                        systemName: factorIcon(factor.factor),
                        variant: .danger,
                        size: 32,
                        iconSize: 12
                    )
                    VStack(alignment: .leading, spacing: 2) {
                        Text(factorName(factor.factor))
                            .font(.solBodyBold)
                            .foregroundStyle(Color.solForeground)
                        Text(factor.evidence)
                            .font(.solCaption)
                            .foregroundStyle(Color.solMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                }
                .padding(SolSpacing.base)
                .solCard()
            }
        }
    }

    @ViewBuilder
    private func recoveryPlanSection(plan: RecoveryPlan) -> some View {
        VStack(alignment: .leading, spacing: SolSpacing.sm) {
            Text("PLAN DE RECUPERARE")
                .font(.solMicro)
                .foregroundStyle(Color.solMuted)
                .tracking(1.2)

            stepCard(number: 1, step: plan.step1)
            stepCard(number: 2, step: plan.step2)
            stepCard(number: 3, step: plan.step3)
        }
    }

    @ViewBuilder
    private func stepCard(number: Int, step: RecoveryStep) -> some View {
        HStack(alignment: .top, spacing: SolSpacing.md) {
            ZStack {
                Circle()
                    .fill(Color.solPrimary.opacity(0.15))
                    .frame(width: 36, height: 36)
                Text("\(number)")
                    .font(.solBodyBold)
                    .foregroundStyle(Color.solPrimary)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(step.action)
                    .font(.solBodyBold)
                    .foregroundStyle(Color.solForeground)
                    .fixedSize(horizontal: false, vertical: true)
                if let saving = step.monthlySaving {
                    Text("Economisești ≈ \(saving.amount) RON/lună")
                        .font(.solCaption)
                        .foregroundStyle(Color.solPrimary)
                }
                HStack(spacing: SolSpacing.xs) {
                    LabelBadge(title: complexityLabel(step.complexity), color: complexityColor(step.complexity))
                    if let tool = step.tool {
                        LabelBadge(title: toolLabel(tool), color: .solCyan)
                    }
                }
            }
            Spacer()
        }
        .padding(SolSpacing.base)
        .solCard()
    }

    @ViewBuilder
    private var csalbCard: some View {
        VStack(alignment: .leading, spacing: SolSpacing.md) {
            HStack {
                IconContainer(systemName: "scale.3d", variant: .cyan, size: 44, iconSize: 18)
                VStack(alignment: .leading, spacing: 2) {
                    Text("CSALB poate ajuta")
                        .font(.solH3)
                        .foregroundStyle(Color.solForeground)
                    Text("Mediere gratuită cu IFN/banca")
                        .font(.solCaption)
                        .foregroundStyle(Color.solMuted)
                }
                Spacer()
            }
            Text("Centrul de Soluționare Alternativă a Litigiilor Bancare e o instituție gratuită care mediază dispute cu băncile și IFN-urile. Procesul durează 30-90 zile.")
                .font(.solBody)
                .foregroundStyle(Color.solMuted)
                .fixedSize(horizontal: false, vertical: true)
            SolomonButton("Începe procedura CSALB", icon: "arrow.up.right") {
                CSALBDeeplink.openStartProcedure()
            }
        }
        .padding(SolSpacing.cardStandard)
        .solAIInsightCard()
    }

    @ViewBuilder
    private func solomonNarrative(_ text: String) -> some View {
        HStack(alignment: .top, spacing: SolSpacing.sm) {
            IconContainer(systemName: "sparkles", variant: .neon, size: 32, iconSize: 12)
            Text(text)
                .font(.solBody)
                .foregroundStyle(Color.solForeground)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(SolSpacing.cardStandard)
        .solAIInsightCard()
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: SolSpacing.md) {
            IconContainer(systemName: "checkmark.shield.fill", variant: .neon, size: 64, iconSize: 26)
            Text("Niciun semn de spirală")
                .font(.solH3)
                .foregroundStyle(Color.solForeground)
            Text("Solomon nu detectează presiune financiară pe baza datelor curente.")
                .font(.solBody)
                .foregroundStyle(Color.solMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, SolSpacing.lg)
        }
        .padding(SolSpacing.xl)
    }

    // MARK: - Logic

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
                // Decode context din JSON
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

    private func severityTitle(_ s: SpiralSeverity) -> String {
        switch s {
        case .none:     return "Totul bine"
        case .low:      return "Atenție ușoară"
        case .medium:   return "Presiune financiară"
        case .high:     return "Spirală activă"
        case .critical: return "URGENȚĂ — Spirală critică"
        }
    }

    private func severityIcon(_ s: SpiralSeverity) -> String {
        switch s {
        case .none, .low: return "checkmark.shield.fill"
        case .medium:     return "exclamationmark.triangle.fill"
        case .high:       return "exclamationmark.circle.fill"
        case .critical:   return "exclamationmark.octagon.fill"
        }
    }

    private func severityColor(_ s: SpiralSeverity) -> Color {
        switch s {
        case .none, .low: return .solPrimary
        case .medium:     return .solWarning
        case .high, .critical: return .solDestructive
        }
    }

    private func severityVariant(_ s: SpiralSeverity) -> IconContainer.Variant {
        switch s {
        case .none, .low: return .neon
        case .medium:     return .warn
        case .high, .critical: return .danger
        }
    }

    private func factorIcon(_ f: SpiralFactorKind) -> String {
        switch f {
        case .balanceDeclining:        return "arrow.down.right"
        case .cardCreditIncreasing:    return "creditcard.fill"
        case .ifnActive:               return "exclamationmark.octagon.fill"
        case .obligationsExceedIncome: return "scalemass.fill"
        case .bnplStacking:            return "rectangle.stack.fill"
        case .overdraftFrequent:       return "minus.circle.fill"
        }
    }

    private func factorName(_ f: SpiralFactorKind) -> String {
        switch f {
        case .balanceDeclining:        return "Soldul scade"
        case .cardCreditIncreasing:    return "Datorie card de credit în creștere"
        case .ifnActive:               return "IFN activ"
        case .obligationsExceedIncome: return "Obligații peste venit"
        case .bnplStacking:            return "BNPL stack"
        case .overdraftFrequent:       return "Descoperit frecvent"
        }
    }

    private func complexityLabel(_ c: RecoveryComplexity) -> String {
        switch c {
        case .easy:        return "ușor"
        case .medium:      return "mediu"
        case .hard:        return "dificil"
        case .behavioral:  return "comportamental"
        }
    }

    private func complexityColor(_ c: RecoveryComplexity) -> Color {
        switch c {
        case .easy:        return .solPrimary
        case .medium:      return .solWarning
        case .hard:        return .solDestructive
        case .behavioral:  return .solCyan
        }
    }

    private func toolLabel(_ tool: RecoveryTool) -> String {
        switch tool {
        case .csalb:         return "CSALB"
        case .anpc:          return "ANPC"
        case .bankNegotiate: return "Negociere"
        case .selfService:   return "Self-service"
        }
    }
}
