import SwiftUI

// MARK: - SolomonButton (Claude Design v3 — pill capsule, gradient mint)
//
// API public PĂSTRAT — toate cele 5 stiluri (primary, secondary, danger, ghost,
// heroGradient) rămân disponibile cu aceeași semnătură. Vizualul intern e
// reconstruit cu pattern din SolPrimaryButton/SolSecondaryButton:
//   - .primary / .heroGradient → pill capsule, gradient mint→deep,
//     shadow .solMintExact.opacity(0.4) radius 12, border white .20 inset
//   - .secondary → glass pill, bg white .04, border white .10, fg white .70
//   - .danger → pill capsule rose gradient
//   - .ghost → text plain mint
//   - Loading state cu ProgressView tint .solMintExact

public struct SolomonButton: View {

    public enum Style {
        /// Primary CTA — pill capsule mint gradient
        case primary
        /// Secondary — glass pill subtle
        case secondary
        /// Destructive — pill capsule rose gradient
        case danger
        /// Plain text mint
        case ghost
        /// Hero gradient mint→deep — alias semantic pt CTA-uri hero (Welcome, CanIAfford big card)
        case heroGradient
    }

    public let title: String
    public let style: Style
    public let isLoading: Bool
    public let icon: String?
    public let action: () -> Void

    @State private var triggerHaptic: Int = 0

    public init(
        _ title: String,
        style: Style = .primary,
        isLoading: Bool = false,
        icon: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.isLoading = isLoading
        self.icon = icon
        self.action = action
    }

    public var body: some View {
        Button {
            triggerHaptic += 1
            action()
        } label: {
            label
                .frame(maxWidth: .infinity, minHeight: 50)
                .padding(.horizontal, 18)
                .background(backgroundView)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(borderView)
                .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: 4)
        }
        .buttonStyle(SolomonScaleButtonStyle())
        .disabled(isLoading)
        .sensoryFeedback(.impact(weight: .medium), trigger: triggerHaptic)
    }

    @ViewBuilder
    private var label: some View {
        HStack(spacing: 8) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .controlSize(.small)
                    .tint(.solMintExact)
            } else if let icon {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
            }
            Text(title)
                .font(.system(size: 15, weight: .semibold))
        }
        .foregroundStyle(foregroundColor)
        .opacity(isLoading ? 0.7 : 1.0)
    }

    // MARK: - Per-style background / border / shadow

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary, .heroGradient:
            SolAccent.mint.primaryButtonGradient
        case .secondary:
            Color.white.opacity(0.04)
                .background(.ultraThinMaterial.opacity(0.4))
        case .danger:
            SolAccent.rose.primaryButtonGradient
        case .ghost:
            Color.clear
        }
    }

    @ViewBuilder
    private var borderView: some View {
        switch style {
        case .primary, .heroGradient, .danger:
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.20), lineWidth: 1)
                .blendMode(.plusLighter)
        case .secondary:
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        case .ghost:
            EmptyView()
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary, .heroGradient:
            return Color(red: 0x05/255, green: 0x2E/255, blue: 0x16/255)
        case .secondary:
            return Color.white.opacity(0.7)
        case .danger:
            return Color.white
        case .ghost:
            return Color.solMintExact
        }
    }

    private var shadowColor: Color {
        switch style {
        case .primary, .heroGradient:
            return Color.solMintExact.opacity(0.4)
        case .danger:
            return Color.solRoseExact.opacity(0.4)
        case .secondary, .ghost:
            return .clear
        }
    }

    private var shadowRadius: CGFloat {
        switch style {
        case .primary, .heroGradient, .danger: return 12
        case .secondary, .ghost:               return 0
        }
    }
}

// MARK: - Press scale

private struct SolomonScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.solCanvasDark.ignoresSafeArea()
        VStack(spacing: 12) {
            SolomonButton("Continuă", icon: "arrow.right") {}
            SolomonButton("Anulează abonamentul", style: .secondary, icon: "xmark") {}
            SolomonButton("Loading...", isLoading: true) {}
            SolomonButton("Șterge", style: .danger, icon: "trash") {}
            SolomonButton("Mai târziu", style: .ghost) {}
            SolomonButton("Hero CTA", style: .heroGradient, icon: "sparkles") {}
        }
        .padding(16)
    }
    .preferredColorScheme(.dark)
}
