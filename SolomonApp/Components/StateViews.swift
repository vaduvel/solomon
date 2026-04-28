import SwiftUI

// MARK: - State Views (Apple HIG aligned)
//
// Reutilizabile pentru toate ecranele Solomon: empty / loading / error.
// Pattern: icon mare + title + subtitle + optional CTA, centered vertical.

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
        VStack(spacing: SolSpacing.base) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.tertiary)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: SolSpacing.sm) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.solForeground)
                    .multilineTextAlignment(.center)

                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let cta {
                SolomonButton(cta.title, style: .secondary, icon: cta.icon, action: cta.action)
                    .padding(.top, SolSpacing.sm)
                    .padding(.horizontal, SolSpacing.xxl)
            }
        }
        .padding(SolSpacing.xl)
        .frame(maxWidth: .infinity)
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
        VStack(spacing: SolSpacing.base) {
            ProgressView()
                .progressViewStyle(.circular)
                .controlSize(.large)
                .tint(Color.solPrimary)

            if let title {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.solForeground)
            }
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(SolSpacing.xl)
        .frame(maxWidth: .infinity)
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
        VStack(spacing: SolSpacing.base) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Color.solWarning)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: SolSpacing.sm) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.solForeground)
                    .multilineTextAlignment(.center)

                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let retryAction {
                SolomonButton("Reîncearcă", style: .secondary, icon: "arrow.clockwise", action: retryAction)
                    .padding(.top, SolSpacing.sm)
                    .padding(.horizontal, SolSpacing.xxl)
            }
        }
        .padding(SolSpacing.xl)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - InlineErrorText (sub câmp input)

public struct InlineErrorText: View {
    public let message: String

    public init(_ message: String) {
        self.message = message
    }

    public var body: some View {
        HStack(spacing: SolSpacing.xs) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.footnote)
                .foregroundStyle(Color.solDestructive)
            Text(message)
                .font(.footnote)
                .foregroundStyle(Color.solDestructive)
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.solCanvas.ignoresSafeArea()
        ScrollView {
            VStack(spacing: SolSpacing.xxxl) {
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
                    .padding(.horizontal, SolSpacing.base)
            }
            .padding(.vertical)
        }
    }
    .preferredColorScheme(.dark)
}
