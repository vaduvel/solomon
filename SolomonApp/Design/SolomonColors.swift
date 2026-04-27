import SwiftUI

// MARK: - Solomon Design System — Culori
//
// Token-uri extrase din mockup-urile originale Penny → Solomon.
// Filozofie: AMOLED-first dark, un singur accent mint, niciun alt accent decorativ.
// Sursa adevărului: memory/project_design_system_v0.md

public extension Color {

    // MARK: - Background layers

    /// Canvas principal — #0A0B0E (near-black, OLED friendly)
    static let solCanvas    = Color(hex: "#0A0B0E")
    /// Suprafețe (cards, sheets) — #15161B
    static let solSurface   = Color(hex: "#15161B")
    /// Suprafețe ridicate (modal, popover) — #1E1F26
    static let solElevated  = Color(hex: "#1E1F26")

    // MARK: - Text

    /// Text primar — #F5F5F7
    static let solTextPrimary   = Color(hex: "#F5F5F7")
    /// Text secundar — #A1A1AA
    static let solTextSecondary = Color(hex: "#A1A1AA")
    /// Text attenuat — #6B6B7A
    static let solTextMuted     = Color(hex: "#6B6B7A")

    // MARK: - Convenience aliases

    /// Alias pentru solTextPrimary
    static let solText          = Color(hex: "#F5F5F7")
    /// Alias pentru solTextMuted
    static let solTextTertiary  = Color(hex: "#6B6B7A")

    // MARK: - Accent mint (brand)

    /// Accent principal — #3DDC97 (CTA, success, cifre cheie, toggles ON)
    static let solMint      = Color(hex: "#3DDC97")
    /// Hover/pressed mint — #5EEAA3
    static let solMintHover = Color(hex: "#5EEAA3")
    /// Mint atenuat (fundal badge) — #2BA771
    static let solMintDim   = Color(hex: "#2BA771")

    // MARK: - Semantice

    /// Erori, spiral, danger — #F87171
    static let solDanger    = Color(hex: "#F87171")
    /// Avertismente — #FBBF24
    static let solWarning   = Color(hex: "#FBBF24")
    /// Info — #60A5FA
    static let solInfo      = Color(hex: "#60A5FA")

    // MARK: - Border

    /// Bordură subtilă — rgba(255,255,255,0.06)
    static let solBorder    = Color.white.opacity(0.06)
}

// MARK: - Hex init helper

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
