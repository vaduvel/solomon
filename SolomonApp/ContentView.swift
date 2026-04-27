import SwiftUI

// MARK: - ContentView
//
// Root view — TabView cu 4 tab-uri Solomon.
// Personalizare tab bar: icon mint pentru tab activ, canvas background.

struct ContentView: View {

    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {

            TodayView()
                .tabItem {
                    Label("Azi", systemImage: selectedTab == 0 ? "house.fill" : "house")
                }
                .tag(0)

            AnalysisView()
                .tabItem {
                    Label("Analiză", systemImage: selectedTab == 1 ? "chart.bar.fill" : "chart.bar")
                }
                .tag(1)

            WalletView()
                .tabItem {
                    Label("Portofel", systemImage: selectedTab == 2 ? "wallet.bifold.fill" : "wallet.bifold")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Setări", systemImage: selectedTab == 3 ? "gearshape.fill" : "gearshape")
                }
                .tag(3)
        }
        .tint(Color.solPrimary)
        .toolbarBackground(Color.solCard, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
