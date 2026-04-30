import SwiftUI

// MARK: - Ecran 8 — Procesare (Solomon DS)
//
// Pattern din Solomon DS: eyebrow + titlu + subtitle + SolListCard cu rows numerotate
// (spinner mint pentru in-progress + checkmark mint pentru done) + SolLinearProgress global jos.
// Auto-next când toate task-urile sunt done.

struct OnboardingScreen8Processing: View {
    @Environment(OnboardingState.self) private var stateEnv

    var body: some View {
        @Bindable var state = stateEnv
        ZStack {
            MeshBackground()

            VStack(spacing: 0) {
                Spacer(minLength: SolSpacing.xl)

                // Eyebrow + titlu + subtitle
                VStack(spacing: SolSpacing.sm) {
                    Text("PASUL 8")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.solMintLight)
                        .tracking(1.4)
                        .textCase(.uppercase)

                    Text("Solomon învață despre tine")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .tracking(-0.5)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Configurez Safe to Spend, detectez tipare și pregătesc primul raport.")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.white.opacity(0.55))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, SolSpacing.lg)
                }
                .padding(.horizontal, SolSpacing.lg)

                Spacer(minLength: SolSpacing.xl)

                // Lista task-urilor (numerotate, glass rows)
                SolListCard {
                    ForEach(Array(state.processingTasks.enumerated()), id: \.element.id) { index, task in
                        ProcessingStepRow(
                            number: index + 1,
                            title: task.title,
                            state: task.state
                        )
                        if index < state.processingTasks.count - 1 {
                            SolHairlineDivider()
                        }
                    }
                }
                .padding(.horizontal, SolSpacing.lg)

                Spacer(minLength: SolSpacing.xl)

                // Linear progress global
                VStack(spacing: SolSpacing.xs) {
                    SolLinearProgress(progress: globalProgress, accent: .mint, glow: true)
                        .frame(height: 6)
                    HStack {
                        Text(progressLabel)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.45))
                            .tracking(0.4)
                            .textCase(.uppercase)
                        Spacer()
                        Text("\(Int(globalProgress * 100))%")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.solMintLight)
                            .monospacedDigit()
                    }
                }
                .padding(.horizontal, SolSpacing.lg)
                .padding(.bottom, SolSpacing.xl)
            }
        }
        .task {
            await state.runSimulatedProcessing()
            Haptics.success()
            // Auto-next după 0.6s pentru ca utilizatorul să vadă toate check-urile
            try? await Task.sleep(nanoseconds: 600_000_000)
            withAnimation(.smooth) {
                state.next()
            }
        }
    }

    private var globalProgress: CGFloat {
        let total = stateEnv.processingTasks.count
        guard total > 0 else { return 0 }
        let done = stateEnv.processingTasks.filter { $0.state == .done }.count
        let running = stateEnv.processingTasks.filter { $0.state == .running }.count
        return CGFloat(done) / CGFloat(total) + (running > 0 ? 0.5 / CGFloat(total) : 0)
    }

    private var progressLabel: String {
        if stateEnv.processingTasks.allSatisfy({ $0.state == .done }) {
            return "Solomon e gata"
        }
        return "Procesez..."
    }
}

// MARK: - ProcessingStepRow (numerotat, glass)

private struct ProcessingStepRow: View {
    let number: Int
    let title: String
    let state: ProcessingTaskRow.State

    var body: some View {
        HStack(spacing: 12) {
            // Bullet: număr / spinner / checkmark
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(bulletBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .stroke(bulletBorder, lineWidth: 1)
                    )

                bulletContent
            }
            .frame(width: 28, height: 28)

            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(textColor)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .animation(.easeOut(duration: 0.3), value: state)
    }

    @ViewBuilder
    private var bulletContent: some View {
        switch state {
        case .pending:
            Text("\(number)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.4))
                .monospacedDigit()
        case .running:
            ProgressView()
                .progressViewStyle(.circular)
                .tint(Color.solMintExact)
                .scaleEffect(0.7)
        case .done:
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.solMintExact)
        }
    }

    private var bulletBackground: Color {
        switch state {
        case .pending: return Color.white.opacity(0.04)
        case .running: return Color.solMintExact.opacity(0.10)
        case .done:    return Color.solMintExact.opacity(0.12)
        }
    }

    private var bulletBorder: Color {
        switch state {
        case .pending: return Color.white.opacity(0.08)
        case .running: return Color.solMintExact.opacity(0.30)
        case .done:    return Color.solMintExact.opacity(0.25)
        }
    }

    private var textColor: Color {
        switch state {
        case .pending: return Color.white.opacity(0.4)
        case .running: return Color.white
        case .done:    return Color.white.opacity(0.85)
        }
    }
}

#Preview {
    OnboardingScreen8Processing()
        .environment(OnboardingState())
        .preferredColorScheme(.dark)
}
