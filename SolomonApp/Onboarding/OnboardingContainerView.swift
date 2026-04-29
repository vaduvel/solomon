import SwiftUI
import os
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

    let onFinish: () -> Void

    var body: some View {
        ZStack {
            Color.solCanvas.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar (progress + back)
                topBar
                    .padding(.horizontal, SolSpacing.screenHorizontal)
                    .padding(.top, SolSpacing.sm)

                // Current screen with slide transition
                ZStack {
                    currentScreen
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                        .id(state.currentStep)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .preferredColorScheme(.dark)
        .environment(state)
    }

    // MARK: - Top bar

    @ViewBuilder
    private var topBar: some View {
        HStack {
            Button {
                state.back()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.solMuted)
                    .frame(width: 36, height: 36)
                    .background(Color.solCard)
                    .clipShape(Circle())
            }
            .opacity(state.canGoBack ? 1 : 0)
            .disabled(!state.canGoBack)

            Spacer()

            OnboardingStepDots(
                totalSteps: OnboardingState.totalSteps,
                currentStep: state.currentStep
            )

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
            // NU marcăm completed: userul rămâne în onboarding și poate apăsa Continuă din nou.
            Logger.onboarding.error("Onboarding save failed: \(error.localizedDescription, privacy: .public)")
            // Pentru moment: tot apelăm onFinish ca să nu blocăm — dar fără markCompleted,
            // următorul launch va re-arăta onboarding-ul.
            onFinish()
        }
    }
}

#Preview {
    OnboardingContainerView(onFinish: {})
}
