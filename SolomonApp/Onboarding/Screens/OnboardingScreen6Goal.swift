import SwiftUI

// MARK: - Ecran 6 — Obiectiv (HIG aligned)

struct OnboardingScreen6Goal: View {
    @Environment(OnboardingState.self) var state: OnboardingState

    var body: some View {
        @Bindable var state = state
        ScrollView {
            VStack(alignment: .leading, spacing: SolSpacing.xxl) {

                VStack(alignment: .leading, spacing: SolSpacing.xs) {
                    Text("Ce vrei să rezolvi?")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(Color.solForeground)
                    Text("Selectează tot ce ți se aplică.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, SolSpacing.lg)

                // Goal options as native list-style toggles
                VStack(spacing: SolSpacing.sm) {
                    ForEach(OnboardingState.GoalChip.allCases, id: \.self) { chip in
                        goalRow(chip: chip)
                    }
                }

                // Big goal optional
                VStack(alignment: .leading, spacing: SolSpacing.sm) {
                    Text("Ai un obiectiv mare?")
                        .font(.headline)
                        .foregroundStyle(Color.solForeground)
                    Text("Vacanță, mașină, casă...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    SolomonTextInput(
                        placeholder: "ex: Vacanță în Grecia",
                        text: $state.bigGoalText,
                        icon: "target"
                    )
                }

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

    @ViewBuilder
    private func goalRow(chip: OnboardingState.GoalChip) -> some View {
        let isSelected = state.selectedGoals.contains(chip)
        Button {
            Haptics.selection()
            if isSelected {
                state.selectedGoals.remove(chip)
            } else {
                state.selectedGoals.insert(chip)
            }
        } label: {
            HStack(spacing: SolSpacing.md) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.solPrimary : Color.solMuted)
                    .symbolRenderingMode(.hierarchical)
                Text(chip.rawValue)
                    .font(.body)
                    .foregroundStyle(Color.solForeground)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            .padding(SolSpacing.base)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.solPrimary.opacity(0.08) : Color.solCard)
            .clipShape(RoundedRectangle(cornerRadius: SolRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: SolRadius.lg)
                    .stroke(isSelected ? Color.solPrimary.opacity(0.4) : Color.solBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        Color.solCanvas.ignoresSafeArea()
        OnboardingScreen6Goal()
            .environment({
                let s = OnboardingState()
                s.selectedGoals = [.noZeroOn22]
                return s
            }())
    }
    .preferredColorScheme(.dark)
}
