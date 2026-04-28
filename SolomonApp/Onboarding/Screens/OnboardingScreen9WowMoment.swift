import SwiftUI
import SolomonCore

// MARK: - Ecran 9 — Wow Moment
//
// Conform spec §11 ecran 9:
//   - Generare LLM cu JSON schema "wow_moment" (vezi §6.2)
//   - Prezentare structurată în 7 secțiuni
//   - CTA principal: [Anulează abonamentele fantomă]
//   - CTA secundar: [Continuă cu Solomon]
//
// Faza 13: prezentăm un PLACEHOLDER vizual (numere mock) — generarea LLM
// reală vine în Faza 14 odată cu MLX integration.

struct OnboardingScreen9WowMoment: View {
    @EnvironmentObject var state: OnboardingState
    let onFinish: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: SolSpacing.lg) {

                // Trophy header (Penny mockup screen 16)
                VStack(spacing: SolSpacing.sm) {
                    ZStack {
                        Circle()
                            .fill(Color.solPrimary.opacity(0.15))
                            .frame(width: 80, height: 80)
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(LinearGradient.solHero)
                    }

                    Text("Bună, \(displayName)!")
                        .font(.solH1)
                        .foregroundStyle(Color.solForeground)

                    Text("Iată primul tău raport Solomon")
                        .font(.solBody)
                        .foregroundStyle(Color.solMuted)
                }
                .padding(.top, SolSpacing.lg)

                // Hero number
                VStack(spacing: 6) {
                    Text("Safe to Spend")
                        .font(.solCaption)
                        .foregroundStyle(Color.solMuted)
                        .textCase(.uppercase)
                        .tracking(1.5)
                    Text(safeToSpendFormatted)
                        .font(.system(size: 56, weight: .bold, design: .monospaced))
                        .foregroundStyle(LinearGradient.solHero)
                    Text("\(perDay) RON / zi · \(daysLeft) zile rămase")
                        .font(.solCaption)
                        .foregroundStyle(Color.solMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, SolSpacing.xl)
                .solGlassCard()

                // Insights placeholder (3 cards)
                VStack(spacing: SolSpacing.sm) {
                    insightCard(
                        icon: "exclamationmark.triangle.fill",
                        variant: .warn,
                        title: "Abonamente fantomă",
                        body: "Avem 2 abonamente nefolosite — ai economisi 78 RON/lună dacă le anulezi."
                    )
                    insightCard(
                        icon: "chart.line.uptrend.xyaxis",
                        variant: .neon,
                        title: "Pattern detectat",
                        body: "Cheltuiești 31% pe livrări mâncare. Media e 12% pentru profilul tău."
                    )
                    insightCard(
                        icon: "checkmark.shield.fill",
                        variant: .neon,
                        title: "Zero IFN, zero BNPL",
                        body: "Nu ai datorii toxice active. Bravo!"
                    )
                }

                Spacer().frame(height: SolSpacing.lg)

                // CTAs
                VStack(spacing: SolSpacing.sm) {
                    SolomonButton("Anulează abonamentele fantomă", icon: "scissors") {
                        finish()
                    }
                    SolomonButton("Continuă cu Solomon", style: .secondary) {
                        finish()
                    }
                }
            }
            .padding(.horizontal, SolSpacing.screenHorizontal)
            .padding(.bottom, SolSpacing.xl)
        }
    }

    // MARK: - Mock data

    private var displayName: String {
        state.name.isEmpty ? "prieten" : state.name
    }

    private var safeToSpendValue: Int {
        // Estimare simplificată: salariul - obligații
        let salary = state.salaryRange?.midpointRON ?? 5000
        let obligations = state.draftObligations.reduce(0) { $0 + $1.amountRON }
        return max(0, salary - obligations - 1500)  // -1500 reservation pentru utilities/food
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

    // MARK: - Subview

    private func insightCard(icon: String, variant: IconContainer.Variant, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: SolSpacing.md) {
            IconContainer(systemName: icon, variant: variant, size: 36, iconSize: 14)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.solBodyBold)
                    .foregroundStyle(Color.solForeground)
                Text(body)
                    .font(.solCaption)
                    .foregroundStyle(Color.solMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(SolSpacing.base)
        .solCard()
    }

    // MARK: - Finish

    private func finish() {
        onFinish()
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
