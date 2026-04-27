import SwiftUI
import SolomonCore

// MARK: - Ecran 4 — Bancă principală (15 sec)
//
// Conform spec §11 ecran 4:
//   - Întrebare: "La ce bancă ai contul principal?"
//   - Chips: BT / BCR / ING / Raiffeisen / Revolut / [Altă]

struct OnboardingScreen4Bank: View {
    @EnvironmentObject var state: OnboardingState

    var body: some View {
        VStack(spacing: SolSpacing.xl) {
            VStack(alignment: .leading, spacing: SolSpacing.sm) {
                Text("Banca ta principală")
                    .font(.solH1)
                    .foregroundStyle(Color.solForeground)
                Text("Selectează banca unde îți intră salariul.")
                    .font(.solBody)
                    .foregroundStyle(Color.solMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, SolSpacing.lg)

            BankPicker(selectedBank: $state.primaryBank)

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
        OnboardingScreen4Bank()
            .environmentObject(OnboardingState())
    }
    .preferredColorScheme(.dark)
}
