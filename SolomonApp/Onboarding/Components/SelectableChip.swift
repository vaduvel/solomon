import SwiftUI

// MARK: - SelectableChip & MultiSelectChip (DS v1.0)
//
// Chip-uri pill cu single/multi-select.
// Selected: bg solPrimary opacity 0.15 + border solPrimary + text solPrimary
// Unselected: bg transparent + border solBorder + text solMuted

// MARK: - Single-select chip

struct SelectableChip: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: SolSpacing.xs) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .medium))
                }
                Text(title)
                    .font(.solBody)
            }
            .foregroundStyle(isSelected ? Color.solPrimary : Color.solForeground)
            .padding(.horizontal, SolSpacing.base)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? Color.solPrimary.opacity(0.12) : Color.clear)
            )
            .overlay(
                Capsule()
                    .stroke(
                        isSelected ? Color.solPrimary : Color.white.opacity(0.15),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: isSelected)
    }
}

// MARK: - Multi-select chip (with checkmark)

struct MultiSelectChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: SolSpacing.xs) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.solPrimary)
                }
                Text(title)
                    .font(.solBody)
                    .foregroundStyle(isSelected ? Color.solPrimary : Color.solForeground)
            }
            .padding(.horizontal, SolSpacing.base)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? Color.solPrimary.opacity(0.12) : Color.clear)
            )
            .overlay(
                Capsule()
                    .stroke(
                        isSelected ? Color.solPrimary : Color.white.opacity(0.15),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: isSelected)
    }
}

// MARK: - Feature chip (with leading checkmark — used in welcome screen 1)

struct FeatureChip: View {
    let title: String
    var icon: String = "checkmark.circle.fill"

    var body: some View {
        HStack(spacing: SolSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Color.solPrimary)
            Text(title)
                .font(.solBody)
                .foregroundStyle(Color.solForeground)
            Spacer()
        }
        .padding(.horizontal, SolSpacing.base)
        .padding(.vertical, SolSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.solCard)
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(Color.solBorder, lineWidth: 1)
        )
    }
}

#Preview {
    ZStack {
        Color.solCanvas.ignoresSafeArea()
        VStack(spacing: SolSpacing.base) {
            HStack {
                SelectableChip(title: "<3.000", isSelected: false) {}
                SelectableChip(title: "3-5.000", isSelected: true) {}
                SelectableChip(title: "5-8.000", isSelected: false) {}
            }
            HStack {
                MultiSelectChip(title: "Vacanță", isSelected: true) {}
                MultiSelectChip(title: "Datorii", isSelected: false) {}
            }
            FeatureChip(title: "Învăț din comportamentul tău")
            FeatureChip(title: "Îți arăt ce să faci")
            FeatureChip(title: "Fără judecăți")
        }
        .padding(SolSpacing.lg)
    }
    .preferredColorScheme(.dark)
}
