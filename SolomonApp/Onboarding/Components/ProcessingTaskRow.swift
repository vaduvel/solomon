import SwiftUI

// MARK: - ProcessingTaskRow
//
// Folosit în Ecran 8 onboarding (procesare 1-3 minute).
// State: pending → running (spinner) → done (check verde)

struct ProcessingTaskRow: View {

    enum State {
        case pending
        case running
        case done
    }

    let title: String
    let state: State

    var body: some View {
        HStack(spacing: SolSpacing.md) {
            statusIcon
                .frame(width: 28, height: 28)
            Text(title)
                .font(.solBody)
                .foregroundStyle(textColor)
            Spacer()
        }
        .padding(.vertical, SolSpacing.sm)
        .padding(.horizontal, SolSpacing.base)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.solCard.opacity(state == .pending ? 0.5 : 1.0))
        .clipShape(RoundedRectangle(cornerRadius: SolRadius.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: SolRadius.xl, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
        .animation(.easeOut(duration: 0.3), value: state)
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch state {
        case .pending:
            Circle()
                .stroke(Color.solBorder, lineWidth: 1.5)

        case .running:
            ProgressView()
                .progressViewStyle(.circular)
                .tint(Color.solPrimary)

        case .done:
            ZStack {
                Circle().fill(Color.solPrimary.opacity(0.15))
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.solPrimary)
            }
        }
    }

    private var textColor: Color {
        switch state {
        case .pending: return Color.solMuted
        case .running: return Color.solForeground
        case .done:    return Color.solForeground
        }
    }

    private var borderColor: Color {
        switch state {
        case .pending: return Color.solBorder
        case .running: return Color.solPrimary.opacity(0.3)
        case .done:    return Color.solPrimary.opacity(0.2)
        }
    }
}

#Preview {
    ZStack {
        Color.solCanvas.ignoresSafeArea()
        VStack(spacing: SolSpacing.sm) {
            ProcessingTaskRow(title: "Citesc emailurile financiare...", state: .done)
            ProcessingTaskRow(title: "Identific tranzacții și abonamente...", state: .running)
            ProcessingTaskRow(title: "Caut pattern-uri...", state: .pending)
            ProcessingTaskRow(title: "Pregătesc primul raport...", state: .pending)
        }
        .padding(SolSpacing.lg)
    }
    .preferredColorScheme(.dark)
}
