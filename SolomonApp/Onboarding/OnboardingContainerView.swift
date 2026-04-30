import SwiftUI
import os
import SolomonCore
import SolomonStorage

// MARK: - OnboardingContainerView
//
// Orchestrator pentru cele 9 ecrane. Controlează:
//   - Progress dots top
//   - Back button (când e relevant)
//   - Tranziție spring slide între ecrane
//   - Save final → markCompleted → trigger TabView main app

struct OnboardingContainerView: View {

    @State private var state = OnboardingState()
    @State private var saveError: String?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var didAppear: Bool = false
    @State private var dotsPulse: Bool = false
    @State private var previousStep: Int = 0

    let onFinish: () -> Void

    var body: some View {
        ZStack {
            Color.solCanvas.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar (progress + back)
                topBar
                    .opacity(didAppear ? 1 : 0)
                    .offset(y: reduceMotion ? 0 : (didAppear ? 0 : -6))
                    .animation(.spring(response: 0.5, dampingFraction: 0.9), value: didAppear)
                    .padding(.horizontal, SolSpacing.screenHorizontal)
                    .padding(.top, SolSpacing.sm)

                // Current screen with slide transition
                ZStack {
                    currentScreen
                        .transition(
                            reduceMotion ? .opacity : .asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            )
                        )
                        .animation(.spring(response: 0.6, dampingFraction: 0.9), value: state.currentStep)
                        .id(state.currentStep)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .preferredColorScheme(.dark)
        .environment(state)
        .alert("Salvarea profilului a eșuat", isPresented: errorAlertBinding, presenting: saveError) { _ in
            Button("Încearcă din nou") {
                handleFinish()
            }
            Button("Anulează", role: .cancel) { saveError = nil }
        } message: { error in
            Text("Solomon nu a putut salva datele tale (\(error)). Apasă \"Încearcă din nou\" — fără asta, datele introduse se pierd.")
        }
        .onAppear {
            didAppear = true
            previousStep = state.currentStep
        }
        .onDisappear {
            didAppear = false
        }
        .onChange(of: state.currentStep) { _, newStep in
            if !reduceMotion {
                dotsPulse = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                    dotsPulse = false
                }
            }
            Haptics.light()
            previousStep = newStep
        }
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )
    }

    // MARK: - Top bar

    @ViewBuilder
    private var topBar: some View {
        HStack {
            Button {
                Haptics.light()
                state.back()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.solMuted)
                    .frame(width: 36, height: 36)
                    .background(Color.solCard)
                    .clipShape(Circle())
            }
            .pressEffect(scale: reduceMotion ? 1 : 0.96)
            .opacity(state.canGoBack ? 1 : 0)
            .disabled(!state.canGoBack)

            Spacer()

            OnboardingStepDots(
                totalSteps: OnboardingState.totalSteps,
                currentStep: state.currentStep
            )
            .scaleEffect(reduceMotion ? 1 : (dotsPulse ? 1.03 : 1.0))
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: dotsPulse)
            .animation(.spring(response: 0.45, dampingFraction: 0.85), value: state.currentStep)

            Spacer()

            // Spațiu echivalent cu butonul back, pentru centrare progresie
            Color.clear.frame(width: 36, height: 36)
        }
    }

    // MARK: - Screen routing

    @ViewBuilder
    private var currentScreen: some View {
        switch state.currentStep {
        case 0: OnboardingScreen1Welcome()
        case 1: OnboardingScreen2Identity()
        case 2: OnboardingScreen3Income()
        case 3: OnboardingScreen4Bank()
        case 4: OnboardingScreen5Obligations()
        case 5: OnboardingScreen6Goal()
        case 6: OnboardingScreen7Permissions()
        case 7: OnboardingScreen8Processing()
        case 8: OnboardingScreen9WowMoment(onFinish: handleFinish)
        default: OnboardingScreen1Welcome()
        }
    }

    // MARK: - Final save

    private func handleFinish() {
        // FAZA A5: salvare ATOMICĂ via OnboardingPersistence.
        // Dacă pică Core Data: rollback automat, NU mai marcăm completed → userul
        // poate retry-ui (alternativ ar fi un onboarding zombie cu date corupte).
        let context = SolomonPersistenceController.shared.container.viewContext
        let persistence = OnboardingPersistence(context: context)

        do {
            try state.persistFinalProfile(onboardingPersistence: persistence)
            onFinish()
        } catch {
            // Save eșuat — context.rollback() a curățat deja toate scrierile parțiale.
            // NU marcăm completed și NU intrăm în app — afișăm alert cu retry.
            // Înainte: ajungeam în main app cu profil gol → confuzie totală pentru user.
            Logger.onboarding.error("Onboarding save failed: \(error.localizedDescription, privacy: .public)")
            saveError = error.localizedDescription
        }
    }
}

private struct PressEffect: ViewModifier {
    @GestureState private var isPressed = false
    let scale: CGFloat

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scale : 1)
            .opacity(isPressed ? 0.98 : 1)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .updating($isPressed) { _, state, _ in
                        state = true
                    }
            )
    }
}

private extension View {
    func pressEffect(scale: CGFloat = 0.98) -> some View {
        modifier(PressEffect(scale: scale))
    }
}

#Preview {
    OnboardingContainerView(onFinish: {})
}
