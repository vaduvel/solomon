import SwiftUI

// MARK: - Solomon Design System v2.0 — Typography (Apple HIG aligned)
//
// Refactor Faza 27: aliniere la Apple Human Interface Guidelines.
// Folosim **direct** font styles native iOS (.largeTitle, .title2, .headline,
// .body, .footnote, etc.) care:
//   1. Suportă Dynamic Type automat (accessibility)
//   2. Au scale corect calibrat per platform
//   3. Adapt automat la light/dark mode
//
// Aliasurile Solomon (.solH1, .solDisplay etc.) sunt mapate la cele native
// pentru migrare graduală — NU mai introducem custom sizes.
//
// Excepție: hero numbers (Safe-to-Spend, payday amount) folosesc system mono
// la 40-56pt explicit pentru emphasis vizual cheie.

public extension Font {

    // MARK: - HIG native (preferate)

    // Toate astea sunt deja built-in: .largeTitle, .title, .title2, .title3,
    // .headline, .body, .callout, .subheadline, .footnote, .caption, .caption2

    // MARK: - Solomon hero numbers (excepție pentru emphasis)

    /// Hero number eroic (40pt Bold Mono) — Safe to Spend, Payday amount
    static let solHero: Font = .system(size: 40, weight: .bold, design: .monospaced)

    /// Big hero (56pt Bold Mono) — Wow Moment Safe-to-Spend
    static let solHeroBig: Font = .system(size: 56, weight: .bold, design: .monospaced)

    /// Mono inline (16pt Medium) — sume în liste/cards
    static let solMono: Font = .system(.callout, design: .monospaced).weight(.medium)

    /// Mono large (20pt Semibold) — sume în card hero
    static let solMonoLarge: Font = .system(.title3, design: .monospaced).weight(.semibold)

    // MARK: - Aliases legacy (mapate la HIG native pentru migrare graduală)

    static let solDisplay: Font = .system(size: 40, weight: .bold)
    static let solDisplayLG: Font = .system(size: 40, weight: .bold)
    static let solDisplayXL: Font = .system(size: 56, weight: .bold)

    static let solH1: Font = .title              // 28pt Regular
    static let solH2: Font = .title2             // 22pt Regular
    static let solH3: Font = .title3             // 20pt Regular
    static let solHeadingXL: Font = .title       // 28pt
    static let solHeadingMD: Font = .title2      // 22pt
    static let solHeadingSM: Font = .title3      // 20pt

    static let solHeadline: Font = .headline     // 17pt Semibold
    static let solBodyBold: Font = .system(.body, weight: .semibold)  // 17pt Semibold
    static let solBody: Font = .body             // 17pt Regular
    static let solBodyLG: Font = .body
    static let solBodyMD: Font = .callout        // 16pt Regular
    static let solCallout: Font = .callout       // 16pt
    static let solSubheadline: Font = .subheadline  // 15pt
    static let solCaption: Font = .footnote      // 13pt Regular
    static let solFootnote: Font = .footnote     // 13pt
    static let solMicro: Font = .caption2        // 11pt

    /// Mono small (13pt Medium)
    static let solMonoSM: Font = .system(.footnote, design: .monospaced).weight(.medium)
    /// Mono medium (16pt Medium) — alias pentru solMono
    static let solMonoMD: Font = .system(.callout, design: .monospaced).weight(.medium)
    /// Mono amount inline standard
    static let solMonoAmount: Font = .system(.callout, design: .monospaced).weight(.medium)
    /// Mono large inline (20pt)
    static let solMonoLG: Font = .system(.title3, design: .monospaced).weight(.semibold)
}

// MARK: - View modifier helpers

public extension View {

    /// Aplică stilul de sumă (mono + primary green)
    func solMoneyStyle(size: Font = .solMono, color: Color = .solPrimary) -> some View {
        self.font(size).foregroundStyle(color)
    }

    /// Text muted (foreground secondary)
    func solMuted() -> some View {
        self.foregroundStyle(.secondary)
    }

    /// Text muted style (alias)
    func solMutedStyle() -> some View {
        self.font(.body).foregroundStyle(Color.solMuted)
    }

    /// Section header style — uppercase footnote tracked
    func solSectionHeader() -> some View {
        self
            .font(.footnote)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .tracking(0.5)
    }
}
