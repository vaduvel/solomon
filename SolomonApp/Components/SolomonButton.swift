import SwiftUI

// MARK: - SolomonButton
//
// CTA pill button — accent mint sau secundar.

public struct SolomonButton: View {

    public enum Style {
        case primary    // mint fill
        case secondary  // outline mint
        case danger     // roșu
        case ghost      // transparent, text mint
    }

    public let title: String
    public let style: Style
    public let isLoading: Bool
    public let action: () -> Void

    public init(
        _ title: String,
        style: Style = .primary,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.isLoading = isLoading
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: SolSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.8)
                        .tint(foregroundColor)
                }
                Text(title)
                    .font(.solHeadingSM)
                    .foregroundStyle(foregroundColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, SolSpacing.base)
            .padding(.horizontal, SolSpacing.xl)
            .background(backgroundView)
            .clipShape(Capsule())
        }
        .disabled(isLoading)
        .buttonStyle(.plain)
    }

    // MARK: - Styling helpers

    private var foregroundColor: Color {
        switch style {
        case .primary:   return Color.solCanvas
        case .secondary: return Color.solMint
        case .danger:    return Color.white
        case .ghost:     return Color.solMint
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            Color.solMint
        case .secondary:
            Capsule()
                .stroke(Color.solMint, lineWidth: 1.5)
                .background(Color.clear)
        case .danger:
            Color.solDanger
        case .ghost:
            Color.clear
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.solCanvas.ignoresSafeArea()
        VStack(spacing: SolSpacing.base) {
            SolomonButton("Hai să ne cunoaștem →") {}
            SolomonButton("Conectează Gmail", style: .secondary) {}
            SolomonButton("Se generează...", isLoading: true) {}
            SolomonButton("Anulează abonamentul", style: .danger) {}
            SolomonButton("Mai târziu", style: .ghost) {}
        }
        .padding()
    }
}
