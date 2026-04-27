import SwiftUI
import SolomonStorage

// MARK: - SolomonApp
//
// Entry point al aplicației Solomon iOS.
// Setează forced dark mode și accent mint din design system.
// Gestionează URL scheme `solomon://` pentru ingestia notificărilor bancare.

@main
struct SolomonApp: App {

    // MARK: - Dependencies

    private let persistence = PersistenceController.shared

    // MARK: - Init

    init() {
        // Configurăm NotificationIngestionService cu repository-ul CoreData.
        let repo = CoreDataTransactionRepository(context: persistence.container.viewContext)
        NotificationIngestionService.shared.configure(repository: repo)
    }

    // MARK: - Scene

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)  // Solomon e AMOLED-first dark
                .onOpenURL { url in
                    // Procesează solomon://transaction?raw=...
                    NotificationIngestionService.shared.ingest(url: url)
                }
                .environment(\.managedObjectContext, persistence.container.viewContext)
        }
    }
}
