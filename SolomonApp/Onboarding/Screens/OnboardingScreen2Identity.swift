import SwiftUI
import SolomonCore

// MARK: - Ecran 2 — Identitate (Solomon DS — editorial premium)
//
// Pattern preluat din Solomon DS / goal-edit.html:
//   - Field label uppercase tracked 0.5em (mint-muted)
//   - Glass input cu border 1px white/8 + focus mint
//   - SolPill row pentru selecții finite (age range, addressing)

struct OnboardingScreen2Identity: View {
    @Environment(OnboardingState.self) var state: OnboardingState
    @FocusState private var nameFocused: Bool

    var body: some View {
        @Bindable var state = state

        ZStack {
            MeshBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: SolSpacing.xxl) {

                    // Header — eyebrow + titlu mare + subtitle
                    VStack(alignment: .leading, spacing: 10) {
                        Text("PASUL 2")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.solMintLight)
                            .tracking(1.4)
                            .textCase(.uppercase)

                        Text("Cum te cheamă?")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundStyle(Color.white)
                            .tracking(-0.8)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Ca să-ți pot vorbi pe limba ta — și să-ți recunosc vocea când îți răspund.")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.white.opacity(0.55))
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, SolSpacing.lg)

                    // Field — Numele tău
                    fieldGroup(label: "NUMELE TĂU") {
                        glassTextField(
                            text: $state.name,
                            placeholder: "ex: Andrei",
                            isFocused: nameFocused
                        )
                        .focused($nameFocused)
                    }

                    // Field — Vârstă
                    fieldGroup(label: "VÂRSTĂ") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(AgeRange.allCases, id: \.self) { range in
                                    SolPill(
                                        range.displayNameRO,
                                        isActive: state.ageRange == range
                                    ) {
                                        state.ageRange = range
                                    }
                                }
                            }
                        }
                        .scrollClipDisabled()
                    }

                    // Field — Cum îți zicem?
                    fieldGroup(label: "CUM ÎȚI ZICEM?") {
                        HStack(spacing: 8) {
                            SolPill(
                                "Pe nume (tu)",
                                isActive: state.addressing == .tu
                            ) {
                                state.addressing = .tu
                            }
                            SolPill(
                                "Formal (dvs.)",
                                isActive: state.addressing == .dumneavoastra
                            ) {
                                state.addressing = .dumneavoastra
                            }
                            Spacer(minLength: 0)
                        }
                    }

                    Spacer(minLength: SolSpacing.xxxl)
                }
                .padding(.horizontal, SolSpacing.lg)
                .padding(.bottom, SolSpacing.xxxl)
            }
            .scrollDismissesKeyboard(.immediately)
        }
        .safeAreaInset(edge: .bottom) {
            SolPrimaryButton("Continuă", fullWidth: true) {
                state.next()
            }
            .opacity(canContinue ? 1 : 0.4)
            .disabled(!canContinue)
            .padding(.horizontal, SolSpacing.lg)
            .padding(.vertical, SolSpacing.base)
            .background(.ultraThinMaterial)
        }
        .onAppear {
            Task {
                try? await Task.sleep(for: .milliseconds(300))
                nameFocused = true
            }
        }
    }

    // MARK: - Helpers

    private var canContinue: Bool {
        !state.name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    @ViewBuilder
    private func fieldGroup<Content: View>(
        label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.45))
                .tracking(0.55) // ~0.5em la 11pt
                .textCase(.uppercase)
            content()
        }
    }

    @ViewBuilder
    private func glassTextField(
        text: Binding<String>,
        placeholder: String,
        isFocused: Bool
    ) -> some View {
        TextField("", text: text, prompt: Text(placeholder).foregroundColor(Color.white.opacity(0.30)))
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .font(.system(size: 17, weight: .medium))
            .foregroundStyle(Color.white)
            .tracking(-0.2)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        isFocused
                            ? Color.solMintExact.opacity(0.45)
                            : Color.white.opacity(0.08),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: isFocused ? Color.solMintExact.opacity(0.18) : .clear,
                radius: 12
            )
            .animation(.easeOut(duration: 0.18), value: isFocused)
    }
}

#Preview {
    OnboardingScreen2Identity()
        .environment(OnboardingState())
        .preferredColorScheme(.dark)
}
