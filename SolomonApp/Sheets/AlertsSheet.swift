import SwiftUI

// MARK: - AlertsSheet
//
// Sheet deschis la apăsarea clopotelului din TodayView.
// Redesign 1:1 cu Solomon DS / screens/alerts.html (Claude Design v3 editorial premium).
// Layout: handle + appbar (brand "SOLOMON · ALERTE" + count) +
//         secțiune AZI (currentMoment + restul de azi) + secțiune ANTERIOARE.

struct AlertsSheet: View {

    @Environment(\.dismiss) private var dismiss

    let moments: [DisplayMoment]
    let currentMoment: DisplayMoment?

    var body: some View {
        ZStack {
            MeshBackground()

            VStack(spacing: 0) {
                // Sheet handle (4×40 capsule centrat)
                handle
                    .padding(.top, 8)
                    .padding(.bottom, 4)

                ScrollView {
                    VStack(spacing: 0) {
                        appbar
                            .padding(.bottom, 16)

                        // Pinned: momentul curent (azi).
                        if let current = currentMoment {
                            SolSectionHeaderRow("AZI", meta: countLabel(for: todayMoments(includingCurrent: true)))

                            VStack(spacing: 10) {
                                alertCard(current)
                                ForEach(todayMoments(includingCurrent: false)) { moment in
                                    alertCard(moment)
                                }
                            }
                            .padding(.bottom, 14)
                        } else if !todayMoments(includingCurrent: false).isEmpty {
                            SolSectionHeaderRow("AZI", meta: countLabel(for: todayMoments(includingCurrent: false)))

                            VStack(spacing: 10) {
                                ForEach(todayMoments(includingCurrent: false)) { moment in
                                    alertCard(moment)
                                }
                            }
                            .padding(.bottom, 14)
                        }

                        if !olderMoments.isEmpty {
                            SolSectionHeaderRow("ANTERIOARE", meta: countLabel(for: olderMoments))

                            VStack(spacing: 10) {
                                ForEach(olderMoments) { moment in
                                    alertCard(moment, dimmed: true)
                                }
                            }
                            .padding(.bottom, 14)
                        }

                        if currentMoment == nil && moments.isEmpty {
                            emptyState
                        }

                        Color.clear.frame(height: 40)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Handle

    private var handle: some View {
        HStack {
            Spacer()
            Capsule()
                .fill(Color.white.opacity(0.18))
                .frame(width: 36, height: 5)
            Spacer()
        }
    }

    // MARK: - App bar (brand + count)

    private var appbar: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text("SOLOMON · ALERTE")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.45))
                    .tracking(1.4)
                Text(greetingText)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .tracking(-0.5)
            }
            Spacer()
        }
        .padding(.top, 8)
    }

    private var greetingText: String {
        let total = totalCount
        if total == 0 { return "Liniște" }
        if total == 1 { return "1 nouă" }
        return "\(total) noi"
    }

    private var totalCount: Int {
        let currentExtra = currentMoment == nil ? 0 : 1
        return moments.count + currentExtra
    }

    // MARK: - Sections — partitioning

    /// Toate momentele unice (currentMoment înaintea moments dacă nu e deja inclus).
    private var allMoments: [DisplayMoment] {
        var out: [DisplayMoment] = []
        if let current = currentMoment {
            out.append(current)
        }
        for moment in moments where moment.id != currentMoment?.id {
            out.append(moment)
        }
        return out
    }

    private func todayMoments(includingCurrent: Bool) -> [DisplayMoment] {
        let cal = Calendar.current
        return allMoments.filter { moment in
            guard cal.isDateInToday(moment.generatedAt) else { return false }
            if !includingCurrent, moment.id == currentMoment?.id { return false }
            return true
        }
    }

    private var olderMoments: [DisplayMoment] {
        let cal = Calendar.current
        return allMoments.filter { !cal.isDateInToday($0.generatedAt) }
    }

    private func countLabel(for list: [DisplayMoment]) -> String {
        "\(list.count)"
    }

    // MARK: - Alert card (alert-card din alerts.html)

    @ViewBuilder
    private func alertCard(_ moment: DisplayMoment, dimmed: Bool = false) -> some View {
        let accent = accentForMoment(moment)
        let titleColor = dimmed ? Color.white.opacity(0.85) : Color.white
        let bodyColor = dimmed ? Color.white.opacity(0.55) : Color.white.opacity(0.7)

        Button {
            Haptics.light()
            dismiss()
        } label: {
            HStack(alignment: .top, spacing: 12) {
                alertIcon(moment: moment, accent: accent)

                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 8) {
                        Text(moment.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(titleColor)
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        Text(moment.timeAgoString)
                            .font(.system(size: 11))
                            .foregroundStyle(Color.white.opacity(0.4))
                    }
                    .padding(.bottom, 3)

                    Text(moment.llmResponse)
                        .font(.system(size: 13))
                        .foregroundStyle(bodyColor)
                        .lineSpacing(2)
                        .multilineTextAlignment(.leading)
                        .padding(.bottom, 10)

                    if let badge = moment.badge {
                        HStack(spacing: 8) {
                            SolChip(badge, kind: chipKindForAccent(accent))
                            Spacer()
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(alertCardBackground(accent: accent, dimmed: dimmed))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(alertCardStroke(accent: accent, dimmed: dimmed), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func alertIcon(moment: DisplayMoment, accent: SolAccent) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(accent.color.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(accent.color.opacity(0.30), lineWidth: 1)
                )
            Image(systemName: moment.systemIconName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(accent.color)
        }
        .frame(width: 34, height: 34)
    }

    @ViewBuilder
    private func alertCardBackground(accent: SolAccent, dimmed: Bool) -> some View {
        if dimmed {
            LinearGradient(
                colors: [Color.white.opacity(0.04), Color.white.opacity(0.015)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            LinearGradient(
                colors: [accent.color.opacity(0.05), accent.color.opacity(0.01)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private func alertCardStroke(accent: SolAccent, dimmed: Bool) -> Color {
        dimmed ? Color.white.opacity(0.07) : accent.color.opacity(0.2)
    }

    // MARK: - Accent mapping per moment type

    private func accentForMoment(_ moment: DisplayMoment) -> SolAccent {
        switch moment.momentTypeRaw {
        case "spiral_alert":         return .rose
        case "upcoming_obligation":  return .amber
        case "can_i_afford":         return .blue
        default:                     return .mint
        }
    }

    private func chipKindForAccent(_ accent: SolAccent) -> SolChip.Kind {
        switch accent {
        case .rose:   return .rose
        case .amber:  return .warn
        case .blue:   return .blue
        case .violet: return .violet
        case .mint:   return .mint
        }
    }

    // MARK: - Empty state

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "bell.slash")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(Color.white.opacity(0.4))
            Text("Nicio alertă activă")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.white)
            Text("Solomon monitorizează datele tale și te avertizează când detectează ceva important.")
                .font(.system(size: 13))
                .foregroundStyle(Color.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

#Preview {
    AlertsSheet(
        moments: [.previewSpiral, .previewPayday, .previewCanIAfford],
        currentMoment: .previewSpiral
    )
    .preferredColorScheme(.dark)
}
