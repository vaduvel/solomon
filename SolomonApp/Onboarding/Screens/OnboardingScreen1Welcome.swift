import SwiftUI

// MARK: - Ecran 1 — Welcome (15 sec)
//
// Conform spec §11 ecran 1:
//   - Logo Solomon
//   - Tagline: "Înțelepciune pentru banii tăi"
//   - 3 chips features
//   - Subtitle: "100% pe telefonul tău. Datele nu pleacă nicăieri."
//   - CTA: [Hai să ne cunoaștem →]
//   - Mic text: "Durează 3 minute"

struct OnboardingScreen1Welcome: View {
    @EnvironmentObject var state: OnboardingState

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: SolSpacing.xxl)

            // Logo S în cerc gradient
            ZStack {
                Circle()
                    .fill(LinearGradient.solHero)
                    .frame(width: 96, height: 96)
                    .shadow(color: Color.solPrimary.opacity(0.4), radius: 24, x: 0, y: 8)
                Text("S")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(Color.solCanvas)
            }
            .padding(.bottom, SolSpacing.lg)

            Text("Solomon")
                .font(.solDisplay)
                .foregroundStyle(Color.solForeground)

            Text("Înțelepciune pentru banii tăi")
                .font(.solBody)
                .foregroundStyle(Color.solMuted)
                .padding(.top, 4)

            Spacer().frame(height: SolSpacing.xl)

            // 3 feature chips
            VStack(spacing: SolSpacing.sm) {
                FeatureChip(title: "Învăț din comportamentul tău")
                FeatureChip(title: "Îți arăt ce să faci cu banii")
                FeatureChip(title: "Fără judecăți, doar fapte")
            }
            .padding(.horizontal, SolSpacing.screenHorizontal)

            Spacer()

            VStack(spacing: SolSpacing.sm) {
                Text("100% pe telefonul tău. Datele nu pleacă nicăieri.")
                    .font(.solCaption)
                    .foregroundStyle(Color.solMuted)
                    .multilineTextAlignment(.center)

                SolomonButton("Hai să ne cunoaștem", icon: "arrow.right") {
                    state.next()
                }

                Text("Durează 3 minute")
                    .font(.solMicro)
                    .foregroundStyle(Color.solMuted)
            }
            .padding(.horizontal, SolSpacing.screenHorizontal)
            .padding(.bottom, SolSpacing.xl)
        }
    }
}

#Preview {
    ZStack {
        Color.solCanvas.ignoresSafeArea()
        OnboardingScreen1Welcome()
            .environmentObject(OnboardingState())
    }
    .preferredColorScheme(.dark)
}
