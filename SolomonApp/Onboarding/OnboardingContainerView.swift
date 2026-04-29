import SwiftUI
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
        let context = SolomonPersistenceController.shared.container.viewContext
        let userRepo = CoreDataUserProfileRepository(context: context)
        let oblRepo = CoreDataObligationRepository(context: context)
        let goalRepo = CoreDataGoalRepository(context: context)

        do {
            try state.persistFinalProfile(
                userProfileRepository: userRepo,
                obligationRepository: oblRepo,
                goalRepository: goalRepo
            )
            onFinish()
        } catch {
            // Pe error: marcăm completed oricum, ca să nu blocăm userul.
            // În producție: log la analytics + retry mechanism.
            print("⚠️ Onboarding save failed: \(error.localizedDescription)")
            OnboardingState.markCompleted()
            onFinish()
        }
    }
}

#Preview {
    OnboardingContainerView(onFinish: {})
}
