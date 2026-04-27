import SwiftUI

// MARK: - StatusBadge & LabelBadge (DS v1.0)
//
// Mici tag-uri colorate cu icon + text.
// Status: success/warning/danger/info/neutral (cu icon stânga)
// Label: tag fără icon (Penny AI, Premium, 91% spent, Over budget)

struct StatusBadge: View {

    enum Kind {
        case success
        case warning
        case danger
        case info
        case neutral

        var color: Color {
            switch self {
            case .success: return .solPrimary
            case .warning: return .solWarning
            case .danger:  return .solDestructive
            case .info:    return .solCyan
            case .neutral: return .solMuted
            }
        }

        var icon: String? {
            switch self {
            case .success: return "checkmark"
            case .warning: return "exclamationmark.triangle.fill"
            case .danger:  return "xmark"
            case .info:    return "info.circle.fill"
            case .neutral: return nil
            }
        }
    }

    let title: String
    let kind: Kind

    var body: some View {
        HStack(spacing: 4) {
            if let icon = kind.icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
            }
            Text(title)
                .font(.solMicro)
        }
        .foregroundStyle(kind.color)
        .padding(.horizontal, SolSpacing.sm)
        .padding(.vertical, 4)
        .background(
            Capsule().fill(kind.color.opacity(0.15))
        )
        .overlay(
            Capsule().stroke(kind.color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Label badge (no icon, more bg)

struct LabelBadge: View {
    let title: String
    let color: Color

    var body: some View {
        Text(title)
            .font(.solMicro)
            .foregroundStyle(color)
            .padding(.horizontal, SolSpacing.sm)
            .padding(.vertical, 4)
            .background(
                Capsule().fill(color.opacity(0.18))
            )
    }
}

#Preview {
    ZStack {
        Color.solCanvas.ignoresSafeArea()
        VStack(spacing: SolSpacing.md) {
            HStack(spacing: 8) {
                StatusBadge(title: "Success", kind: .success)
                StatusBadge(title: "Warning", kind: .warning)
                StatusBadge(title: "Danger", kind: .danger)
                StatusBadge(title: "Info", kind: .info)
                StatusBadge(title: "Neutral", kind: .neutral)
            }
            HStack(spacing: 8) {
                LabelBadge(title: "Solomon AI", color: .solPrimary)
                LabelBadge(title: "Premium", color: .solCyan)
                LabelBadge(title: "91% spent", color: .solWarning)
                LabelBadge(title: "Over budget", color: .solDestructive)
            }
        }
        .padding(SolSpacing.lg)
    }
    .preferredColorScheme(.dark)
}
