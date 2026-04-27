import SwiftUI

// MARK: - SolomonToggle (DS v1.0)
//
// Custom toggle/switch conform Penny DS — mint când ON.
// Layout: titlu + subtitle stânga, switch dreapta.

struct SolomonToggle: View {
    let title: String
    var subtitle: String? = nil
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .center, spacing: SolSpacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.solBodyBold)
                    .foregroundStyle(Color.solForeground)
                if let subtitle {
                    Text(subtitle)
                        .font(.solCaption)
                        .foregroundStyle(Color.solMuted)
                }
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color.solPrimary)
        }
        .padding(SolSpacing.base)
        .background(Color.solCard)
        .clipShape(RoundedRectangle(cornerRadius: SolRadius.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: SolRadius.xl, style: .continuous)
                .stroke(Color.solBorder, lineWidth: 1)
        )
    }
}

#Preview {
    @Previewable @State var on = true
    @Previewable @State var off = false

    ZStack {
        Color.solCanvas.ignoresSafeArea()
        VStack(spacing: SolSpacing.md) {
            SolomonToggle(
                title: "Auto-save enabled",
                subtitle: "Automatically round up transactions",
                isOn: $on
            )
            SolomonToggle(title: "Ai venituri extra?", isOn: $off)
        }
        .padding(SolSpacing.lg)
    }
    .preferredColorScheme(.dark)
}
