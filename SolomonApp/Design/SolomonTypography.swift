import SwiftUI

// MARK: - Solomon Design System — Tipografie
//
// SF Pro Display pentru headings mari, SF Pro Text pentru body, SF Mono pentru sume.
// Scara completă conform DS v0.

public extension Font {

    // MARK: - Display (numere eroice, splash)

    /// 64pt Bold — numere mari (balanță, sumă principală)
    static let solDisplayXL: Font = .system(size: 64, weight: .bold, design: .default)
    /// 48pt Bold — headings principale
    static let solDisplayLG: Font = .system(size: 48, weight: .bold, design: .default)

    // MARK: - Headings

    /// 28pt Bold — secțiuni principale
    static let solHeadingXL: Font = .system(size: 28, weight: .bold, design: .default)
    /// 22pt Semibold — titluri card
    static let solHeadingMD: Font = .system(size: 22, weight: .semibold, design: .default)
    /// 17pt Semibold — sub-titluri
    static let solHeadingSM: Font = .system(size: 17, weight: .semibold, design: .default)

    // MARK: - Body

    /// 17pt Regular — body principal (liste, descrieri)
    static let solBodyLG: Font = .system(size: 17, weight: .regular, design: .default)
    /// 15pt Regular — body secundar (sub-text, metadata)
    static let solBodyMD: Font = .system(size: 15, weight: .regular, design: .default)
    /// 13pt Regular — caption, labels mici
    static let solCaption: Font = .system(size: 13, weight: .medium, design: .default)

    // MARK: - Mono (sume inline)

    /// 13pt SF Mono Medium — sume afișate inline
    static let solMonoSM: Font = .system(size: 13, weight: .medium, design: .monospaced)
    /// 15pt SF Mono Medium — sume în card
    static let solMonoMD: Font = .system(size: 15, weight: .medium, design: .monospaced)
    /// 20pt SF Mono Semibold — sume mari în hero
    static let solMonoLG: Font = .system(size: 20, weight: .semibold, design: .monospaced)
}

// MARK: - Text modifier helpers

public extension View {

    /// Aplică stilul de sumă (mono + mint)
    func solMoneyStyle(size: Font = .solMonoMD, color: Color = .solMint) -> some View {
        self.font(size).foregroundStyle(color)
    }

    /// Aplică stilul de text atenuat
    func solMuted() -> some View {
        self.font(.solBodyMD).foregroundStyle(Color.solTextMuted)
    }
}
