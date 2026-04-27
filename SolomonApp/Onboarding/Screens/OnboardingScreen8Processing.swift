import SwiftUI

// MARK: - Ecran 8 — Procesare (1-3 minute)
//
// Conform spec §11 ecran 8:
//   - Animație: "Mă uit la ultimele 6 luni..."
//   - Progress bar cu sub-tasks vizibile:
//     • Citesc emailurile financiare...
//     • Identific tranzacții și abonamente...
//     • Caut pattern-uri...
//     • Pregătesc primul raport...

struct OnboardingScreen8Processing: View {
    @EnvironmentObject var state: OnboardingState

    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: SolSpacing.lg) {
            Spacer().frame(height: SolSpacing.xl)

            // Hero animated icon (sparkle pulsing)
            ZStack {
                Circle()
                    .fill(LinearGradient.solHero)
                    .frame(width: 88, height: 88)
                    .blur(radius: 20)
                    .opacity(0.6)
                    .scaleEffect(pulseScale)

                ZStack {
                    Circle()
                        .stroke(Color.solPrimary, lineWidth: 2)
                        .frame(width: 80, height: 80)
                    Image(systemName: "sparkles")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(Color.solPrimary)
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    pulseScale = 1.4
                }
            }

            VStack(spacing: SolSpacing.xs) {
                Text("Solomon analizează...")
                    .font(.solH2)
                    .foregroundStyle(Color.solForeground)
                Text("Mă uit la ultimele 6 luni de date.")
                    .font(.solBody)
                    .foregroundStyle(Color.solMuted)
            }
            .padding(.top, SolSpacing.md)

            Spacer().frame(height: SolSpacing.xl)

            // Sub-tasks list
            VStack(spacing: SolSpacing.sm) {
                ForEach(state.processingTasks) { task in
                    ProcessingTaskRow(title: task.title, state: task.state)
                }
            }

            Spacer()

            // CTA — apare doar când totul e done
            if state.canProceedFromCurrentStep {
                SolomonButton("Vezi primul raport", icon: "arrow.right") {
                    state.next()
                }
                .transition(.opacity.combined(with: .scale))
            } else {
                Text("Te rugăm să aștepți...")
                    .font(.solCaption)
                    .foregroundStyle(Color.solMuted)
            }
        }
        .padding(.horizontal, SolSpacing.screenHorizontal)
        .padding(.bottom, SolSpacing.xl)
        .task {
            await state.runSimulatedProcessing()
        }
    }
}

#Preview {
    ZStack {
        Color.solCanvas.ignoresSafeArea()
        OnboardingScreen8Processing()
            .environmentObject(OnboardingState())
    }
    .preferredColorScheme(.dark)
}
