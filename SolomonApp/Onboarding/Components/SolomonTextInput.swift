import SwiftUI

// MARK: - SolomonTextInput (Apple HIG strict — Faza 28)
//
// Wrapper minimal peste TextField/SecureField nativ:
//   - Icon prefix (SF Symbol)
//   - Background nativ thinMaterial
//   - Focus state cu accent solPrimary
//   - Standard 50pt height (≥ HIG tap target)
//
// În forma de Form/insetGrouped folosim TextField direct (NU acest wrapper).
// Acest wrapper e pentru ecrane de onboarding care NU sunt în List.

struct SolomonTextInput: View {

    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    var trailingButton: (icon: String, action: () -> Void)? = nil

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: SolSpacing.sm) {
            if let icon {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
            }

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(.body)
            .keyboardType(keyboardType)
            .focused($isFocused)
            .submitLabel(.done)
            .autocorrectionDisabled()

            if let tb = trailingButton {
                Button(action: tb.action) {
                    Image(systemName: tb.icon)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, SolSpacing.base)
        .frame(height: 50)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: SolRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: SolRadius.lg, style: .continuous)
                .stroke(isFocused ? Color.solPrimary : Color.clear, lineWidth: 1.5)
        )
        .animation(.smooth(duration: 0.2), value: isFocused)
    }
}

#Preview {
    @Previewable @State var name = ""
    @Previewable @State var search = ""

    ZStack {
        Color.solCanvas.ignoresSafeArea()
        VStack(spacing: SolSpacing.base) {
            SolomonTextInput(placeholder: "ex: Andrei", text: $name, icon: "person.fill")
            SolomonTextInput(placeholder: "Search...", text: $search, icon: "magnifyingglass")
        }
        .padding(SolSpacing.lg)
    }
    .preferredColorScheme(.dark)
}
