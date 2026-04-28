import SwiftUI

// MARK: - Chip components (Apple HIG strict — Faza 28)
//
// Folosesc native Button cu `.borderedProminent` / `.bordered` styles + `.tint(.mint)`.

// MARK: - SelectableChip (single-select)

struct SelectableChip: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        if isSelected {
            Button(action: action) { label }
                .buttonStyle(.borderedProminent)
                .tint(.mint)
                .controlSize(.regular)
                .sensoryFeedback(.selection, trigger: isSelected)
        } else {
            Button(action: action) { label }
                .buttonStyle(.bordered)
                .tint(.mint)
                .controlSize(.regular)
                .sensoryFeedback(.selection, trigger: isSelected)
        }
    }

    @ViewBuilder
    private var label: some View {
        HStack(spacing: SolSpacing.xs) {
            if let icon {
                Image(systemName: icon)
                    .font(.footnote.weight(.medium))
            }
            Text(title)
                .font(.subheadline)
        }
    }
}

// MARK: - MultiSelectChip

struct MultiSelectChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        if isSelected {
            Button(action: action) { label }
                .buttonStyle(.borderedProminent)
                .tint(.mint)
                .controlSize(.regular)
        } else {
            Button(action: action) { label }
                .buttonStyle(.bordered)
                .tint(.mint)
                .controlSize(.regular)
        }
    }

    @ViewBuilder
    private var label: some View {
        HStack(spacing: SolSpacing.xs) {
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.footnote.weight(.bold))
            }
            Text(title)
                .font(.subheadline)
        }
    }
}

// MARK: - FeatureChip (display-only — Welcome)

struct FeatureChip: View {
    let title: String
    var icon: String = "checkmark"

    var body: some View {
        Label(title, systemImage: icon)
            .font(.subheadline)
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, SolSpacing.base)
            .padding(.vertical, SolSpacing.md)
            .background(.regularMaterial, in: Capsule())
    }
}

#Preview {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        VStack(spacing: SolSpacing.base) {
            HStack {
                SelectableChip(title: "<3.000", isSelected: false) {}
                SelectableChip(title: "3-5.000", isSelected: true) {}
            }
            HStack {
                MultiSelectChip(title: "Vacanță", isSelected: true) {}
                MultiSelectChip(title: "Datorii", isSelected: false) {}
            }
            FeatureChip(title: "Învăț din comportament", icon: "brain.head.profile")
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
