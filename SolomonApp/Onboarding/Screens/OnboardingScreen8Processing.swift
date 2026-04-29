import SwiftUI

// MARK: - Ecran 8 — Procesare (Apple HIG aligned)
//
// Pattern HIG: animated icon + title + subtitle + animated progress steps.
// Folosim .symbolEffect(.pulse) iOS 17+ pentru animație nativ.

struct OnboardingScreen8Processing: View {
    @Environment(OnboardingState.self) var state

    var body: some View {
        VStack(spacing: 0) {

            Spacer()

            // Animated sparkle (HIG iOS 17+)
            Image(systemName: "sparkles")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(LinearGradient.solHero)
                .symbolEffect(.pulse, options: .repeating)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 96, height: 96)
                .background(
                    Circle()
                        .fill(Color.solPrimary.opacity(0.15))
                )
                .overlay(
                    Circle()
                        .stroke(Color.solPrimary.opacity(0.4), lineWidth: 2)
                )

            VStack(spacing: SolSpacing.xs) {
                Text("Solomon analizează...")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.solForeground)
                Text("Mă uit la ultimele 6 luni de date.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, SolSpacing.lg)

            Spacer()

            // Tasks list
            VStack(spacing: SolSpacing.sm) {
                ForEach(state.processingTasks) { task in
                    ProcessingTaskRow(title: task.title, state: task.state)
                }
            }
            .padding(.horizontal, SolSpacing.lg)

            Spacer()
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: SolSpacing.sm) {
                if state.canProceedFromCurrentStep {
                    SolomonButton("Vezi primul raport", icon: "arrow.right") {
                        Haptics.medium()
                        state.next()
                    }
                    .transition(.opacity.combined(with: .scale))
                } else {
                    Text("Te rugăm să aștepți...")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
            }
            .padding(.horizontal, SolSpacing.lg)
            .padding(.vertical, SolSpacing.base)
            .background(.ultraThinMaterial)
            .animation(.smooth, value: state.canProceedFromCurrentStep)
        }
        .task {
            await state.runSimulatedProcessing()
            Haptics.success()
        }
    }
}

#Preview {
    ZStack {
        Color.solCanvas.ignoresSafeArea()
        OnboardingScreen8Processing()
            .environment(OnboardingState())
    }
    .preferredColorScheme(.dark)
}
