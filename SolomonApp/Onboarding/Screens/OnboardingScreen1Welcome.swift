import SwiftUI

// MARK: - Ecran 1 — Welcome (Solomon DS · Claude Design v3)
//
// Layout:
//   - MeshBackground full-screen (mint/blue/violet)
//   - Logo 96×96 cu gradient mint→deep + glow shadow
//   - Wordmark "Solomon" + tagline mut
//   - 3 feature rows în glass card (SolListCard + SolListRow cu iconițe accent)
//   - Privacy text mic + SolPrimaryButton fullWidth → state.next()

struct OnboardingScreen1Welcome: View {
    @Environment(OnboardingState.self) var state

    var body: some View {
        ZStack {
            MeshBackground()

            VStack(spacing: 0) {

                Spacer()

                // Logo 96×96 — mint→deep gradient + glow
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.solMintExact, Color.solMintDeep],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 96, height: 96)
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(Color.white.opacity(0.20), lineWidth: 1)
                                .blendMode(.plusLighter)
                        )
                        .shadow(color: Color.solMintExact.opacity(0.45), radius: 30, x: 0, y: 12)
                        .shadow(color: Color.solMintExact.opacity(0.25), radius: 60, x: 0, y: 0)

                    Text("S")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(Color(red: 0x05/255, green: 0x2E/255, blue: 0x16/255))
                        .tracking(-1)
                }

                // Wordmark + tagline
                VStack(spacing: 8) {
                    Text("Solomon")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundStyle(Color.white)
                        .tracking(-1.2)

                    Text("Înțelepciune pentru banii tăi")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(Color.white.opacity(0.55))
                        .tracking(-0.2)
                }
                .padding(.top, 28)

                Spacer()

                // 3 feature rows în glass card
                SolListCard {
                    SolListRow(
                        title: "Învăț din comportamentul tău",
                        leading: { featureIcon("brain.head.profile", accent: .mint) },
                        trailing: { EmptyView() }
                    )
                    SolHairlineDivider()
                    SolListRow(
                        title: "Îți arăt ce să faci cu banii",
                        leading: { featureIcon("lightbulb.fill", accent: .amber) },
                        trailing: { EmptyView() }
                    )
                    SolHairlineDivider()
                    SolListRow(
                        title: "Fără judecăți, doar fapte",
                        leading: { featureIcon("heart.fill", accent: .rose) },
                        trailing: { EmptyView() }
                    )
                }
                .padding(.horizontal, SolSpacing.lg)

                Spacer()

                // Privacy text + CTA
                VStack(spacing: 16) {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.solMintLight)
                        Text("100% pe telefonul tău. Datele nu pleacă nicăieri.")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(Color.white.opacity(0.45))
                            .tracking(0.2)
                    }

                    SolPrimaryButton("Începe", fullWidth: true) {
                        state.next()
                    }
                }
                .padding(.horizontal, SolSpacing.lg)
                .padding(.bottom, SolSpacing.lg)
            }
        }
    }

    @ViewBuilder
    private func featureIcon(_ system: String, accent: SolAccent) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(accent.iconGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .stroke(accent.color.opacity(0.25), lineWidth: 1)
                )
            Image(systemName: system)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(accent.color)
        }
        .frame(width: 36, height: 36)
        .shadow(color: accent.color.opacity(0.18), radius: 10)
    }
}

#Preview {
    OnboardingScreen1Welcome()
        .environment(OnboardingState())
        .preferredColorScheme(.dark)
}
