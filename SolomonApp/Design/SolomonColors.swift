import SwiftUI

// MARK: - Solomon Design System v1.0 — Culori
//
// Sursa adevărului: Penny DS v1.0 (mockup-urile + DS sheet trimise de Daniel).
// Filozofie: AMOLED black-blue, neon green primary, glassmorphism cards, motion neon.
// Toți tokens-ii din DS sheet sunt aici 1:1.

public extension Color {

    // MARK: - Background layers (DS v1.0)

    /// Canvas principal — #0A0E1A (deepest background, blue-black)
    static let solCanvas    = Color(hex: "#0A0E1A")
    /// Card / elevated surface — #1C2230
    static let solCard      = Color(hex: "#1C2230")
    /// Secondary background (input fields, list items) — #151923
    static let solSecondary = Color(hex: "#151923")

    /// Aliasuri legacy (păstrate pentru compatibilitate cu cod Faza 10–12)
    static let solSurface   = Color(hex: "#1C2230")
    static let solElevated  = Color(hex: "#1C2230")

    // MARK: - Text

    /// Foreground primary — #FFFFFF
    static let solForeground   = Color(hex: "#FFFFFF")
    /// Muted foreground — #8B92A8
    static let solMuted        = Color(hex: "#8B92A8")

    /// Aliasuri legacy
    static let solTextPrimary   = Color(hex: "#FFFFFF")
    static let solTextSecondary = Color(hex: "#8B92A8")
    static let solTextMuted     = Color(hex: "#8B92A8")
    static let solText          = Color(hex: "#FFFFFF")
    static let solTextTertiary  = Color(hex: "#8B92A8")

    // MARK: - Primary (neon green) + Cyan accent

    /// Primary — #00FF87 (CTA, success, key numbers, toggles ON)
    static let solPrimary     = Color(hex: "#00FF87")
    /// Cyan accent — #00D4FF (gradient pair, secondary highlights)
    static let solCyan        = Color(hex: "#00D4FF")

    /// Aliasuri legacy
    static let solMint        = Color(hex: "#00FF87")
    static let solMintHover   = Color(hex: "#5EEAA3")
    static let solMintDim     = Color(hex: "#2BA771")

    // MARK: - Semantic

    /// Warning amber — #FFB800
    static let solWarning   = Color(hex: "#FFB800")
    /// Destructive (danger, negative amounts, errors) — #FF3B6D
    static let solDestructive = Color(hex: "#FF3B6D")
    static let solDanger      = Color(hex: "#FF3B6D")
    /// Info blue — #60A5FA
    static let solInfo      = Color(hex: "#60A5FA")

    // MARK: - Border

    /// Border subtle — rgba(255,255,255,0.08)
    static let solBorder    = Color.white.opacity(0.08)
    /// Border accent (neon green subtle, AI insight cards) — rgba(0,255,135,0.12)
    static let solBorderAccent = Color(hex: "#00FF87").opacity(0.12)
}

// MARK: - Gradients (DS v1.0 signature)

public extension LinearGradient {

    /// Primary CTA gradient — green→cyan 135°
    static let solPrimaryCTA = LinearGradient(
        colors: [Color(hex: "#00FF87"), Color(hex: "#00D4FF")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Hero / Avatar gradient (same as CTA)
    static let solHero = LinearGradient(
        colors: [Color(hex: "#00FF87"), Color(hex: "#00D4FF")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Warning gradient — amber→pink-red 135°
    static let solWarningGradient = LinearGradient(
        colors: [Color(hex: "#FFB800"), Color(hex: "#FF3B6D")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
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
