import SwiftUI
import SolomonCore
import SolomonStorage
import SolomonMoments

// MARK: - Ecran 9 — Wow Moment (HIG aligned + MomentEngine real)
//
// Refactor Faza 27: wired la MomentEngine.generateWowMoment cu demo data
// auto-generat din onboarding state. User vede răspuns LLM real (cu fallback
// Template dacă MLX nu e disponibil) cu cifrele lui personalizate.

struct OnboardingScreen9WowMoment: View {
    @EnvironmentObject var state: OnboardingState
    let onFinish: () -> Void

    @State private var llmResponse: String?
    @State private var isGenerating: Bool = true
    // Engine e creat în generateMoment() cu provider-ul real injectat

    var body: some View {
        ScrollView {
            VStack(spacing: SolSpacing.lg) {

                // Hero block
                VStack(spacing: SolSpacing.md) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 56, weight: .light))
                        .foregroundStyle(LinearGradient.solHero)
                        .symbolRenderingMode(.hierarchical)
                        .frame(width: 96, height: 96)
                        .background(
                            Circle()
                                .fill(Color.solPrimary.opacity(0.15))
                        )

                    Text("Bună, \(displayName)")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(Color.solForeground)

                    Text("Iată primul tău raport Solomon")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, SolSpacing.lg)

                // Hero amount
                VStack(spacing: SolSpacing.xs) {
                    Text("Safe to Spend")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)

                    Text(safeToSpendFormatted)
                        .font(.solHeroBig)
                        .foregroundStyle(LinearGradient.solHero)

                    Text("\(perDay) RON / zi · \(daysLeft) zile rămase")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, SolSpacing.xl)
                .solGlassCard()

                // LLM response (Solomon "vorbește")
                if isGenerating {
                    HStack(spacing: SolSpacing.sm) {
                        ProgressView()
                            .controlSize(.small)
                            .tint(Color.solPrimary)
                        Text("Solomon analizează...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(SolSpacing.base)
                    .frame(maxWidth: .infinity)
                    .solCard()
                } else if let llm = llmResponse, !llm.isEmpty {
                    HStack(alignment: .top, spacing: SolSpacing.sm) {
                        Image(systemName: "sparkles")
                            .font(.body)
                            .foregroundStyle(Color.solPrimary)
                        Text(llm)
                            .font(.body)
                            .foregroundStyle(Color.solForeground)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(SolSpacing.base)
                    .solAIInsightCard()
                }

                // Insights dinamice derivate din datele introduse în onboarding
                if !dynamicInsights.isEmpty {
                    VStack(spacing: SolSpacing.sm) {
                        ForEach(dynamicInsights.indices, id: \.self) { idx in
                            let item = dynamicInsights[idx]
                            insightRow(icon: item.icon, iconColor: item.color,
                                       title: item.title, body: item.body)
                        }
                    }
                }
            }
            .padding(.horizontal, SolSpacing.lg)
            .padding(.bottom, SolSpacing.xxxl)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: SolSpacing.sm) {
                SolomonButton("Continuă cu Solomon", icon: "arrow.right") {
                    Haptics.success()
                    onFinish()
                }
            }
            .padding(.horizontal, SolSpacing.lg)
            .padding(.vertical, SolSpacing.base)
            .background(.ultraThinMaterial)
        }
        .task {
            await generateMoment()
        }
    }

    // MARK: - Insight row

    @ViewBuilder
    private func insightRow(icon: String, iconColor: Color, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: SolSpacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(iconColor)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.solForeground)
                Text(body)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(SolSpacing.base)
        .solCard()
    }

    // MARK: - Generation

    private func generateMoment() async {
        isGenerating = true
        defer { isGenerating = false }

        // Construim un Snapshot minimal din state (fără să atingem CoreData încă)
        let demographic = DemographicProfile(
            name: state.name.isEmpty ? "prietene" : state.name,
            addressing: state.addressing,
            ageRange: .range25to35
        )
        let financial = FinancialProfile(
            salaryRange: state.salaryRange ?? .range5to8,
            salaryFrequency: .monthly(dayOfMonth: state.paydayDay),
            hasSecondaryIncome: state.hasSecondaryIncome,
            primaryBank: state.primaryBank ?? .other
        )
        let profile = UserProfile(demographics: demographic, financials: financial)

        // Construim obligații din draft (cele cu nume + sumă valid)
        let obligations: [Obligation] = state.draftObligations
            .filter { !$0.name.isEmpty && $0.amountRON > 0 }
            .map { d in
                Obligation(
                    id: UUID(),
                    name: d.name,
                    amount: Money(d.amountRON),
                    dayOfMonth: d.dayOfMonth,
                    kind: d.kind,
                    confidence: .declared,
                    since: Date()
                )
            }

        let snapshot = MomentEngine.Snapshot(
            userProfile: profile,
            transactions: [],
            obligations: obligations,
            subscriptions: [],
            goals: []
        )

        // Injectăm provider-ul real (MLX dacă e descărcat, Template fallback)
        let engine = MomentEngine(llm: ModelDownloadService.shared.makeLLMProvider())
        do {
            let output = try await engine.generateWowMoment(snapshot: snapshot)
            llmResponse = output.llmResponse
        } catch {
            llmResponse = nil
        }
    }

    // MARK: - Dynamic insights derivate din datele onboarding

    private struct InsightItem {
        let icon: String
        let color: Color
        let title: String
        let body: String
    }

    private var dynamicInsights: [InsightItem] {
        var items: [InsightItem] = []
        let salary = state.salaryRange?.midpointRON ?? 5000

        // 1. IFN / BNPL check
        let hasIFN = state.draftObligations.contains { $0.kind == .loanIFN || $0.kind == .bnpl }
        if hasIFN {
            let ifnTotal = state.draftObligations
                .filter { $0.kind == .loanIFN || $0.kind == .bnpl }
                .reduce(0) { $0 + $1.amountRON }
            items.append(InsightItem(
                icon: "exclamationmark.triangle.fill",
                color: .solWarning,
                title: "IFN / BNPL activ",
                body: "\(ifnTotal) RON/lună în credite scumpe — Solomon monitorizează."
            ))
        } else {
            items.append(InsightItem(
                icon: "checkmark.shield.fill",
                color: .solPrimary,
                title: "Zero IFN, zero BNPL",
                body: "Nu ai datorii toxice. Excelent punct de plecare!"
            ))
        }

        // 2. Rata obligații / venit
        let totalObligations = state.draftObligations.reduce(0) { $0 + $1.amountRON }
        if totalObligations > 0 && salary > 0 {
            let ratio = Int(Double(totalObligations) / Double(salary) * 100)
            if ratio > 50 {
                items.append(InsightItem(
                    icon: "exclamationmark.circle.fill",
                    color: .solWarning,
                    title: "Obligații ridicate",
                    body: "\(ratio)% din venit pe obligații fixe. Solomon va alerta dacă cresc."
                ))
            } else {
                items.append(InsightItem(
                    icon: "checkmark.circle.fill",
                    color: .solPrimary,
                    title: "Obligații sub control",
                    body: "\(ratio)% din venit — în parametri sănătoși."
                ))
            }
        }

        return items
    }

    // MARK: - Mock cifre din state

    private var displayName: String {
        state.name.isEmpty ? "prieten" : state.name
    }

    private var safeToSpendValue: Int {
        let salary = state.salaryRange?.midpointRON ?? 5000
        let obligations = state.draftObligations.reduce(0) { $0 + $1.amountRON }
        return max(0, salary - obligations - 1500)
    }

    private var safeToSpendFormatted: String {
        RomanianMoneyFormatter.format(Money(safeToSpendValue))
    }

    private var perDay: Int {
        guard daysLeft > 0 else { return 0 }
        return safeToSpendValue / daysLeft
    }

    private var daysLeft: Int {
        let cal = Calendar.current
        let today = cal.component(.day, from: Date())
        let payday = state.paydayDay
        return payday > today ? (payday - today) : (30 - today + payday)
    }
}

#Preview {
    ZStack {
        Color.solCanvas.ignoresSafeArea()
        OnboardingScreen9WowMoment(onFinish: {})
            .environmentObject({
                let s = OnboardingState()
                s.name = "Andrei"
                s.salaryRange = .range5to8
                s.paydayDay = 15
                return s
            }())
    }
    .preferredColorScheme(.dark)
}
