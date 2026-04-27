import SwiftUI

// MARK: - OnboardingStepDots
//
// Progress indicator pentru onboarding (top of screen).
// Pattern din Penny DS v1.0:
//   - Active dot: w-6 (24px) pill, mint, neon glow
//   - Inactive dot: w-1.5 (6px) circle, muted
//   - h-3px
//
// Folosit în toate cele 9 ecrane onboarding.

struct OnboardingStepDots: View {
    let totalSteps: Int
    let currentStep: Int  // 0-indexed

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Capsule()
                    .fill(color(for: index))
                    .frame(
                        width: index == currentStep ? 24 : 6,
                        height: 3
                    )
                    .shadow(
                        color: index == currentStep
                            ? Color.solPrimary.opacity(0.6)
                            : Color.clear,
                        radius: 4,
                        x: 0,
                        y: 0
                    )
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentStep)
            }
        }
    }

    private func color(for index: Int) -> Color {
        if index <= currentStep {
            return Color.solPrimary
        } else {
            return Color.white.opacity(0.15)
        }
    }
}

#Preview {
    ZStack {
        Color.solCanvas.ignoresSafeArea()
        VStack(spacing: 24) {
            OnboardingStepDots(totalSteps: 9, currentStep: 0)
            OnboardingStepDots(totalSteps: 9, currentStep: 2)
            OnboardingStepDots(totalSteps: 9, currentStep: 5)
            OnboardingStepDots(totalSteps: 9, currentStep: 8)
        }
    }
    .preferredColorScheme(.dark)
}
