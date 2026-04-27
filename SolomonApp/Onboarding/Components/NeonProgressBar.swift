import SwiftUI

// MARK: - NeonProgressBar (DS v1.0)
//
// Progress bar liniar cu neon glow.
// 4 stări de culoare: success (mint), info (cyan), warning (amber), danger (red).
// Inălțime: 2px (thin) sau 4px (standard).

struct NeonProgressBar: View {

    enum Variant {
        case success    // mint
        case info       // cyan
        case warning    // amber
        case danger     // red
        case automatic  // auto by progress: <0.7 success, <0.9 warning, else danger

        func color(progress: Double) -> Color {
            switch self {
            case .success: return .solPrimary
            case .info:    return .solCyan
            case .warning: return .solWarning
            case .danger:  return .solDestructive
            case .automatic:
                if progress < 0.7 { return .solPrimary }
                if progress < 0.9 { return .solWarning }
                return .solDestructive
            }
        }
    }

    let progress: Double  // 0.0...1.0
    var variant: Variant = .automatic
    var height: CGFloat = 4
    var label: String? = nil
    var trailing: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: SolSpacing.xs) {
            if label != nil || trailing != nil {
                HStack {
                    if let label {
                        Text(label)
                            .font(.solBody)
                            .foregroundStyle(Color.solForeground)
                    }
                    Spacer()
                    if let trailing {
                        Text(trailing)
                            .font(.solBodyBold)
                            .foregroundStyle(variant.color(progress: clampedProgress))
                    }
                }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: height)

                    Capsule()
                        .fill(variant.color(progress: clampedProgress))
                        .frame(width: max(0, geo.size.width * clampedProgress), height: height)
                        .shadow(color: variant.color(progress: clampedProgress).opacity(0.5), radius: 6, x: 0, y: 0)
                }
            }
            .frame(height: height)
        }
    }

    private var clampedProgress: Double {
        max(0, min(1, progress))
    }
}

#Preview {
    ZStack {
        Color.solCanvas.ignoresSafeArea()
        VStack(spacing: SolSpacing.md) {
            NeonProgressBar(progress: 0.91, variant: .warning, label: "Food budget", trailing: "91%")
            NeonProgressBar(progress: 0.61, variant: .success, label: "Transport", trailing: "61%")
            NeonProgressBar(progress: 0.28, variant: .info, label: "Monthly savings", trailing: "28%")
            NeonProgressBar(progress: 0.96, variant: .danger, label: "Danger zone", trailing: "96%")
            NeonProgressBar(progress: 0.5, variant: .automatic)
        }
        .padding(SolSpacing.lg)
    }
    .preferredColorScheme(.dark)
}
