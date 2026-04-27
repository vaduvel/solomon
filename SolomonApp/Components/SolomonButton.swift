import SwiftUI

// MARK: - SolomonButton (DS v1.0)
//
// CTA pill button conform Penny DS v1.0:
//   - PRIMARY: linear-gradient(135°, #00FF87, #00D4FF) + glow neon
//     bg gradient, color #0A0E1A (text negru pe verde-cyan)
//     shadow: 0 4px 20px rgba(0,255,135,0.35)
//     h-14 (56px), rounded-2xl
//   - OUTLINE/SECONDARY: border 1.5px solPrimary, transparent bg
//   - DANGER: solDestructive fill
//   - GHOST: transparent, text solPrimary

public struct SolomonButton: View {

    public enum Style {
        case primary    // gradient fill + glow (DS v1.0)
        case secondary  // outline primary
        case danger     // destructive fill
        case ghost      // transparent, text primary
    }

    public let title: String
    public let style: Style
    public let isLoading: Bool
    public let icon: String?
    public let action: () -> Void

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
        Button(action: action) {
            HStack(spacing: SolSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.8)
                        .tint(foregroundColor)
                }
                if let icon, !isLoading {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(foregroundColor)
                }
                Text(title)
                    .font(.solBodyBold)
                    .foregroundStyle(foregroundColor)
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            .padding(.horizontal, SolSpacing.xl)
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: SolRadius.xxl, style: .continuous))
            .modifier(GlowModifier(style: style, isEnabled: !isLoading))
        }
        .disabled(isLoading)
        .buttonStyle(ScaleOnPressButtonStyle())
    }

    // MARK: - Styling helpers

    private var foregroundColor: Color {
        switch style {
        case .primary:   return Color.solCanvas         // text dark on bright gradient
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
            RoundedRectangle(cornerRadius: SolRadius.xxl, style: .continuous)
                .stroke(Color.solPrimary, lineWidth: 1.5)
                .background(Color.clear)
        case .danger:
            Color.solDestructive
        case .ghost:
            Color.clear
        }
    }
}

// MARK: - GlowModifier (neon green shadow)

private struct GlowModifier: ViewModifier {
    let style: SolomonButton.Style
    let isEnabled: Bool

    func body(content: Content) -> some View {
        switch style {
        case .primary where isEnabled:
            content.shadow(color: Color.solPrimary.opacity(0.35), radius: 20, x: 0, y: 4)
        case .danger where isEnabled:
            content.shadow(color: Color.solDestructive.opacity(0.30), radius: 16, x: 0, y: 4)
        default:
            content
        }
    }
}

// MARK: - Press scale

private struct ScaleOnPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.85), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.solCanvas.ignoresSafeArea()
        VStack(spacing: SolSpacing.base) {
            SolomonButton("Continue") {}
            SolomonButton("I'll be careful", style: .secondary) {}
            SolomonButton("Loading...", isLoading: true) {}
            SolomonButton("Cancel subscription", style: .danger) {}
            SolomonButton("Later", style: .ghost) {}
            SolomonButton("With icon", icon: "arrow.right") {}
        }
        .padding(SolSpacing.lg)
    }
    .preferredColorScheme(.dark)
}
