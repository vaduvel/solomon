import SwiftUI

// MARK: - Ecran 1 — Welcome (Apple HIG aligned)
//
// Pattern HIG: hero icon + tagline central + 3 feature rows + CTA bottom-anchored.
// Spec §11 ecran 1 — păstrăm conținutul, refactor layout.

struct OnboardingScreen1Welcome: View {
    @Environment(OnboardingState.self) var state

    var body: some View {
        VStack(spacing: 0) {

            Spacer()

            // Logo gradient
            ZStack {
                Circle()
                    .fill(LinearGradient.solHero)
                    .frame(width: 96, height: 96)
                    .shadow(color: Color.solPrimary.opacity(0.4), radius: 24, x: 0, y: 8)
                Text("S")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(Color.solCanvas)
            }

            VStack(spacing: SolSpacing.xs) {
                Text("Solomon")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(Color.solForeground)

                Text("Înțelepciune pentru banii tăi")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, SolSpacing.xl)

            Spacer().frame(height: SolSpacing.xxl)

            // Feature rows (HIG list-like)
            VStack(spacing: SolSpacing.base) {
                featureRow(icon: "brain.head.profile", text: "Învăț din comportamentul tău")
                featureRow(icon: "lightbulb.fill", text: "Îți arăt ce să faci cu banii")
                featureRow(icon: "heart.fill", text: "Fără judecăți, doar fapte")
            }
            .padding(.horizontal, SolSpacing.lg)

            Spacer()

            // Privacy + CTA bottom
            VStack(spacing: SolSpacing.base) {
                HStack(spacing: SolSpacing.xs) {
                    Image(systemName: "lock.shield.fill")
                        .font(.footnote)
                        .foregroundStyle(Color.solPrimary)
                    Text("100% pe telefonul tău. Datele nu pleacă nicăieri.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                SolomonButton("Hai să ne cunoaștem", icon: "arrow.right") {
                    Haptics.medium()
                    state.next()
                }

                Text("Durează 3 minute")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, SolSpacing.lg)
            .padding(.bottom, SolSpacing.lg)
        }
    }

    @ViewBuilder
    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: SolSpacing.base) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.solPrimary)
                .frame(width: 32)
                .symbolRenderingMode(.hierarchical)
            Text(text)
                .font(.body)
                .foregroundStyle(Color.solForeground)
            Spacer()
        }
    }
}

#Preview {
    ZStack {
        Color.solCanvas.ignoresSafeArea()
        OnboardingScreen1Welcome()
            .environment(OnboardingState())
    }
    .preferredColorScheme(.dark)
}
