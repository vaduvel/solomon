import SwiftUI

// MARK: - Solomon Design System v1.0 — Tipografie
//
// Sursa adevărului: Penny DS v1.0
//   - Primary: Space Grotesk (headings, UI labels, CTAs)
//   - Secondary: Inter (body text, meta, captions)
//   - Mono: JetBrains Mono (amounts, numbers, currency)
//
// IMPORTANT: Fonturile custom NU sunt încă embedded în bundle.
// Pentru moment folosim system fallbacks geometric similare:
//   - Space Grotesk → SF Pro Display (geometric sans)
//   - Inter → SF Pro Text (humanist sans, optimized for UI)
//   - JetBrains Mono → SF Mono (monospaced)
//
// TODO Faza 14+: download .ttf-uri și adaugă la Assets/Fonts în Info.plist.

public extension Font {

    // MARK: - Display / Hero (Space Grotesk Bold, 40px)

    static let solDisplay: Font = .system(size: 40, weight: .bold, design: .default)

    /// Aliasuri legacy
    static let solDisplayXL: Font = .system(size: 64, weight: .bold, design: .default)
    static let solDisplayLG: Font = .system(size: 40, weight: .bold, design: .default)

    // MARK: - Headings

    /// H1 / Screen Title — 22px Bold
    static let solH1: Font = .system(size: 22, weight: .bold, design: .default)
    /// H2 / Section — 20px Semibold
    static let solH2: Font = .system(size: 20, weight: .semibold, design: .default)
    /// H3 / Card Title — 18px Semibold
    static let solH3: Font = .system(size: 18, weight: .semibold, design: .default)

    /// Aliasuri legacy
    static let solHeadingXL: Font = .system(size: 22, weight: .bold, design: .default)
    static let solHeadingMD: Font = .system(size: 20, weight: .semibold, design: .default)
    static let solHeadingSM: Font = .system(size: 18, weight: .semibold, design: .default)

    // MARK: - Body (Inter)

    /// Body / Default — 15px Regular
    static let solBody: Font = .system(size: 15, weight: .regular, design: .default)
    /// Body bold (CTAs, emphasis) — 15px Semibold
    static let solBodyBold: Font = .system(size: 15, weight: .semibold, design: .default)
    /// Caption / Meta — 13px Regular
    static let solCaption: Font = .system(size: 13, weight: .regular, design: .default)
    /// Micro / Badge — 11px Medium
    static let solMicro: Font = .system(size: 11, weight: .medium, design: .default)

    /// Aliasuri legacy
    static let solBodyLG: Font = .system(size: 15, weight: .regular, design: .default)
    static let solBodyMD: Font = .system(size: 15, weight: .regular, design: .default)

    // MARK: - Mono (JetBrains Mono → SF Mono)

    /// Mono / Amount — 16px Medium-Semibold
    static let solMonoAmount: Font = .system(size: 16, weight: .semibold, design: .monospaced)
    /// Mono small (inline) — 13px Medium
    static let solMonoSM: Font = .system(size: 13, weight: .medium, design: .monospaced)
    /// Mono medium — 16px Medium
    static let solMonoMD: Font = .system(size: 16, weight: .medium, design: .monospaced)
    /// Mono large (hero amounts) — 40px Bold
    static let solMonoLG: Font = .system(size: 40, weight: .bold, design: .monospaced)

    /// Alias legacy
    static let solMono: Font = .system(size: 16, weight: .medium, design: .monospaced)
    static let solHeadline: Font = .system(size: 18, weight: .semibold, design: .default)
}

// MARK: - Text modifier helpers

public extension View {

    /// Aplică stilul de sumă (mono + primary green)
    func solMoneyStyle(size: Font = .solMonoAmount, color: Color = .solPrimary) -> some View {
        self.font(size).foregroundStyle(color)
    }

    /// Aplică stilul de text atenuat
    func solMutedStyle() -> some View {
        self.font(.solBody).foregroundStyle(Color.solMuted)
    }

    /// Alias legacy
    func solMuted() -> some View {
        self.font(.solBody).foregroundStyle(Color.solMuted)
    }
}
