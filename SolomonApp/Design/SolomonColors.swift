import SwiftUI

// MARK: - Solomon Design System v3.0 — Apple iOS 26 Native (Faza 28)
//
// Refactor MAJOR: nu mai folosim culori hardcoded custom. Folosim SEMANTIC
// COLORS Apple iOS 26 — acelasi tokens pe care le foloseste Apple Mail/
// Wallet/Music/Settings. Solomon arata IDENTIC cu apps Apple built-in.
//
// Aliasurile vechi (.solCanvas, .solCard, .solForeground etc.) raman ca
// alias-uri spre tokenii Apple pentru migrare graduala. Cod nou foloseste
// DIRECT primitives Apple (.primary, .secondary, Color(.systemBackground)).

public extension Color {

    // MARK: - Brand accent (singurul nostru token "custom" — e .mint Apple nativ)

    /// Brandul Solomon = .mint (Apple iOS 26 system color, ~#00C896)
    /// Pentru tint() pe butoane, controls, segments. NU pentru bg/text.
    static let solBrand = Color.mint

    // MARK: - Background layers (Apple iOS 26 semantic)

    /// Background general — adaptează la light/dark automat (negru AMOLED în dark)
    static let solCanvas = Color(.systemGroupedBackground)
    /// Card/elevated surface — adaptează automat
    static let solCard = Color(.secondarySystemGroupedBackground)
    /// Tertiary surface (modal, hover)
    static let solSecondary = Color(.tertiarySystemGroupedBackground)
    /// Surface non-grouped
    static let solSurface = Color(.secondarySystemBackground)
    /// Elevated surface
    static let solElevated = Color(.tertiarySystemBackground)

    // MARK: - Text (Apple semantic)

    /// Text primar — Color.primary (alb în dark, negru în light)
    static let solForeground = Color.primary
    /// Text secundar — Color.secondary (gri 60%)
    static let solMuted = Color.secondary
    /// Aliasuri legacy
    static let solTextPrimary = Color.primary
    static let solTextSecondary = Color.secondary
    static let solTextMuted = Color.secondary
    static let solText = Color.primary
    static let solTextTertiary = Color.secondary

    // MARK: - Brand semantic (mapat la Apple system colors iOS 26)

    /// Primary CTA / success — .mint (iOS 26 vibrant green)
    static let solPrimary = Color.mint
    /// Secondary accent — .cyan (iOS 26 cyan)
    static let solCyan = Color.cyan
    /// Aliasuri legacy
    static let solMint = Color.mint
    static let solMintHover = Color.mint
    static let solMintDim = Color.mint.opacity(0.6)

    // MARK: - Semantic state (Apple system colors)

    /// Warning / amber — .orange Apple
    static let solWarning = Color.orange
    /// Destructive / error — .red Apple (= #FF3B30 iOS standard)
    static let solDestructive = Color.red
    static let solDanger = Color.red
    /// Info — .blue Apple
    static let solInfo = Color.blue

    // MARK: - Border (Apple semantic)

    /// Bordură subtilă — .separator Apple (auto-adapt)
    static let solBorder = Color(.separator)
    /// Bordură accent (cards AI insight) — mint subtil
    static let solBorderAccent = Color.mint.opacity(0.25)
}

// MARK: - Gradients (Solomon brand signature — folosit DOAR pentru hero CTAs)

public extension LinearGradient {

    /// Brand gradient mint→cyan — DOAR pentru hero CTAs (Welcome, CanIAfford)
    static let solPrimaryCTA = LinearGradient(
        colors: [Color.mint, Color.cyan],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Hero / Avatar gradient (alias)
    static let solHero = LinearGradient(
        colors: [Color.mint, Color.cyan],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Warning gradient (rar folosit)
    static let solWarningGradient = LinearGradient(
        colors: [Color.orange, Color.red],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Hex init (păstrat pentru cazuri speciale, dar evităm folosirea)

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
