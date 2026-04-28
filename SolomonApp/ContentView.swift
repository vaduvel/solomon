import SwiftUI

// MARK: - ContentView (HIG aligned TabView)
//
// Pattern HIG: TabView nativ cu Label(systemImage:) per tab.
// Tint = solPrimary (mint), bg = nativ adaptive material.

struct ContentView: View {

    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {

            TodayView()
                .tabItem {
                    Label("Azi", systemImage: "house.fill")
                }
                .tag(0)

            AnalysisView()
                .tabItem {
                    Label("Analiză", systemImage: "chart.bar.fill")
                }
                .tag(1)

            WalletView()
                .tabItem {
                    Label("Portofel", systemImage: "wallet.bifold.fill")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Setări", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(Color.solPrimary)
        .onChange(of: selectedTab) { _, _ in Haptics.selection() }
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
