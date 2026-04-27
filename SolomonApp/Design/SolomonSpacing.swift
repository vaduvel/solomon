import SwiftUI

// MARK: - Solomon Design System — Spacing & Radius
//
// Baza 4. Toate layout-urile Solomon respectă această scară.

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

    // MARK: - Screen insets

    /// Padding orizontal standard pentru conținut de ecran
    public static let screenHorizontal: CGFloat = 20

    /// Padding vertical între secțiuni
    public static let sectionGap: CGFloat = 32
}

public enum SolRadius {
    /// Chips, badges — 8
    public static let sm:   CGFloat = 8
    /// Cards — 16
    public static let md:   CGFloat = 16
    /// Bottom sheets, modal cards — 24
    public static let lg:   CGFloat = 24
    /// CTA pill buttons — 999
    public static let pill: CGFloat = 999
}

// MARK: - View convenience

public extension View {

    /// Padding standard pentru conținut de ecran (orizontal + top)
    func solScreenPadding() -> some View {
        self.padding(.horizontal, SolSpacing.screenHorizontal)
    }

    /// Card styling: background surface + corner radius + border subtil
    func solCard() -> some View {
        self
            .background(Color.solSurface)
            .clipShape(RoundedRectangle(cornerRadius: SolRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SolRadius.md, style: .continuous)
                    .stroke(Color.solBorder, lineWidth: 1)
            )
    }

    /// Elevated card (modals, popovers)
    func solElevatedCard() -> some View {
        self
            .background(Color.solElevated)
            .clipShape(RoundedRectangle(cornerRadius: SolRadius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SolRadius.lg, style: .continuous)
                    .stroke(Color.solBorder, lineWidth: 1)
            )
    }
}
