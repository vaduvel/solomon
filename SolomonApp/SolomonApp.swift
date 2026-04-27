import SwiftUI

// MARK: - SolomonApp
//
// Entry point al aplicației Solomon iOS.
// Setează forced dark mode și accent mint din design system.

@main
struct SolomonApp: App {

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)  // Solomon e AMOLED-first dark
        }
    }
}
