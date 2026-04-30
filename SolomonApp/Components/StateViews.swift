import SwiftUI

// MARK: - State Views (Claude Design v3 — premium glass)
//
// Empty / Loading / Error state views — glass card cu icon mare în container
// colorat (38×38 rounded sq + border) + titlu + subtitle muted + opțional CTA.
//
// API public PĂSTRAT (EmptyStateView/CTA, LoadingStateView, ErrorStateView,
// InlineErrorText) — call site-urile existente continuă să compileze.

// MARK: - EmptyStateView

public struct EmptyStateView: View {
    public let icon: String
    public let title: String
    public let subtitle: String?
    public let cta: CTA?

    public struct CTA {
        public let title: String
        public let icon: String?
        public let action: () -> Void

        public init(title: String, icon: String? = nil, action: @escaping () -> Void) {
            self.title = title
            self.icon = icon
            self.action = action
        }
    }

    public init(icon: String, title: String, subtitle: String? = nil, cta: CTA? = nil) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.cta = cta
    }

    public var body: some View {
        SolStateCard(
            icon: icon,
            title: title,
            subtitle: subtitle,
            accent: .mint,
            cta: cta
        )
    }
}

// MARK: - LoadingStateView

public struct LoadingStateView: View {
    public let title: String?
    public let subtitle: String?

    public init(title: String? = nil, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    public var body: some View {
        VStack(spacing: 16) {
            // Icon container mint cu ProgressView mare
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(SolAccent.mint.iconGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .stroke(Color.solMintExact.opacity(0.4), lineWidth: 1)
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: Color.solMintExact.opacity(0.25), radius: 12)

                ProgressView()
                    .progressViewStyle(.circular)
                    .controlSize(.large)
                    .tint(.solMintExact)
            }
            .padding(.bottom, 4)

            VStack(spacing: 6) {
                if let title {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .multilineTextAlignment(.center)
                }
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.white.opacity(0.55))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.04), Color.white.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .background(.ultraThinMaterial.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }
}

// MARK: - ErrorStateView

public struct ErrorStateView: View {
    public let title: String
    public let subtitle: String?
    public let retryAction: (() -> Void)?

    public init(
        title: String = "Ceva n-a mers",
        subtitle: String? = nil,
        retryAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.retryAction = retryAction
    }

    public var body: some View {
        let cta: EmptyStateView.CTA? = retryAction.map { action in
            EmptyStateView.CTA(title: "Reîncearcă", icon: "arrow.clockwise", action: action)
        }
        SolStateCard(
            icon: "xmark.octagon.fill",
            title: title,
            subtitle: subtitle,
            accent: .rose,
            cta: cta
        )
    }
}

// MARK: - InlineErrorText (sub câmp input)

public struct InlineErrorText: View {
    public let message: String

    public init(_ message: String) {
        self.message = message
    }

    public var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.solRoseExact)
            Text(message)
                .font(.system(size: 12))
                .foregroundStyle(Color.solRoseExact)
            Spacer()
        }
    }
}

// MARK: - SolStateCard (shared glass card)

/// Internal — împărțit între EmptyStateView și ErrorStateView.
fileprivate struct SolStateCard: View {
    let icon: String
    let title: String
    let subtitle: String?
    let accent: SolAccent
    let cta: EmptyStateView.CTA?

    var body: some View {
        VStack(spacing: 16) {
            // Icon container 38×38 colorat cu border accent
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(accent.iconGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .stroke(accent.color.opacity(0.4), lineWidth: 1)
                    )
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(accent.color)
            }
            .frame(width: 38, height: 38)
            .shadow(color: accent.color.opacity(0.2), radius: 12)

            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .multilineTextAlignment(.center)

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.white.opacity(0.55))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(2)
                }
            }

            if let cta {
                SolPrimaryButton(cta.title, accent: accent, fullWidth: true) {
                    cta.action()
                }
                .padding(.top, 4)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.04), Color.white.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .background(.ultraThinMaterial.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.solCanvasDark.ignoresSafeArea()
        ScrollView {
            VStack(spacing: 24) {
                EmptyStateView(
                    icon: "tray",
                    title: "Nicio tranzacție",
                    subtitle: "Conectează banca via Shortcuts sau adaugă manual.",
                    cta: .init(title: "Adaugă tranzacție", icon: "plus", action: {})
                )

                LoadingStateView(title: "Se încarcă...", subtitle: "Solomon analizează ultimele 30 zile")

                ErrorStateView(
                    title: "Conexiune lipsă",
                    subtitle: "Solomon are nevoie de internet pentru a descărca modelul.",
                    retryAction: {}
                )

                InlineErrorText("Numele e obligatoriu")
                    .padding(.horizontal, 16)
            }
            .padding(.vertical, 24)
        }
    }
    .preferredColorScheme(.dark)
}
