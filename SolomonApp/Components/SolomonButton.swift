import SwiftUI

// MARK: - SolomonButton (DS v2.0 — Apple HIG aligned)
//
// Refactor Faza 27: aliniat la Apple Human Interface Guidelines.
// Folosim sub-the-hood `Button` cu modifiers HIG pentru:
//   - Tap target garantat ≥ 44pt
//   - Haptic feedback automat
//   - Stiluri standardizate (filled prominent / bordered / plain / danger)
//   - Disabled state cu opacity HIG-recomandată
//
// Păstrăm gradient mint→cyan ca brand signature pe primary, dar cu corner
// radius mai sobru (12pt în loc de 28pt) pentru aspect nativ.

public struct SolomonButton: View {

    public enum Style {
        /// Primary CTA — gradient mint→cyan + neon glow (signature Solomon)
        case primary
        /// Secondary — bordură primary + transparent bg
        case secondary
        /// Destructive — solid red
        case danger
        /// Plain — text only, no bg
        case ghost
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
            HStack(spacing: SolSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.85)
                        .tint(foregroundColor)
                }
                if let icon, !isLoading {
                    Image(systemName: icon)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(foregroundColor)
                }
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(foregroundColor)
            }
            .frame(maxWidth: .infinity, minHeight: 50)  // ≥ HIG tap target 44pt + breath
            .padding(.horizontal, SolSpacing.base)
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: SolRadius.lg, style: .continuous))  // 12pt — HIG button
            .overlay(borderOverlay)
            .modifier(GlowModifier(style: style, isEnabled: !isLoading))
        }
        .disabled(isLoading)
        .buttonStyle(ScaleOnPressButtonStyle())
        .sensoryFeedback(.impact(weight: .medium), trigger: triggerHaptic)
    }

    // MARK: - Styling

    private var foregroundColor: Color {
        switch style {
        case .primary:   return Color.solCanvas        // text dark on bright gradient
        case .secondary: return Color.solPrimary
        case .danger:    return Color.white
        case .ghost:     return Color.solPrimary
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            LinearGradient.solPrimaryCTA
        case .secondary:
            Color.clear
        case .danger:
            Color.solDestructive
        case .ghost:
            Color.clear
        }
    }

    @ViewBuilder
    private var borderOverlay: some View {
        if style == .secondary {
            RoundedRectangle(cornerRadius: SolRadius.lg, style: .continuous)
                .stroke(Color.solPrimary, lineWidth: 1.5)
        }
    }
}

// MARK: - GlowModifier

private struct GlowModifier: ViewModifier {
    let style: SolomonButton.Style
    let isEnabled: Bool

    func body(content: Content) -> some View {
        switch style {
        case .primary where isEnabled:
            content.shadow(color: Color.solPrimary.opacity(0.30), radius: 14, x: 0, y: 4)
        case .danger where isEnabled:
            content.shadow(color: Color.solDestructive.opacity(0.25), radius: 12, x: 0, y: 4)
        default:
            content
        }
    }
}

// MARK: - Press scale (subtle, HIG)

private struct ScaleOnPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.solCanvas.ignoresSafeArea()
        VStack(spacing: SolSpacing.md) {
            SolomonButton("Continuă", icon: "arrow.right") {}
            SolomonButton("Anulează abonamentul", style: .secondary, icon: "xmark") {}
            SolomonButton("Loading...", isLoading: true) {}
            SolomonButton("Șterge", style: .danger, icon: "trash") {}
            SolomonButton("Mai târziu", style: .ghost) {}
        }
        .padding(SolSpacing.base)
    }
    .preferredColorScheme(.dark)
}
