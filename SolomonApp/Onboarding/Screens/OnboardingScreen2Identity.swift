import SwiftUI
import SolomonCore

// MARK: - Ecran 2 — Identitate (30 sec)
//
// Conform spec §11 ecran 2:
//   - Input: "Cum te cheamă?"
//   - Toggle: "Cum vrei să-ți zic? [Pe nume / Formal]"
//   - CTA: [Continuă →]

struct OnboardingScreen2Identity: View {
    @EnvironmentObject var state: OnboardingState

    var body: some View {
        VStack(spacing: SolSpacing.xl) {
            VStack(spacing: SolSpacing.sm) {
                Text("Hai să ne cunoaștem")
                    .font(.solH1)
                    .foregroundStyle(Color.solForeground)

                Text("Cum te cheamă?")
                    .font(.solBody)
                    .foregroundStyle(Color.solMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, SolSpacing.lg)

            SolomonTextInput(
                placeholder: "ex: Andrei",
                text: $state.name,
                icon: "person.fill"
            )

            VStack(alignment: .leading, spacing: SolSpacing.sm) {
                Text("Cum vrei să-ți zic?")
                    .font(.solCaption)
                    .foregroundStyle(Color.solMuted)
                    .textCase(.uppercase)
                    .tracking(1.2)

                HStack(spacing: SolSpacing.sm) {
                    SelectableChip(
                        title: "Pe nume (tu)",
                        isSelected: state.addressing == .tu
                    ) {
                        state.addressing = .tu
                    }
                    SelectableChip(
                        title: "Formal (dvs.)",
                        isSelected: state.addressing == .dumneavoastra
                    ) {
                        state.addressing = .dumneavoastra
                    }
                    Spacer()
                }
            }

            Spacer()

            SolomonButton("Continuă", icon: "arrow.right") {
                state.next()
            }
            .opacity(state.canProceedFromCurrentStep ? 1 : 0.4)
            .disabled(!state.canProceedFromCurrentStep)
        }
        .padding(.horizontal, SolSpacing.screenHorizontal)
        .padding(.bottom, SolSpacing.xl)
    }
}

#Preview {
    ZStack {
        Color.solCanvas.ignoresSafeArea()
        OnboardingScreen2Identity()
            .environmentObject(OnboardingState())
    }
    .preferredColorScheme(.dark)
}
