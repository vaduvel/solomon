import SwiftUI

// MARK: - MomentCard (Claude Design v3 — premium glass)
//
// Cardul principal Solomon — afișează răspunsul LLM generat pentru un moment.
// Design: glass card .ultraThinMaterial cu border subtle, icon container colorat,
// badge accent capsule, body 14pt + footer mint expand.
//
// API public PĂSTRAT — nu rupe call site-urile existente.

public struct MomentCard: View {

    // MARK: - Input

    public let moment: DisplayMoment

    // MARK: - State

    @State private var isExpanded = false

    // MARK: - Init

    public init(moment: DisplayMoment) {
        self.moment = moment
    }

    // MARK: - Body

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            // Header rând: icon container colorat + title/subtitle + badge
            HStack(alignment: .top, spacing: 12) {
                momentIconView

                VStack(alignment: .leading, spacing: 2) {
                    Text(moment.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.white)
                    Text(moment.subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.45))
                }

                Spacer()

                severityBadge
            }

            // Conținut LLM
            Text(displayedText)
                .font(.system(size: 14))
                .foregroundStyle(Color.white.opacity(0.85))
                .lineSpacing(2)
                .animation(.easeInOut(duration: 0.25), value: isExpanded)

            // Footer — timp generat + expand button mint
            HStack {
                Text(moment.timeAgoString)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.white.opacity(0.35))

                Spacer()

                if moment.llmResponse.count > 200 {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        Text(isExpanded ? "Mai puțin" : "Citește tot")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.solMintExact)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.04), Color.white.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .background(.ultraThinMaterial.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.4), radius: 20, x: 0, y: 8)
    }

    // MARK: - Sub-views

    @ViewBuilder
    private var momentIconView: some View {
        let accent = preciseAccent
        ZStack {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(accent.iconGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .stroke(accent.color.opacity(0.4), lineWidth: 1)
                )
            Image(systemName: moment.systemIconName)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(accent.color)
        }
        .frame(width: 36, height: 36)
        .shadow(color: accent.color.opacity(0.18), radius: 10)
    }

    @ViewBuilder
    private var severityBadge: some View {
        if let badge = moment.badge {
            let accent = preciseAccent
            HStack(spacing: 6) {
                Circle()
                    .fill(accent.color)
                    .frame(width: 6, height: 6)
                    .shadow(color: accent.color, radius: 4)
                Text(badge)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(accent.lightColor)
                    .tracking(0.5)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule().fill(accent.color.opacity(0.10))
            )
            .overlay(
                Capsule().stroke(accent.color.opacity(0.25), lineWidth: 1)
            )
        }
    }

    // MARK: - Helpers

    /// Map accentul DisplayMoment (Color) la SolAccent precis pentru tokens noi.
    private var preciseAccent: SolAccent {
        switch moment.momentTypeRaw {
        case "spiral_alert":           return .rose
        case "upcoming_obligation":    return .amber
        case "can_i_afford",
             "pattern_alert":          return .blue
        default:                       return .mint
        }
    }

    private var displayedText: String {
        guard !isExpanded && moment.llmResponse.count > 200 else {
            return moment.llmResponse
        }
        let truncated = String(moment.llmResponse.prefix(200))
        return truncated + "…"
    }
}

// MARK: - DisplayMoment model

/// Model de prezentare pentru MomentCard — decuplat de la domeniu.
public struct DisplayMoment: Identifiable, Sendable {
    public let id: UUID
    public let momentTypeRaw: String
    public let title: String
    public let subtitle: String
    public let llmResponse: String
    public let generatedAt: Date
    public let accentColor: Color
    public let systemIconName: String
    public let badge: String?

    public init(
        id: UUID = UUID(),
        momentTypeRaw: String,
        title: String,
        subtitle: String,
        llmResponse: String,
        generatedAt: Date = .now,
        accentColor: Color = .solMint,
        systemIconName: String = "sparkles",
        badge: String? = nil
    ) {
        self.id = id
        self.momentTypeRaw = momentTypeRaw
        self.title = title
        self.subtitle = subtitle
        self.llmResponse = llmResponse
        self.generatedAt = generatedAt
        self.accentColor = accentColor
        self.systemIconName = systemIconName
        self.badge = badge
    }

    public var timeAgoString: String {
        let interval = Date.now.timeIntervalSince(generatedAt)
        if interval < 60 { return "acum" }
        if interval < 3600 { return "acum \(Int(interval / 60)) min" }
        if interval < 86400 { return "acum \(Int(interval / 3600))h" }
        return "azi"
    }
}

// MARK: - Mapper from MomentOutput

import SolomonCore
import SolomonMoments

public extension DisplayMoment {

    /// Convertește un MomentOutput (din SolomonMoments) într-un DisplayMoment pentru UI.
    static func from(_ output: MomentOutput) -> DisplayMoment {
        DisplayMoment(
            momentTypeRaw: output.momentType.rawValue,
            title: titleFor(output.momentType),
            subtitle: subtitleFor(output.momentType),
            llmResponse: output.llmResponse,
            generatedAt: output.generatedAt,
            accentColor: accentColorFor(output.momentType),
            systemIconName: iconFor(output.momentType),
            badge: badgeFor(output.momentType)
        )
    }

    private static func titleFor(_ type: MomentType) -> String {
        switch type {
        case .wowMoment:           return "Primul tău raport"
        case .canIAfford:          return "Verificare rapidă"
        case .payday:              return "Salariul a intrat"
        case .upcomingObligation:  return "Plată care urmează"
        case .patternAlert:        return "Tipar nou detectat"
        case .subscriptionAudit:   return "Audit abonamente"
        case .spiralAlert:         return "Atenție — presiune financiară"
        case .weeklySummary:       return "Săptămâna ta"
        }
    }

    private static func subtitleFor(_ type: MomentType) -> String {
        switch type {
        case .wowMoment:           return "Solomon a analizat ultimele luni"
        case .canIAfford:          return "Pot să-mi permit?"
        case .payday:              return "Alocare automată"
        case .upcomingObligation:  return "Pregătește-te pentru plată"
        case .patternAlert:        return "Observație Solomon"
        case .subscriptionAudit:   return "Lunar — verificare automată"
        case .spiralAlert:         return "Plan de recuperare disponibil"
        case .weeklySummary:       return "Sumar duminică"
        }
    }

    private static func iconFor(_ type: MomentType) -> String {
        switch type {
        case .wowMoment:           return "sparkles"
        case .canIAfford:          return "questionmark.circle.fill"
        case .payday:              return "banknote.fill"
        case .upcomingObligation:  return "calendar.badge.exclamationmark"
        case .patternAlert:        return "chart.line.uptrend.xyaxis"
        case .subscriptionAudit:   return "scissors"
        case .spiralAlert:         return "exclamationmark.triangle.fill"
        case .weeklySummary:       return "chart.bar.fill"
        }
    }

    private static func accentColorFor(_ type: MomentType) -> Color {
        switch type {
        case .spiralAlert:         return .solRoseExact
        case .upcomingObligation:  return .solAmberExact
        case .canIAfford,
             .patternAlert:        return .solBlueExact
        default:                   return .solMintExact
        }
    }

    private static func badgeFor(_ type: MomentType) -> String? {
        switch type {
        case .spiralAlert:         return "URGENT"
        case .upcomingObligation:  return "Atenție"
        default:                   return nil
        }
    }
}

// MARK: - Preview helpers

extension DisplayMoment {

    static let previewCanIAfford = DisplayMoment(
        momentTypeRaw: "can_i_afford",
        title: "Pot să-mi permit?",
        subtitle: "Pizza de la Glovo · 65 RON",
        llmResponse: "DA, îți permiți. După pizza rămâi cu 735 RON pentru 9 zile, adică 81 RON/zi — e ok. Comanda fără griji.",
        accentColor: .solMintExact,
        systemIconName: "checkmark.circle.fill",
        badge: "DA"
    )

    static let previewSpiral = DisplayMoment(
        momentTypeRaw: "spiral_alert",
        title: "Alertă financiară",
        subtitle: "Spiral score 3 — Critic",
        llmResponse: "Vreau să vorbim 2 minute. Soldul tău scade constant — 4 luni la rând balanța finală a scăzut. Ai acum un IFN activ (Credius, ~3.250 RON total), plus un card de credit cu 1.840 RON datorie. Obligațiile depășesc venitul cu 380 RON/lună. Cel mai ușor prim pas: anulează abonamentele pe care nu le folosești — Netflix, HBO Max, Spotify împreună fac 104 RON/lună. CSALB te poate ajuta să renegociezi creditul gratuit. Asta e fixabil. Mergem împreună.",
        accentColor: .solRoseExact,
        systemIconName: "exclamationmark.triangle.fill",
        badge: "CRITIC"
    )

    static let previewPayday = DisplayMoment(
        momentTypeRaw: "payday",
        title: "Salariul a intrat!",
        subtitle: "5.200 RON · azi",
        llmResponse: "Banii au ajuns! Ai 5.200 RON intrați. Am rezervat 1.500 RON pentru obligații fixe — rămâi cu 3.660 RON liberi, adică 122 RON/zi pentru luna asta. E mai bine decât luna trecută!",
        accentColor: .solMintExact,
        systemIconName: "banknote.fill",
        badge: nil
    )
}

// MARK: - Preview

#Preview("Moment Card — CanIAfford") {
    ZStack {
        Color.solCanvasDark.ignoresSafeArea()
        MomentCard(moment: .previewCanIAfford)
            .padding()
    }
    .preferredColorScheme(.dark)
}

#Preview("Moment Card — Spiral Alert") {
    ZStack {
        Color.solCanvasDark.ignoresSafeArea()
        MomentCard(moment: .previewSpiral)
            .padding()
    }
    .preferredColorScheme(.dark)
}

#Preview("Moment Card — Payday") {
    ZStack {
        Color.solCanvasDark.ignoresSafeArea()
        MomentCard(moment: .previewPayday)
            .padding()
    }
    .preferredColorScheme(.dark)
}
