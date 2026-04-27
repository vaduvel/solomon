import SwiftUI

// MARK: - MomentCard
//
// Cardul principal Solomon — afișează răspunsul LLM generat pentru un moment.
// Design: surface card, icon colorat, text LLM, metadate discrete.

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
        VStack(alignment: .leading, spacing: SolSpacing.md) {

            // Header rând
            HStack(spacing: SolSpacing.sm) {
                momentIconView
                VStack(alignment: .leading, spacing: 2) {
                    Text(moment.title)
                        .font(.solHeadingSM)
                        .foregroundStyle(Color.solTextPrimary)
                    Text(moment.subtitle)
                        .font(.solCaption)
                        .foregroundStyle(Color.solTextMuted)
                }
                Spacer()
                severityBadge
            }

            // Separator subtil
            Divider()
                .background(Color.solBorder)

            // Conținut LLM
            Text(displayedText)
                .font(.solBodyLG)
                .foregroundStyle(Color.solTextPrimary)
                .lineSpacing(4)
                .animation(.easeInOut(duration: 0.25), value: isExpanded)

            // Footer — timp generat + expand button
            HStack {
                Text(moment.timeAgoString)
                    .solMuted()

                Spacer()

                if moment.llmResponse.count > 200 {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        Text(isExpanded ? "Mai puțin" : "Citește tot")
                            .font(.solCaption)
                            .foregroundStyle(Color.solMint)
                    }
                }
            }
        }
        .padding(SolSpacing.xl)
        .solCard()
    }

    // MARK: - Sub-views

    @ViewBuilder
    private var momentIconView: some View {
        ZStack {
            Circle()
                .fill(moment.accentColor.opacity(0.15))
                .frame(width: 40, height: 40)
            Image(systemName: moment.systemIconName)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(moment.accentColor)
        }
    }

    @ViewBuilder
    private var severityBadge: some View {
        if let badge = moment.badge {
            Text(badge)
                .font(.solCaption)
                .foregroundStyle(moment.accentColor)
                .padding(.horizontal, SolSpacing.sm)
                .padding(.vertical, SolSpacing.xs)
                .background(moment.accentColor.opacity(0.12))
                .clipShape(Capsule())
        }
    }

    // MARK: - Helpers

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

// MARK: - Preview helpers

extension DisplayMoment {

    static let previewCanIAfford = DisplayMoment(
        momentTypeRaw: "can_i_afford",
        title: "Pot să-mi permit?",
        subtitle: "Pizza de la Glovo · 65 RON",
        llmResponse: "DA, îți permiți. După pizza rămâi cu 735 RON pentru 9 zile, adică 81 RON/zi — e ok. Comanda fără griji.",
        accentColor: .solMint,
        systemIconName: "checkmark.circle.fill",
        badge: "DA"
    )

    static let previewSpiral = DisplayMoment(
        momentTypeRaw: "spiral_alert",
        title: "Alertă financiară",
        subtitle: "Spiral score 3 — Critic",
        llmResponse: "Vreau să vorbim 2 minute. Soldul tău scade constant — 4 luni la rând balanța finală a scăzut. Ai acum un IFN activ (Credius, ~3.250 RON total), plus un card de credit cu 1.840 RON datorie. Obligațiile depășesc venitul cu 380 RON/lună. Cel mai ușor prim pas: anulează abonamentele pe care nu le folosești — Netflix, HBO Max, Spotify împreună fac 104 RON/lună. CSALB te poate ajuta să renegociezi creditul gratuit. Asta e fixabil. Mergem împreună.",
        accentColor: .solDanger,
        systemIconName: "exclamationmark.triangle.fill",
        badge: "CRITIC"
    )

    static let previewPayday = DisplayMoment(
        momentTypeRaw: "payday",
        title: "Salariul a intrat! 🎉",
        subtitle: "5.200 RON · azi",
        llmResponse: "Banii au ajuns! Ai 5.200 RON intrați. Am rezervat 1.500 RON pentru obligații fixe — rămâi cu 3.660 RON liberi, adică 122 RON/zi pentru luna asta. E mai bine decât luna trecută!",
        accentColor: .solMint,
        systemIconName: "banknote.fill",
        badge: nil
    )
}

// MARK: - Preview

#Preview("Moment Card — CanIAfford") {
    ZStack {
        Color.solCanvas.ignoresSafeArea()
        MomentCard(moment: .previewCanIAfford)
            .padding()
    }
}

#Preview("Moment Card — Spiral Alert") {
    ZStack {
        Color.solCanvas.ignoresSafeArea()
        MomentCard(moment: .previewSpiral)
            .padding()
    }
}

#Preview("Moment Card — Payday") {
    ZStack {
        Color.solCanvas.ignoresSafeArea()
        MomentCard(moment: .previewPayday)
            .padding()
    }
}
