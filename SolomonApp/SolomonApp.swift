import SwiftUI
import SolomonStorage

// MARK: - SolomonApp
//
// Entry point al aplicației Solomon iOS.
// Decide între onboarding (first-run) și ContentView principal.
// Setează forced dark mode și configurează NotificationIngestionService.
// Înregistrează BGTaskScheduler handlers pentru momentele auto-declanșate.

@main
struct SolomonApp: App {

    // MARK: - Dependencies

    private let persistence = SolomonPersistenceController.shared

    // MARK: - Scene phase (pentru BGTask scheduling)

    @Environment(\.scenePhase) private var scenePhase

    // MARK: - First-run gate

    @State private var showOnboarding: Bool = !OnboardingState.hasCompletedOnboarding

    // MARK: - Init

    init() {
        // Configurăm NotificationIngestionService cu repository-ul CoreData.
        let repo = CoreDataTransactionRepository(context: persistence.container.viewContext)
        NotificationIngestionService.shared.configure(repository: repo)

        // Înregistrăm BGTask handlers (TREBUIE apelat înainte de prima scenă).
        BackgroundTaskService.shared.registerHandlers()
    }

    // MARK: - Scene

    var body: some Scene {
        WindowGroup {
            Group {
                if showOnboarding {
                    OnboardingContainerView {
                        // Onboarding complet → trigger main app
                        withAnimation(.easeInOut(duration: 0.4)) {
                            showOnboarding = false
                        }
                    }
                    .transition(.opacity)
                } else {
                    ContentView()
                        .preferredColorScheme(.dark)
                        .onOpenURL { url in
                            NotificationIngestionService.shared.ingest(url: url)
                        }
                        .environment(\.managedObjectContext, persistence.container.viewContext)
                        .transition(.opacity)
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .background {
                    // Planificăm background tasks când app intră în background.
                    Task { @MainActor in
                        BackgroundTaskService.shared.scheduleAll()
                    }
                }
            }
        }
    }
}
