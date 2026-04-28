import SwiftUI

// MARK: - SolomonToggle (Apple HIG strict — Faza 28)
//
// Toggle nativ iOS cu styling Penny tint. Folosit în afara Form/List
// (în Form folosim Toggle() direct).

struct SolomonToggle: View {
    let title: String
    var subtitle: String? = nil
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(Color.solForeground)
                if let subtitle {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .tint(Color.solPrimary)
        .padding(SolSpacing.base)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: SolRadius.lg, style: .continuous))
    }
}

#Preview {
    @Previewable @State var on = true
    @Previewable @State var off = false

    ZStack {
        Color.solCanvas.ignoresSafeArea()
        VStack(spacing: SolSpacing.md) {
            SolomonToggle(title: "Auto-save", subtitle: "Round up transactions", isOn: $on)
            SolomonToggle(title: "Venituri extra", isOn: $off)
        }
        .padding(SolSpacing.lg)
    }
    .preferredColorScheme(.dark)
}
