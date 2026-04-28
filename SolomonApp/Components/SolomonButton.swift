import SwiftUI

// MARK: - SolomonButton (Apple HIG strict — Faza 28)
//
// Refactor: folosim DIRECT iOS native button styles via `.buttonStyle()`,
// fără custom views. Brandul Solomon vine prin `.tint(.solPrimary)` și
// gradient e folosit DOAR ca opțiune explicită pentru hero CTAs.

public struct SolomonButton: View {

    public enum Style {
        /// Native `.borderedProminent` cu solPrimary tint — DEFAULT pentru CTA
        case primary
        /// Native `.bordered` cu solPrimary tint
        case secondary
        /// Native `.borderedProminent` cu .red tint — destructive actions
        case danger
        /// Native `.plain` (text only)
        case ghost
        /// Hero gradient mint→cyan — DOAR pentru CTA-uri hero (Welcome, CanIAfford big card)
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
        }
        .modifier(StyleModifier(style: style))
        .controlSize(.large)
        .disabled(isLoading)
        .sensoryFeedback(.impact(weight: .medium), trigger: triggerHaptic)
    }

    @ViewBuilder
    private var label: some View {
        HStack(spacing: SolSpacing.sm) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .controlSize(.small)
            }
            if let icon, !isLoading {
                Image(systemName: icon)
                    .font(.body.weight(.semibold))
            }
            Text(title)
                .font(.body.weight(.semibold))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Style modifier

private struct StyleModifier: ViewModifier {
    let style: SolomonButton.Style

    func body(content: Content) -> some View {
        switch style {
        case .primary:
            content
                .buttonStyle(.borderedProminent)
                .tint(Color.solPrimary)
                .foregroundStyle(Color.solCanvas)

        case .secondary:
            content
                .buttonStyle(.bordered)
                .tint(Color.solPrimary)

        case .danger:
            content
                .buttonStyle(.borderedProminent)
                .tint(Color.solDestructive)
                .foregroundStyle(.white)

        case .ghost:
            content
                .buttonStyle(.plain)
                .foregroundStyle(Color.solPrimary)

        case .heroGradient:
            content
                .buttonStyle(HeroGradientButtonStyle())
        }
    }
}

// MARK: - Hero gradient style (DOAR pentru hero CTAs)

private struct HeroGradientButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, SolSpacing.lg)
            .frame(maxWidth: .infinity, minHeight: 50)
            .foregroundStyle(Color.solCanvas)
            .background(LinearGradient.solPrimaryCTA)
            .clipShape(RoundedRectangle(cornerRadius: SolRadius.lg, style: .continuous))
            .shadow(color: Color.solPrimary.opacity(configuration.isPressed ? 0.20 : 0.30),
                    radius: 12, x: 0, y: 4)
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
            SolomonButton("Hero CTA", style: .heroGradient, icon: "sparkles") {}
        }
        .padding(SolSpacing.base)
    }
    .preferredColorScheme(.dark)
}
