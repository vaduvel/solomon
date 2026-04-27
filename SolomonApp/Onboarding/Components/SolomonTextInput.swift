import SwiftUI

// MARK: - SolomonTextInput (DS v1.0)
//
// Text input conform Penny DS v1.0:
//   - bg: #1C2230 (solCard)
//   - border: rgba(255,255,255,0.08)
//   - focus border: rgba(0,255,135,0.4) — mint glow
//   - h-14, rounded-2xl, text-15px

struct SolomonTextInput: View {

    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    var trailingButton: (icon: String, action: () -> Void)? = nil

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: SolSpacing.md) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.solMuted)
            }

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(.solBody)
            .foregroundStyle(Color.solForeground)
            .keyboardType(keyboardType)
            .focused($isFocused)
            .submitLabel(.done)
            .autocorrectionDisabled()

            if let tb = trailingButton {
                Button(action: tb.action) {
                    Image(systemName: tb.icon)
                        .font(.system(size: 16))
                        .foregroundStyle(Color.solMuted)
                }
            }
        }
        .padding(.horizontal, SolSpacing.base)
        .frame(height: 56)
        .background(Color.solCard)
        .clipShape(RoundedRectangle(cornerRadius: SolRadius.xxl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: SolRadius.xxl, style: .continuous)
                .stroke(
                    isFocused ? Color.solPrimary.opacity(0.4) : Color.solBorder,
                    lineWidth: isFocused ? 1.5 : 1
                )
        )
        .shadow(
            color: isFocused ? Color.solPrimary.opacity(0.2) : Color.clear,
            radius: 12, x: 0, y: 0
        )
        .animation(.easeOut(duration: 0.2), value: isFocused)
    }
}

#Preview {
    @Previewable @State var name = ""
    @Previewable @State var search = "Bolt"

    ZStack {
        Color.solCanvas.ignoresSafeArea()
        VStack(spacing: SolSpacing.base) {
            SolomonTextInput(placeholder: "Ex: Monthly income...", text: $name)
            SolomonTextInput(placeholder: "Search transactions...", text: $search, icon: "magnifyingglass")
        }
        .padding(SolSpacing.lg)
    }
    .preferredColorScheme(.dark)
}
