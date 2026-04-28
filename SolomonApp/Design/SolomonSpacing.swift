import SwiftUI

// MARK: - Solomon Design System v3.0 — Spacing & Radius (Apple iOS 26 native)
//
// Folosim 8pt grid Apple HIG. Card backgrounds = .regularMaterial / .thinMaterial
// pentru Liquid Glass effect (iOS 26+).

public enum SolSpacing {
    public static let xs:   CGFloat = 4
    public static let sm:   CGFloat = 8
    public static let md:   CGFloat = 12
    public static let base: CGFloat = 16
    public static let lg:   CGFloat = 20
    public static let xl:   CGFloat = 24
    public static let xxl:  CGFloat = 32
    public static let xxxl: CGFloat = 40
    public static let h:    CGFloat = 48
    public static let hh:   CGFloat = 64

    /// Standard horizontal margin (16pt — HIG iOS standard)
    public static let screenHorizontal: CGFloat = 16
    public static let screenHorizontalWide: CGFloat = 20

    public static let sectionGap: CGFloat = 24
    public static let sectionGapLarge: CGFloat = 32

    public static let cardSmall: CGFloat = 16
    public static let cardStandard: CGFloat = 20
    public static let cardHero: CGFloat = 24

    /// Tap target HIG minim
    public static let tapTargetMin: CGFloat = 44
    public static let bottomNavHeight: CGFloat = 50
    public static let listRowHeight: CGFloat = 44
}

public enum SolRadius {
    /// 8pt — chips, badges
    public static let sm:   CGFloat = 8
    /// 10pt
    public static let md:   CGFloat = 10
    /// 12pt — buttons standard
    public static let lg:   CGFloat = 12
    /// 16pt — cards standard
    public static let xl:   CGFloat = 16
    /// 28pt — sheets, hero cards (iOS 26 sheet radius)
    public static let xxl:  CGFloat = 28
    /// Capsule (pill)
    public static let pill: CGFloat = 9999
}

// MARK: - View convenience

public extension View {

    func solScreenPadding() -> some View {
        self.padding(.horizontal, SolSpacing.screenHorizontal)
    }

    /// Card cu background nativ Apple iOS 26 (Liquid Glass)
    /// Folosește .regularMaterial care adaptează la light/dark automat.
    func solCard() -> some View {
        self
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: SolRadius.xl, style: .continuous))
    }

    /// Glassmorphism hero card cu .ultraThinMaterial (iOS 26 Liquid Glass)
    /// Folosit pentru hero numbers (Safe-to-Spend, Payday).
    func solGlassCard() -> some View {
        self
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: SolRadius.xxl, style: .continuous))
    }

    /// AI insight card — .regularMaterial + border accent mint subtil
    func solAIInsightCard() -> some View {
        self
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: SolRadius.xl, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SolRadius.xl, style: .continuous)
                    .strokeBorder(Color.mint.opacity(0.25), lineWidth: 1)
            )
    }

    /// Elevated card (sheets, modals) — .thickMaterial
    func solElevatedCard() -> some View {
        self
            .background(.thickMaterial, in: RoundedRectangle(cornerRadius: SolRadius.xxl, style: .continuous))
    }

    /// Subtle shadow pentru floating elements (NU glow agresiv)
    func solSubtleShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 2)
    }

    /// Asigură tap target ≥ 44pt
    func solTapTarget() -> some View {
        self.frame(minWidth: SolSpacing.tapTargetMin, minHeight: SolSpacing.tapTargetMin)
    }

    /// Glow neon — DEPRECAT, nu mai folosim peste tot
    /// Păstrat doar pentru compatibilitate, dar e no-op subtil acum
    func solNeonGlow(color: Color = .mint, radius: CGFloat = 8, opacity: Double = 0.15) -> some View {
        self.shadow(color: color.opacity(opacity), radius: radius, x: 0, y: 2)
    }
}
