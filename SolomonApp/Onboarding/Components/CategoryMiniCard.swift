import SwiftUI

// MARK: - CategoryMiniCard (DS v1.0)
//
// Card mic cu ring progress + icon + label + amount.
// Folosit în Today/Analysis pentru categorii principale (Food, Transport, Social).
// Penny mockup: min-w-130px, ring SVG r=18, glassmorphism.

struct CategoryMiniCard: View {

    let icon: String
    let title: String
    let amountText: String        // ex: "680 RON"
    let progress: Double          // 0.0...1.0 (% din buget)
    let progressLabel: String?    // ex: "91%"
    let variant: IconContainer.Variant

    var body: some View {
        VStack(alignment: .leading, spacing: SolSpacing.sm) {
            // Ring progress + icon
            ZStack {
                Circle()
                    .stroke(variant.color.opacity(0.2), lineWidth: 3)
                    .frame(width: 44, height: 44)

                Circle()
                    .trim(from: 0, to: clampedProgress)
                    .stroke(
                        variant.color,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: variant.color.opacity(0.6), radius: 4)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(variant.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.solCaption)
                    .foregroundStyle(Color.solMuted)
                Text(amountText)
                    .font(.solMonoMD)
                    .foregroundStyle(Color.solForeground)
            }

            if let progressLabel {
                LabelBadge(title: progressLabel, color: variant.color)
            }
        }
        .padding(SolSpacing.base)
        .frame(minWidth: 130, alignment: .leading)
        .solCard()
    }

    private var clampedProgress: Double {
        max(0, min(1, progress))
    }
}

#Preview {
    ZStack {
        Color.solCanvas.ignoresSafeArea()
        HStack(spacing: SolSpacing.sm) {
            CategoryMiniCard(
                icon: "bag.fill",
                title: "Food",
                amountText: "680 RON",
                progress: 0.91,
                progressLabel: "91%",
                variant: .warn
            )
            CategoryMiniCard(
                icon: "bolt.fill",
                title: "Transport",
                amountText: "490 RON",
                progress: 0.61,
                progressLabel: "OK",
                variant: .neon
            )
            CategoryMiniCard(
                icon: "music.note",
                title: "Social",
                amountText: "320 RON",
                progress: 0.28,
                progressLabel: "OK",
                variant: .cyan
            )
        }
        .padding(SolSpacing.lg)
    }
    .preferredColorScheme(.dark)
}
