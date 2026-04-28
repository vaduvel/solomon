import SwiftUI

// MARK: - Solomon Design System v2.0 — Spacing & Radius (Apple HIG aligned)
//
// 8pt grid strict. Radius HIG-native (8/12/16/28).

public enum SolSpacing {
    // 8pt grid baseline
    public static let xs:   CGFloat = 4
    public static let sm:   CGFloat = 8     // gap-1 / row spacing
    public static let md:   CGFloat = 12    // sub-section
    public static let base: CGFloat = 16    // standard margins
    public static let lg:   CGFloat = 20    // page padding (large screens)
    public static let xl:   CGFloat = 24    // section gap small
    public static let xxl:  CGFloat = 32    // section gap large
    public static let xxxl: CGFloat = 40
    public static let h:    CGFloat = 48
    public static let hh:   CGFloat = 64

    // MARK: - HIG layout standards

    /// Standard horizontal margin (16pt) — default pentru content
    public static let screenHorizontal: CGFloat = 16

    /// Wider page padding (20pt) — for hero / spacious screens
    public static let screenHorizontalWide: CGFloat = 20

    /// Section gap (24pt) — între grupuri logice de conținut
    public static let sectionGap: CGFloat = 24

    /// Section gap mare (32pt) — pentru breathing room
    public static let sectionGapLarge: CGFloat = 32

    /// Card padding standard (16pt)
    public static let cardSmall: CGFloat = 16
    public static let cardStandard: CGFloat = 20
    public static let cardHero: CGFloat = 24

    /// Tap target minimum HIG (44×44pt)
    public static let tapTargetMin: CGFloat = 44

    /// Bottom nav height
    public static let bottomNavHeight: CGFloat = 50  // tab bar standard

    /// List row standard height
    public static let listRowHeight: CGFloat = 44
}

public enum SolRadius {
    /// Mic — chips, badges (8pt)
    public static let sm:   CGFloat = 8
    /// Medium — buttons standard (12pt)
    public static let md:   CGFloat = 10
    /// Standard buttons & cards small (12pt)
    public static let lg:   CGFloat = 12
    /// Cards standard (16pt)
    public static let xl:   CGFloat = 16
    /// Hero cards / sheets / large CTAs (28pt — HIG sheet-like)
    public static let xxl:  CGFloat = 28
    /// Pill (capsule) — circular elements
    public static let pill: CGFloat = 9999
}

// MARK: - View convenience

public extension View {

    /// Padding orizontal standard (16pt)
    func solScreenPadding() -> some View {
        self.padding(.horizontal, SolSpacing.screenHorizontal)
    }

    /// Standard card: bg solCard + radius xl + border
    func solCard() -> some View {
        self
            .background(Color.solCard)
            .clipShape(RoundedRectangle(cornerRadius: SolRadius.xl, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SolRadius.xl, style: .continuous)
                    .stroke(Color.solBorder, lineWidth: 1)
            )
    }

    /// Glassmorphism card (hero numbers — Safe-to-Spend, Payday)
    func solGlassCard() -> some View {
        self
            .background(.ultraThinMaterial)
            .background(Color.solCard.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: SolRadius.xxl, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SolRadius.xxl, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }

    /// AI insight card — neon green border subtil
    func solAIInsightCard() -> some View {
        self
            .background(Color.solCard)
            .clipShape(RoundedRectangle(cornerRadius: SolRadius.xl, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SolRadius.xl, style: .continuous)
                    .stroke(Color.solBorderAccent, lineWidth: 1)
            )
    }

    /// Elevated card (modal, popover, sheet content)
    func solElevatedCard() -> some View {
        self
            .background(Color.solCard)
            .clipShape(RoundedRectangle(cornerRadius: SolRadius.xxl, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SolRadius.xxl, style: .continuous)
                    .stroke(Color.solBorder, lineWidth: 1)
            )
    }

    /// Neon glow shadow (CTA prominent, focus state)
    func solNeonGlow(color: Color = .solPrimary, radius: CGFloat = 20, opacity: Double = 0.35) -> some View {
        self.shadow(color: color.opacity(opacity), radius: radius, x: 0, y: 4)
    }

    /// Asigură tap target ≥ 44pt
    func solTapTarget() -> some View {
        self.frame(minWidth: SolSpacing.tapTargetMin, minHeight: SolSpacing.tapTargetMin)
    }
}
