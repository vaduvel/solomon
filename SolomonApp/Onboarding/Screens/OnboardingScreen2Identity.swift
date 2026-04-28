import SwiftUI
import SolomonCore

// MARK: - Ecran 2 — Identitate (Apple HIG aligned)

struct OnboardingScreen2Identity: View {
    @EnvironmentObject var state: OnboardingState
    @FocusState private var nameFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SolSpacing.xxl) {

                VStack(alignment: .leading, spacing: SolSpacing.xs) {
                    Text("Hai să ne cunoaștem")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(Color.solForeground)
                    Text("Cum te cheamă?")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                // Name input
                SolomonTextInput(
                    placeholder: "ex: Andrei",
                    text: $state.name,
                    icon: "person.fill"
                )
                .focused($nameFocused)

                // Addressing picker — segment control HIG
                VStack(alignment: .leading, spacing: SolSpacing.sm) {
                    Text("Cum vrei să-ți zic?")
                        .solSectionHeader()

                    Picker("Adresare", selection: $state.addressing) {
                        Text("Pe nume (tu)").tag(Addressing.tu)
                        Text("Formal (dvs.)").tag(Addressing.dumneavoastra)
                    }
                    .pickerStyle(.segmented)
                    .tint(Color.solPrimary)
                }

                Spacer(minLength: SolSpacing.xxxl)
            }
            .padding(.horizontal, SolSpacing.lg)
            .padding(.top, SolSpacing.lg)
        }
        .scrollDismissesKeyboard(.immediately)
        .safeAreaInset(edge: .bottom) {
            SolomonButton("Continuă", icon: "arrow.right") {
                Haptics.medium()
                state.next()
            }
            .opacity(state.canProceedFromCurrentStep ? 1 : 0.4)
            .disabled(!state.canProceedFromCurrentStep)
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
}

#Preview {
    ZStack {
        Color.solCanvas.ignoresSafeArea()
        OnboardingScreen2Identity()
            .environmentObject(OnboardingState())
    }
    .preferredColorScheme(.dark)
}
