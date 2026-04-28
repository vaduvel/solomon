import SwiftUI
import SolomonCore

// MARK: - Ecran 4 — Bancă principală (HIG aligned)

struct OnboardingScreen4Bank: View {
    @EnvironmentObject var state: OnboardingState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SolSpacing.xxl) {

                VStack(alignment: .leading, spacing: SolSpacing.xs) {
                    Text("Banca ta principală")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(Color.solForeground)
                    Text("Selectează banca unde îți intră salariul.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, SolSpacing.lg)

                BankPicker(selectedBank: $state.primaryBank)

                Spacer(minLength: SolSpacing.lg)
            }
            .padding(.horizontal, SolSpacing.lg)
            .padding(.bottom, SolSpacing.xxxl)
        }
        .safeAreaInset(edge: .bottom) {
            SolomonButton("Continuă", icon: "arrow.right") {
                Haptics.medium()
                state.next()
            }
            .opacity(state.canProceedFromCurrentStep ? 1 : 0.4)
            .disabled(!state.canProceedFromCurrentStep)
            .padding(.horizontal, SolSpacing.lg)
            .padding(.vertical, SolSpacing.base)
            .background(.ultraThinMaterial)
        }
    }
}

#Preview {
    ZStack {
        Color.solCanvas.ignoresSafeArea()
        OnboardingScreen4Bank()
            .environmentObject(OnboardingState())
    }
    .preferredColorScheme(.dark)
}
