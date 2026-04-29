import SwiftUI

// MARK: - Solomon Design Kit (Claude Design v3 — premium iOS 26)
//
// Transpunere 1:1 din Solomon DS / _shared.css (Claude Design):
//   - MeshBackground (3 mesh blobs + noise)
//   - SolIconButton (38×38 rounded square glass)
//   - HeroCard / HeroBadge cu variante mint/blue/amber/rose
//   - InsightCard cu variante
//   - StatCard / StatGrid
//   - ListCard / ListRow (glass list cu hairline rows)
//   - SolPill (filter) / SolChip (status)
//   - SolSectionHeader (h2 + meta)
//   - Brand logo helpers (ING, BT, Netflix, Spotify, etc.)

// MARK: - Precise palette (din _shared.css :root)

public extension Color {
    /// #34D399 — mint primary (vibrant, accent)
    static let solMintExact   = Color(red: 0x34/255, green: 0xD3/255, blue: 0x99/255)
    /// #10B981 — mint deep (gradient end)
    static let solMintDeep    = Color(red: 0x10/255, green: 0xB9/255, blue: 0x81/255)
    /// #6EE7B7 — mint light (text on dark)
    static let solMintLight   = Color(red: 0x6E/255, green: 0xE7/255, blue: 0xB7/255)
    /// #60A5FA — blue
    static let solBlueExact   = Color(red: 0x60/255, green: 0xA5/255, blue: 0xFA/255)
    /// #3B82F6 — blue deep
    static let solBlueDeep    = Color(red: 0x3B/255, green: 0x82/255, blue: 0xF6/255)
    /// #FBBF24 — amber
    static let solAmberExact  = Color(red: 0xFB/255, green: 0xBF/255, blue: 0x24/255)
    /// #F59E0B — amber deep
    static let solAmberDeep   = Color(red: 0xF5/255, green: 0x9E/255, blue: 0x0B/255)
    /// #FB7185 — rose
    static let solRoseExact   = Color(red: 0xFB/255, green: 0x71/255, blue: 0x85/255)
    /// #E11D48 — rose deep
    static let solRoseDeep    = Color(red: 0xE1/255, green: 0x1D/255, blue: 0x48/255)
    /// #8B5CF6 — violet
    static let solVioletExact = Color(red: 0x8B/255, green: 0x5C/255, blue: 0xF6/255)
    /// #7C3AED — violet deep
    static let solVioletDeep  = Color(red: 0x7C/255, green: 0x3A/255, blue: 0xED/255)

    /// Background canvas exact #050505
    static let solCanvasDark  = Color(red: 0x05/255, green: 0x05/255, blue: 0x05/255)

    /// Hairline white 0.06 — pentru row separators
    static let solHairline    = Color.white.opacity(0.06)
    static let solHairline2   = Color.white.opacity(0.04)

    /// Foreground tints
    static let solFG2  = Color.white.opacity(0.55)
    static let solFG3  = Color.white.opacity(0.40)
    static let solFG4  = Color.white.opacity(0.25)
}

// MARK: - Variant accent

public enum SolAccent: Sendable {
    case mint, blue, amber, rose, violet

    var color: Color {
        switch self {
        case .mint:   return .solMintExact
        case .blue:   return .solBlueExact
        case .amber:  return .solAmberExact
        case .rose:   return .solRoseExact
        case .violet: return .solVioletExact
        }
    }

    var lightColor: Color {
        switch self {
        case .mint:   return .solMintLight
        case .blue:   return Color(red: 0x93/255, green: 0xC5/255, blue: 0xFD/255)
        case .amber:  return .solAmberExact
        case .rose:   return Color(red: 0xFD/255, green: 0xA4/255, blue: 0xAF/255)
        case .violet: return Color(red: 0xC4/255, green: 0xB5/255, blue: 0xFD/255)
        }
    }

    var deepColor: Color {
        switch self {
        case .mint:   return .solMintDeep
        case .blue:   return .solBlueDeep
        case .amber:  return .solAmberDeep
        case .rose:   return .solRoseDeep
        case .violet: return .solVioletDeep
        }
    }

    /// Gradient pentru iconițe colorate (button background) — 18%→6% accent
    var iconGradient: LinearGradient {
        LinearGradient(
            colors: [color.opacity(0.18), color.opacity(0.06)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Gradient pentru btn-pri (180deg accent → deep)
    var primaryButtonGradient: LinearGradient {
        LinearGradient(
            colors: [color, deepColor],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Hero background gradient (155deg, 8% → 2% accent → 2% white)
    var heroBackgroundGradient: LinearGradient {
        LinearGradient(
            colors: [color.opacity(0.08), color.opacity(0.02), Color.white.opacity(0.02)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Top hairline gradient pentru hero (mint glow)
    var topHairlineGradient: LinearGradient {
        LinearGradient(
            colors: [.clear, color.opacity(0.4), .clear],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - MeshBackground

/// Background cu mesh-1 + mesh-2 + mesh-3 + noise — așa cum apare în orice screen.
public struct MeshBackground: View {
    public var topLeftAccent: SolAccent = .mint
    public var midRightAccent: SolAccent = .blue
    public var bottomLeftAccent: SolAccent = .violet

    public init(
        topLeftAccent: SolAccent = .mint,
        midRightAccent: SolAccent = .blue,
        bottomLeftAccent: SolAccent = .violet
    ) {
        self.topLeftAccent = topLeftAccent
        self.midRightAccent = midRightAccent
        self.bottomLeftAccent = bottomLeftAccent
    }

    public var body: some View {
        ZStack {
            Color.solCanvasDark.ignoresSafeArea()

            GeometryReader { geo in
                ZStack {
                    // mesh-1 (top-left, 380px)
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [topLeftAccent.color.opacity(0.18), topLeftAccent.color.opacity(0.04), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 190
                            )
                        )
                        .frame(width: 380, height: 380)
                        .blur(radius: 60)
                        .offset(x: -100, y: -120)

                    // mesh-2 (mid-right, 320px)
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [midRightAccent.color.opacity(0.12), midRightAccent.color.opacity(0.02), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 160
                            )
                        )
                        .frame(width: 320, height: 320)
                        .blur(radius: 50)
                        .offset(x: geo.size.width - 200, y: 200)

                    // mesh-3 (bottom-left, 280px)
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [bottomLeftAccent.color.opacity(0.10), bottomLeftAccent.color.opacity(0.02), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 140
                            )
                        )
                        .frame(width: 280, height: 280)
                        .blur(radius: 50)
                        .offset(x: -80, y: geo.size.height - 280)
                }
            }
            .allowsHitTesting(false)

            // Noise overlay (subtle)
            Canvas { ctx, size in
                let step: CGFloat = 3
                ctx.opacity = 0.6
                for x in stride(from: 0, to: size.width, by: step) {
                    for y in stride(from: 0, to: size.height, by: step) {
                        if Int.random(in: 0..<4) == 0 {
                            ctx.fill(
                                Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)),
                                with: .color(Color.white.opacity(0.015))
                            )
                        }
                    }
                }
            }
            .allowsHitTesting(false)
            .blendMode(.overlay)
        }
        .ignoresSafeArea()
    }
}

// MARK: - SolIconButton (38×38 rounded sq glass)

public struct SolIconButton: View {
    let systemName: String
    let action: () -> Void
    var hasDot: Bool = false
    var dotColor: Color = .solMintExact

    public init(systemName: String, hasDot: Bool = false, dotColor: Color = .solMintExact, action: @escaping () -> Void) {
        self.systemName = systemName
        self.hasDot = hasDot
        self.dotColor = dotColor
        self.action = action
    }

    public var body: some View {
        Button(action: {
            Haptics.light()
            action()
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                            .padding(0.5)
                    )

                Image(systemName: systemName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.white)

                if hasDot {
                    Circle()
                        .fill(dotColor)
                        .frame(width: 6, height: 6)
                        .shadow(color: dotColor, radius: 4)
                        .offset(x: 12, y: -12)
                }
            }
            .frame(width: 38, height: 38)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - SolBackButton (38×38 chevron back)

public struct SolBackButton: View {
    let action: () -> Void

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        Button(action: {
            Haptics.light()
            action()
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.white)
            }
            .frame(width: 38, height: 38)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - AppBar (brand label + greeting + actions)

public struct SolAppBar<Actions: View>: View {
    let brand: String
    let greeting: String
    @ViewBuilder let actions: () -> Actions

    public init(
        brand: String,
        greeting: String,
        @ViewBuilder actions: @escaping () -> Actions = { EmptyView() }
    ) {
        self.brand = brand
        self.greeting = greeting
        self.actions = actions
    }

    public var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text(brand)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.45))
                    .tracking(1.4)
                    .textCase(.uppercase)
                Text(greeting)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .tracking(-0.5)
            }
            Spacer()
            HStack(spacing: 8) {
                actions()
            }
        }
        .padding(.top, SolSpacing.sm)
        .padding(.bottom, SolSpacing.xl)
    }
}

// MARK: - HeroCard wrapper

/// Hero card cu glow ambient top-right, gradient background, top hairline glow, badge slot.
public struct SolHeroCard<Content: View, Badge: View>: View {
    let accent: SolAccent
    @ViewBuilder let content: () -> Content
    @ViewBuilder let badge: () -> Badge

    public init(
        accent: SolAccent = .mint,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder badge: @escaping () -> Badge = { EmptyView() }
    ) {
        self.accent = accent
        self.content = content
        self.badge = badge
    }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            // Hero glow (top-right radial)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [accent.color.opacity(0.25), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 60
                    )
                )
                .frame(width: 120, height: 120)
                .blur(radius: 30)
                .offset(x: -20, y: -10)
                .allowsHitTesting(false)

            // Card
            ZStack(alignment: .top) {
                // Top hairline glow
                accent.topHairlineGradient
                    .frame(height: 1)
                    .frame(maxWidth: .infinity, alignment: .top)

                content()
                    .padding(SolSpacing.lg)
            }
            .background(
                ZStack {
                    accent.heroBackgroundGradient
                    Rectangle().fill(.ultraThinMaterial).opacity(0.6)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(accent.color.opacity(0.18), lineWidth: 1)
            )
            .overlay(alignment: .top) {
                // Inset top white highlight
                Color.white.opacity(0.06).frame(height: 1)
            }
            .shadow(color: Color.black.opacity(0.5), radius: 20, x: 0, y: 20)

            // Badge top-right
            badge()
                .padding(.top, 18)
                .padding(.trailing, 18)
        }
    }
}

// MARK: - HeroBadge (pill cu dot in top-right)

public struct SolHeroBadge: View {
    let label: String
    let accent: SolAccent

    public init(_ label: String, accent: SolAccent = .mint) {
        self.label = label
        self.accent = accent
    }

    public var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(accent.color)
                .frame(width: 6, height: 6)
                .shadow(color: accent.color, radius: 5)
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(accent.lightColor)
                .tracking(0.6)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(accent.color.opacity(0.08))
        )
        .overlay(
            Capsule().stroke(accent.color.opacity(0.20), lineWidth: 1)
        )
    }
}

// MARK: - SolHeroLabel + SolHeroAmount

/// Label small uppercase tracked în hero (ex "DISPONIBIL LIBER · 9 ZILE").
public struct SolHeroLabel: View {
    let text: String
    public init(_ text: String) { self.text = text }
    public var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(Color.white.opacity(0.45))
            .tracking(0.7)
            .textCase(.uppercase)
    }
}

/// Hero amount mare cu decimal opțional + "RON".
/// `big` 42pt + `dec` 22pt + `cur` 13pt — exact ca în CSS.
public struct SolHeroAmount: View {
    let amount: String
    let decimals: String?
    let currency: String
    let accent: SolAccent

    public init(amount: String, decimals: String? = nil, currency: String = "RON", accent: SolAccent = .mint) {
        self.amount = amount
        self.decimals = decimals
        self.currency = currency
        self.accent = accent
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(amount)
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(Color.white)
                .tracking(-1.5)
                .monospacedDigit()
                .shadow(color: accent.color.opacity(0.18), radius: 30)
            if let decimals {
                Text(decimals)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.4))
                    .tracking(-0.5)
                    .monospacedDigit()
            }
            Text(currency)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.4))
                .padding(.leading, 6)
        }
    }
}

// MARK: - InsightCard

public struct SolInsightCard<Content: View>: View {
    let icon: String
    let label: String
    let timestamp: String?
    let accent: SolAccent
    @ViewBuilder let content: () -> Content

    public init(
        icon: String,
        label: String,
        timestamp: String? = nil,
        accent: SolAccent = .mint,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.icon = icon
        self.label = label
        self.timestamp = timestamp
        self.accent = accent
        self.content = content
    }

    public var body: some View {
        ZStack(alignment: .top) {
            // Top hairline (16px inset)
            HStack {
                accent.topHairlineGradient
                    .frame(height: 1)
                    .padding(.horizontal, 16)
            }

            HStack(alignment: .top, spacing: 12) {
                // Icon container
                ZStack {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(accent.iconGradient)
                        .overlay(
                            RoundedRectangle(cornerRadius: 11, style: .continuous)
                                .stroke(accent.color.opacity(0.25), lineWidth: 1)
                        )
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(accent.color)
                }
                .frame(width: 36, height: 36)
                .shadow(color: accent.color.opacity(0.15), radius: 10)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(label)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(accent.lightColor)
                            .tracking(0.5)
                        Spacer()
                        if let timestamp {
                            Text(timestamp)
                                .font(.system(size: 11))
                                .foregroundStyle(Color.white.opacity(0.35))
                        }
                    }

                    content()
                }
            }
            .padding(16)
        }
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.04), Color.white.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .background(.ultraThinMaterial.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
    }
}

// MARK: - PrimaryActionButton (btn-pri din CSS)

public struct SolPrimaryButton: View {
    let title: String
    let accent: SolAccent
    let fullWidth: Bool
    let action: () -> Void

    public init(_ title: String, accent: SolAccent = .mint, fullWidth: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.accent = accent
        self.fullWidth = fullWidth
        self.action = action
    }

    public var body: some View {
        Button(action: {
            Haptics.medium()
            action()
        }) {
            Text(title)
                .font(.system(size: fullWidth ? 14 : 12, weight: .semibold))
                .foregroundStyle(textColor)
                .padding(.horizontal, fullWidth ? 18 : 14)
                .padding(.vertical, fullWidth ? 13 : 7)
                .frame(maxWidth: fullWidth ? .infinity : nil)
                .background(accent.primaryButtonGradient)
                .clipShape(RoundedRectangle(cornerRadius: fullWidth ? 14 : 9, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: fullWidth ? 14 : 9, style: .continuous)
                        .stroke(Color.white.opacity(0.20), lineWidth: 1)
                        .blendMode(.plusLighter)
                )
                .shadow(color: accent.color.opacity(0.4), radius: 12, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    private var textColor: Color {
        switch accent {
        case .mint:   return Color(red: 0x05/255, green: 0x2E/255, blue: 0x16/255)
        case .blue:   return Color.white
        case .amber:  return Color(red: 0x45/255, green: 0x1A/255, blue: 0x03/255)
        case .rose:   return Color.white
        case .violet: return Color.white
        }
    }
}

public struct SolSecondaryButton: View {
    let title: String
    let fullWidth: Bool
    let action: () -> Void

    public init(_ title: String, fullWidth: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.fullWidth = fullWidth
        self.action = action
    }

    public var body: some View {
        Button(action: {
            Haptics.light()
            action()
        }) {
            Text(title)
                .font(.system(size: fullWidth ? 14 : 12, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.7))
                .padding(.horizontal, fullWidth ? 18 : 14)
                .padding(.vertical, fullWidth ? 13 : 7)
                .frame(maxWidth: fullWidth ? .infinity : nil)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: fullWidth ? 14 : 9, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: fullWidth ? 14 : 9, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - StatCard

public struct SolStatCard: View {
    let label: String
    let name: String
    let value: String
    let meta: String?
    let metaAccent: SolAccent?
    let icon: String
    let iconAccent: SolAccent

    public init(
        label: String,
        name: String,
        value: String,
        meta: String? = nil,
        metaAccent: SolAccent? = nil,
        icon: String,
        iconAccent: SolAccent
    ) {
        self.label = label
        self.name = name
        self.value = value
        self.meta = meta
        self.metaAccent = metaAccent
        self.icon = icon
        self.iconAccent = iconAccent
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(iconAccent.iconGradient)
                        .overlay(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .stroke(iconAccent.color.opacity(0.20), lineWidth: 1)
                        )
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(iconAccent.color)
                }
                .frame(width: 30, height: 30)
                Spacer()
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.4))
                    .tracking(0.4)
            }
            .padding(.bottom, 10)

            Text(name)
                .font(.system(size: 11))
                .foregroundStyle(Color.white.opacity(0.5))
                .padding(.top, 2)

            Text(value)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.white)
                .monospacedDigit()
                .tracking(-0.3)
                .padding(.top, 2)

            if let meta {
                Text(meta)
                    .font(.system(size: 11))
                    .foregroundStyle(metaAccent?.color ?? Color.white.opacity(0.45))
                    .padding(.top, 2)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.04), Color.white.opacity(0.015)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .background(.ultraThinMaterial.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
    }
}

// MARK: - SectionHeader (h2 + meta)

public struct SolSectionHeaderRow: View {
    let title: String
    let meta: String?

    public init(_ title: String, meta: String? = nil) {
        self.title = title
        self.meta = meta
    }

    public var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.5))
                .tracking(0.6)
                .textCase(.uppercase)
            Spacer()
            if let meta {
                Text(meta)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.45))
            }
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 12)
    }
}

// MARK: - ListCard (glass list cu rows)

public struct SolListCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    public var body: some View {
        VStack(spacing: 0) {
            content()
        }
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.035), Color.white.opacity(0.015)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .background(.ultraThinMaterial.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
    }
}

/// Hairline divider 0.5px folosit între rows în SolListCard.
public struct SolHairlineDivider: View {
    public init() {}
    public var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.04))
            .frame(height: 0.5)
            .padding(.horizontal, 16)
    }
}

// MARK: - ListRow (40×40 logo + title/sub + right value)

public struct SolListRow<Leading: View, Trailing: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder let leading: () -> Leading
    @ViewBuilder let trailing: () -> Trailing
    let onTap: (() -> Void)?

    public init(
        title: String,
        subtitle: String? = nil,
        onTap: (() -> Void)? = nil,
        @ViewBuilder leading: @escaping () -> Leading,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leading = leading
        self.trailing = trailing
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: {
            if let onTap {
                Haptics.light()
                onTap()
            }
        }) {
            HStack(spacing: 12) {
                leading()
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.white)
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.white.opacity(0.4))
                    }
                }
                Spacer()
                trailing()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(onTap == nil)
    }
}

// MARK: - Brand logo (rounded square 36×36)

public struct SolBrandLogo: View {
    public enum Brand: Sendable {
        case ing, bt, raiffeisen, brd, bcr
        case netflix, spotify, hbo, applemusic
        case glovo, bolt, uber, mega
        case cash      // mint cu icon $
        case dotted    // dashed border (placeholder)
        case custom(letter: String, gradient: LinearGradient, foreground: Color)
    }

    let brand: Brand
    var size: CGFloat = 36

    public init(_ brand: Brand, size: CGFloat = 36) {
        self.brand = brand
        self.size = size
    }

    public var body: some View {
        Group {
            switch brand {
            case .ing:
                logoView(letter: "ING", gradient: gradient(0xFF6B00, 0xE55A00), fg: .white)
            case .bt:
                logoView(letter: "BT", gradient: gradient(0xFFEB00, 0xFACC15), fg: Color(red: 0x1a/255, green: 0x1a/255, blue: 0x1a/255))
            case .raiffeisen:
                logoView(letter: "R", gradient: gradient(0xFFE600, 0xFFCC00), fg: .black)
            case .brd:
                logoView(letter: "BRD", gradient: gradient(0xC8102E, 0x8C0A1F), fg: .white)
            case .bcr:
                logoView(letter: "BCR", gradient: gradient(0x1E3F8B, 0x0E2A64), fg: .white)
            case .netflix:
                logoView(letter: "N", gradient: gradient(0xE50914, 0xB0060F), fg: .white)
            case .spotify:
                logoView(letter: "S", gradient: gradient(0x1DB954, 0x1AA34A), fg: .white)
            case .hbo:
                logoView(letter: "H", gradient: gradient(0x9B5CF6, 0x6B40C7), fg: .white)
            case .applemusic:
                logoView(letter: "A", gradient: gradient(0x1C1C1E, 0x000000), fg: .white)
            case .glovo:
                logoView(letter: "G", gradient: gradient(0xFFC244, 0xFFA200), fg: Color(red: 0x1a/255, green: 0x1a/255, blue: 0x1a/255))
            case .bolt:
                logoView(letter: "B", gradient: gradient(0x3B82F6, 0x2563EB), fg: .white)
            case .uber:
                logoView(letter: "U", gradient: gradient(0x000000, 0x1a1a1a), fg: .white)
            case .mega:
                logoView(letter: "M", gradient: gradient(0xE53935, 0xC62828), fg: .white)
            case .cash:
                ZStack {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(SolAccent.mint.iconGradient)
                        .overlay(
                            RoundedRectangle(cornerRadius: 11, style: .continuous)
                                .stroke(Color.solMintExact.opacity(0.25), lineWidth: 1)
                        )
                    Image(systemName: "banknote.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.solMintExact)
                }
                .frame(width: size, height: size)
            case .dotted:
                ZStack {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 11, style: .continuous)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                                .foregroundStyle(Color.white.opacity(0.2))
                        )
                    Image(systemName: "questionmark")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.5))
                }
                .frame(width: size, height: size)
            case .custom(let letter, let g, let fg):
                logoView(letter: letter, gradient: g, fg: fg)
            }
        }
    }

    private func gradient(_ a: Int, _ b: Int) -> LinearGradient {
        LinearGradient(
            colors: [
                Color(red: Double(a >> 16 & 0xff)/255, green: Double(a >> 8 & 0xff)/255, blue: Double(a & 0xff)/255),
                Color(red: Double(b >> 16 & 0xff)/255, green: Double(b >> 8 & 0xff)/255, blue: Double(b & 0xff)/255)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    @ViewBuilder
    private func logoView(letter: String, gradient: LinearGradient, fg: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(gradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
            Text(letter)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(fg)
                .tracking(-0.3)
        }
        .frame(width: size, height: size)
        .shadow(color: Color.black.opacity(0.4), radius: 4, x: 0, y: 2)
    }
}

// MARK: - SolPill (filter pill)

public struct SolPill: View {
    let label: String
    let isActive: Bool
    let action: () -> Void

    public init(_ label: String, isActive: Bool = false, action: @escaping () -> Void) {
        self.label = label
        self.isActive = isActive
        self.action = action
    }

    public var body: some View {
        Button(action: {
            Haptics.light()
            action()
        }) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isActive ? Color.solMintLight : Color.white.opacity(0.6))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isActive ? Color.solMintExact.opacity(0.12) : Color.white.opacity(0.04))
                )
                .overlay(
                    Capsule()
                        .stroke(isActive ? Color.solMintExact.opacity(0.30) : Color.white.opacity(0.08), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - SolChip (status chip)

public struct SolChip: View {
    public enum Kind: Sendable {
        case mint, warn, rose, muted, blue, violet
    }

    let label: String
    let kind: Kind

    public init(_ label: String, kind: Kind = .mint) {
        self.label = label
        self.kind = kind
    }

    public var body: some View {
        Text(label)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(textColor)
            .tracking(0.3)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(bgColor)
            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
    }

    private var bgColor: Color {
        switch kind {
        case .mint:   return Color.solMintExact.opacity(0.12)
        case .warn:   return Color.solAmberExact.opacity(0.12)
        case .rose:   return Color.solRoseExact.opacity(0.12)
        case .muted:  return Color.white.opacity(0.05)
        case .blue:   return Color.solBlueExact.opacity(0.12)
        case .violet: return Color.solVioletExact.opacity(0.12)
        }
    }

    private var borderColor: Color {
        switch kind {
        case .mint:   return Color.solMintExact.opacity(0.22)
        case .warn:   return Color.solAmberExact.opacity(0.22)
        case .rose:   return Color.solRoseExact.opacity(0.25)
        case .muted:  return Color.white.opacity(0.08)
        case .blue:   return Color.solBlueExact.opacity(0.22)
        case .violet: return Color.solVioletExact.opacity(0.22)
        }
    }

    private var textColor: Color {
        switch kind {
        case .mint:   return .solMintExact
        case .warn:   return .solAmberExact
        case .rose:   return .solRoseExact
        case .muted:  return Color.white.opacity(0.5)
        case .blue:   return .solBlueExact
        case .violet: return .solVioletExact
        }
    }
}

// MARK: - Allocation bar (multi-segment progress în hero wallet)

public struct SolAllocationBar: View {
    public struct Segment: Sendable {
        let fraction: CGFloat
        let gradient: LinearGradient
        let glowColor: Color?

        public init(fraction: CGFloat, gradient: LinearGradient, glowColor: Color? = nil) {
            self.fraction = fraction
            self.gradient = gradient
            self.glowColor = glowColor
        }
    }

    let segments: [Segment]
    let height: CGFloat

    public init(segments: [Segment], height: CGFloat = 7) {
        self.segments = segments
        self.height = height
    }

    public var body: some View {
        GeometryReader { geo in
            HStack(spacing: 2) {
                ForEach(segments.indices, id: \.self) { i in
                    let seg = segments[i]
                    Capsule()
                        .fill(seg.gradient)
                        .frame(width: max(0, geo.size.width * seg.fraction - 2))
                        .shadow(color: seg.glowColor ?? .clear, radius: 8)
                }
                Spacer(minLength: 0)
            }
        }
        .frame(height: height)
        .background(
            Capsule().fill(Color.white.opacity(0.04))
        )
        .overlay(
            Capsule().fill(Color.black.opacity(0.2)).frame(height: 1).padding(.top, -2),
            alignment: .top
        )
    }
}

// MARK: - Cap progress ring (used in goals.html)

public struct SolProgressRing: View {
    let progress: CGFloat   // 0...1
    let label: String?
    var size: CGFloat = 120
    var lineWidth: CGFloat = 9
    var accent: SolAccent = .mint

    public init(progress: CGFloat, label: String? = nil, size: CGFloat = 120, lineWidth: CGFloat = 9, accent: SolAccent = .mint) {
        self.progress = progress
        self.label = label
        self.size = size
        self.lineWidth = lineWidth
        self.accent = accent
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.06), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(colors: [accent.color, accent.deepColor], startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: accent.color.opacity(0.4), radius: 6)

            VStack(spacing: -2) {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .monospacedDigit()
                    .tracking(-0.8)
                if let label {
                    Text(label)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.4))
                        .tracking(0.4)
                        .textCase(.uppercase)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Linear progress (mini, used in goals/categories)

public struct SolLinearProgress: View {
    let progress: CGFloat
    let accent: SolAccent
    var height: CGFloat = 6
    var glow: Bool = false

    public init(progress: CGFloat, accent: SolAccent = .mint, height: CGFloat = 6, glow: Bool = false) {
        self.progress = progress
        self.accent = accent
        self.height = height
        self.glow = glow
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.05))
                Capsule()
                    .fill(LinearGradient(colors: [accent.color, accent.deepColor], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(0, geo.size.width * progress))
                    .shadow(color: glow ? accent.color.opacity(0.4) : .clear, radius: 8)
            }
        }
        .frame(height: height)
    }
}
