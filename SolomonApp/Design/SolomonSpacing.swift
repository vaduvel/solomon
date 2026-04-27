import SwiftUI

// MARK: - Solomon Design System v1.0 — Spacing & Radius
//
// Sursa adevărului: Penny DS v1.0 — bază 4.

public enum SolSpacing {
    // Bază 4
    public static let xs:   CGFloat = 4    // p-1
    public static let sm:   CGFloat = 8    // p-2 / gap-2
    public static let md:   CGFloat = 12   // p-3 / gap-3
    public static let base: CGFloat = 16   // p-4 / gap-4
    public static let lg:   CGFloat = 20   // px-5 (page padding)
    public static let xl:   CGFloat = 24   // p-6
    public static let xxl:  CGFloat = 32
    public static let xxxl: CGFloat = 40
    public static let h:    CGFloat = 48
    public static let hh:   CGFloat = 64

    // MARK: - Screen insets

    /// Page padding — 20px (px-5 din DS)
    public static let screenHorizontal: CGFloat = 20

    /// Section gap — 12px (space-y-3 din DS)
    public static let sectionGap: CGFloat = 12

    /// Card padding hero — 24px (p-6)
    public static let cardHero: CGFloat = 24

    /// Card padding standard — 20px (p-5)
    public static let cardStandard: CGFloat = 20

    /// Card padding small — 16px (p-4)
    public static let cardSmall: CGFloat = 16

    /// Bottom nav height — 72px
    public static let bottomNavHeight: CGFloat = 72

    /// List row height — 72px
    public static let listRowHeight: CGFloat = 72
}

public enum SolRadius {
    /// --radius-sm: 8px (chips, badges)
    public static let sm:   CGFloat = 8
    /// --radius-md: 10px
    public static let md:   CGFloat = 10
    /// --radius-lg: 12px
    public static let lg:   CGFloat = 12
    /// --radius-xl: 16px (standard cards)
    public static let xl:   CGFloat = 16
    /// custom-2xl: 24px (hero cards, sheets, CTA buttons)
    public static let xxl:  CGFloat = 24
    /// custom-full: 9999px (pill chips, avatars)
    public static let pill: CGFloat = 9999
}

// MARK: - View convenience

public extension View {

    /// Padding standard pentru conținut de ecran (orizontal)
    func solScreenPadding() -> some View {
        self.padding(.horizontal, SolSpacing.screenHorizontal)
    }

    /// Standard card: bg #1C2230 + radius xl + border subtle
    func solCard() -> some View {
        self
            .background(Color.solCard)
            .clipShape(RoundedRectangle(cornerRadius: SolRadius.xl, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SolRadius.xl, style: .continuous)
                    .stroke(Color.solBorder, lineWidth: 1)
            )
    }

    /// Glassmorphism hero card — rgba(28,34,48,0.5) + blur(40px) + border
    /// Folosit pentru numerele eroice (Safe to Spend, Payday)
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

    /// AI insight card — bg solCard + border accent neon green subtle
    func solAIInsightCard() -> some View {
        self
            .background(Color.solCard)
            .clipShape(RoundedRectangle(cornerRadius: SolRadius.xl, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SolRadius.xl, style: .continuous)
                    .stroke(Color.solBorderAccent, lineWidth: 1)
            )
    }

    /// Elevated card — alias pentru solCard în context modal/popover
    func solElevatedCard() -> some View {
        self
            .background(Color.solCard)
            .clipShape(RoundedRectangle(cornerRadius: SolRadius.xxl, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SolRadius.xxl, style: .continuous)
                    .stroke(Color.solBorder, lineWidth: 1)
            )
    }

    /// Neon glow shadow primary (CTA buttons, active states)
    func solNeonGlow(color: Color = .solPrimary, radius: CGFloat = 20, opacity: Double = 0.35) -> some View {
        self.shadow(color: color.opacity(opacity), radius: radius, x: 0, y: 4)
    }
}
