import SwiftUI
import SolomonCore

// MARK: - Ecran 4 — Bancă principală (Solomon DS, wallet.html aligned)

struct OnboardingScreen4Bank: View {
    @Environment(OnboardingState.self) var state: OnboardingState

    private let banks: [(Bank, SolBrandLogo.Brand)] = [
        (.ing, .ing),
        (.bancaTransilvania, .bt),
        (.raiffeisen, .raiffeisen),
        (.brd, .brd),
        (.bcr, .bcr),
        (.other, .dotted)
    ]

    var body: some View {
        @Bindable var state = state
        ZStack {
            MeshBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: SolSpacing.xl) {

                    VStack(alignment: .leading, spacing: SolSpacing.sm) {
                        Text("PASUL 4")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.solMintLight)
                            .tracking(1.4)
                            .textCase(.uppercase)

                        Text("Care e banca ta principală?")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(Color.white)
                            .tracking(-0.5)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Selectează banca unde îți intră salariul.")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.white.opacity(0.55))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, SolSpacing.lg)

                    SolListCard {
                        ForEach(Array(banks.enumerated()), id: \.offset) { idx, item in
                            let bank = item.0
                            let brand = item.1
                            let isSelected = state.primaryBank == bank

                            SolListRow(
                                title: bank.displayNameRO,
                                onTap: {
                                    Haptics.selection()
                                    state.primaryBank = bank
                                },
                                leading: { SolBrandLogo(brand) },
                                trailing: {
                                    if isSelected {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(Color.solMintExact)
                                    }
                                }
                            )

                            if idx < banks.count - 1 {
                                SolHairlineDivider()
                            }
                        }
                    }

                    Spacer(minLength: SolSpacing.lg)
                }
                .padding(.horizontal, SolSpacing.lg)
                .padding(.bottom, SolSpacing.xxxl)
            }
            .safeAreaInset(edge: .bottom) {
                SolPrimaryButton("Continuă", fullWidth: true) {
                    state.next()
                }
                .opacity(state.canProceedFromCurrentStep ? 1 : 0.4)
                .disabled(!state.canProceedFromCurrentStep)
                .padding(.horizontal, SolSpacing.lg)
                .padding(.vertical, SolSpacing.base)
            }
        }
    }
}

#Preview {
    OnboardingScreen4Bank()
        .environment(OnboardingState())
        .preferredColorScheme(.dark)
}
