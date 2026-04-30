import SwiftUI
import SolomonCore
import SolomonStorage
import SolomonMoments

// MARK: - Ecran 9 — Wow Moment (Solomon DS v3 editorial premium)

struct OnboardingScreen9WowMoment: View {
    @Environment(OnboardingState.self) var state
    let onFinish: () -> Void

    @State private var llmResponse: String?
    @State private var isGenerating: Bool = true

    var body: some View {
        ZStack {
            MeshBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: SolSpacing.lg) {

                    // Eyebrow + Titlu mare
                    VStack(alignment: .leading, spacing: SolSpacing.sm) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.solMintExact)
                                .frame(width: 6, height: 6)
                                .shadow(color: Color.solMintExact, radius: 5)
                            Text("ULTIMUL PAS · GATA")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color.solMintLight)
                                .tracking(1.4)
                        }

                        Text("Iată ce am găsit, \(displayName)")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(Color.white)
                            .tracking(-0.6)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, SolSpacing.md)

                    // Hero card — Safe to Spend
                    SolHeroCard(
                        accent: .mint,
                        content: {
                            VStack(alignment: .leading, spacing: SolSpacing.md) {
                                SolHeroLabel("DISPONIBIL ESTIMAT · \(daysLeft) ZILE")
                                SolHeroAmount(
                                    amount: heroAmountString,
                                    decimals: nil,
                                    currency: "RON",
                                    accent: .mint
                                )
                                Text("≈ \(perDay) RON/zi · până \(paydayLabel)")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Color.white.opacity(0.55))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        },
                        badge: {
                            SolHeroBadge("PRIMUL TĂU SAFE TO SPEND", accent: .mint)
                        }
                    )

                    // Insight card — Solomon vorbește
                    SolInsightCard(
                        icon: "sparkles",
                        label: "SOLOMON SPUNE",
                        timestamp: "primul tău raport",
                        accent: .mint
                    ) {
                        if let llm = llmResponse, !llm.isEmpty {
                            Text(llm)
                                .font(.system(size: 14))
                                .foregroundStyle(Color.white.opacity(0.85))
                                .fixedSize(horizontal: false, vertical: true)
                                .lineSpacing(3)
                        } else if isGenerating {
                            VStack(alignment: .leading, spacing: 8) {
                                skeletonLine(width: .infinity)
                                skeletonLine(width: 240)
                                skeletonLine(width: 180)
                            }
                            .padding(.top, 4)
                        } else {
                            Text("Solomon analizează cifrele tale și pregătește primul raport personalizat.")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.white.opacity(0.7))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    // Stats triplet
                    HStack(spacing: SolSpacing.sm) {
                        SolStatCard(
                            label: "LUNAR",
                            name: "Economie",
                            value: "\(monthlySaving)",
                            meta: "RON estimat",
                            metaAccent: .mint,
                            icon: "arrow.up.right",
                            iconAccent: .mint
                        )
                        SolStatCard(
                            label: "FIXE",
                            name: "Abonamente",
                            value: "\(subscriptionCount)",
                            meta: subscriptionCount == 1 ? "activ" : "active",
                            metaAccent: .blue,
                            icon: "repeat",
                            iconAccent: .blue
                        )
                        SolStatCard(
                            label: "LUNAR",
                            name: "Obligații",
                            value: "\(totalObligations)",
                            meta: "RON/lună",
                            metaAccent: .amber,
                            icon: "calendar",
                            iconAccent: .amber
                        )
                    }

                    // CTA primary
                    SolPrimaryButton("Începe să folosești Solomon", accent: .mint, fullWidth: true) {
                        Haptics.success()
                        onFinish()
                    }
                    .padding(.top, SolSpacing.sm)
                }
                .padding(.horizontal, SolSpacing.lg)
                .padding(.bottom, SolSpacing.xxxl)
            }
        }
        .task {
            await generateMoment()
        }
    }

    // MARK: - Skeleton

    @ViewBuilder
    private func skeletonLine(width: CGFloat) -> some View {
        Capsule()
            .fill(Color.white.opacity(0.06))
            .frame(width: width == .infinity ? nil : width, height: 10)
            .frame(maxWidth: width == .infinity ? .infinity : nil, alignment: .leading)
    }

    // MARK: - Generation

    private func generateMoment() async {
        isGenerating = true
        defer { isGenerating = false }

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

        let engine = MomentEngine(llm: ModelDownloadService.shared.makeLLMProvider())
        do {
            let output = try await engine.generateWowMoment(snapshot: snapshot)
            llmResponse = output.llmResponse
        } catch {
            llmResponse = nil
        }
    }

    // MARK: - Derived

    private var displayName: String {
        state.name.isEmpty ? "prieten" : state.name
    }

    private var salaryMidpoint: Int {
        state.salaryRange?.midpointRON ?? SolomonDefaults.salaryMidpointFallbackRON
    }

    private var totalObligations: Int {
        state.draftObligations.reduce(0) { $0 + $1.amountRON }
    }

    private var safeToSpendValue: Int {
        max(0, salaryMidpoint - totalObligations)
    }

    private var heroAmountString: String {
        // ex "3.450" — fără decimal
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = "."
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: safeToSpendValue)) ?? "\(safeToSpendValue)"
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

    private var paydayLabel: String {
        "ziua \(state.paydayDay)"
    }

    private var subscriptionCount: Int {
        state.draftObligations.filter { $0.kind == .subscription }.count
    }

    /// Estimare rough: 10% din safe-to-spend reprezintă potențial de economisire.
    private var monthlySaving: Int {
        max(0, Int(Double(safeToSpendValue) * 0.10))
    }
}

#Preview {
    OnboardingScreen9WowMoment(onFinish: {})
        .environment({
            let s = OnboardingState()
            s.name = "Andrei"
            s.salaryRange = .range5to8
            s.paydayDay = 15
            return s
        }())
        .preferredColorScheme(.dark)
}
