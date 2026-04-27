import SwiftUI

// MARK: - Ecran 6 — Obiectiv (20 sec)
//
// Conform spec §11 ecran 6:
//   - "Ce vrei să rezolvi cu Solomon?"
//   - Multi-select chips
//   - Câmp opțional: "Ai un obiectiv mare?"

struct OnboardingScreen6Goal: View {
    @EnvironmentObject var state: OnboardingState

    var body: some View {
        ScrollView {
            VStack(spacing: SolSpacing.xl) {
                VStack(alignment: .leading, spacing: SolSpacing.sm) {
                    Text("Ce vrei să rezolvi cu Solomon?")
                        .font(.solH1)
                        .foregroundStyle(Color.solForeground)
                    Text("Selectează tot ce ți se aplică.")
                        .font(.solBody)
                        .foregroundStyle(Color.solMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, SolSpacing.lg)

                // Multi-select chips
                FlowLayout(spacing: SolSpacing.sm) {
                    ForEach(OnboardingState.GoalChip.allCases, id: \.self) { chip in
                        MultiSelectChip(
                            title: chip.rawValue,
                            isSelected: state.selectedGoals.contains(chip)
                        ) {
                            if state.selectedGoals.contains(chip) {
                                state.selectedGoals.remove(chip)
                            } else {
                                state.selectedGoals.insert(chip)
                            }
                        }
                    }
                }

                // Big goal opțional
                VStack(alignment: .leading, spacing: SolSpacing.sm) {
                    Text("Ai un obiectiv mare? (opțional)")
                        .font(.solBodyBold)
                        .foregroundStyle(Color.solForeground)
                    Text("Vacanță, mașină, casă...")
                        .font(.solCaption)
                        .foregroundStyle(Color.solMuted)

                    SolomonTextInput(
                        placeholder: "ex: Vacanță în Grecia",
                        text: $state.bigGoalText,
                        icon: "target"
                    )
                }

                Spacer().frame(height: SolSpacing.lg)

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
}

// MARK: - FlowLayout (helper pentru wrapping chips)

struct FlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (offset, subview) in zip(result.offsets, subviews) {
            subview.place(at: CGPoint(x: bounds.minX + offset.x, y: bounds.minY + offset.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (offsets: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var offsets: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            offsets.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            totalWidth = max(totalWidth, x)
        }
        return (offsets, CGSize(width: totalWidth, height: y + rowHeight))
    }
}

#Preview {
    ZStack {
        Color.solCanvas.ignoresSafeArea()
        OnboardingScreen6Goal()
            .environmentObject({
                let s = OnboardingState()
                s.selectedGoals = [.noZeroOn22, .saveMonthly]
                return s
            }())
    }
    .preferredColorScheme(.dark)
}
