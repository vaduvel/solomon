import SwiftUI

// MARK: - TodayViewModel
//
// ViewModel pentru TodayView.
// Faza 10: date hardcodate (mock). Faza 11+: conectat la SolomonStorage + SolomonMoments.

@MainActor
final class TodayViewModel: ObservableObject {

    // MARK: - Published state

    @Published var currentMoment: DisplayMoment?
    @Published var recentMoments: [DisplayMoment] = []
    @Published var safeToSpendFormatted: String = "..."
    @Published var perDayFormatted: String?
    @Published var greetingText: String = ""
    @Published var hasUnreadAlert: Bool = false
    @Published var showCanIAfford: Bool = false

    // MARK: - Load (mock data pentru Faza 10)

    func load() async {
        // Mock: va fi înlocuit cu SolomonStorage + SolomonMoments în Faza 11
        greetingText = greetingForCurrentHour()
        safeToSpendFormatted = "1.247 RON"
        perDayFormatted = "≈ 83 RON/zi · 15 zile rămase"
        hasUnreadAlert = false

        // Moment curent mock
        currentMoment = .previewCanIAfford

        // Feed recent mock
        recentMoments = [
            .previewPayday,
            .previewSpiral
        ]
    }

    // MARK: - Helpers

    private func greetingForCurrentHour() -> String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12:  return "Bună dimineața 👋"
        case 12..<18: return "Bună ziua 👋"
        case 18..<22: return "Bună seara 👋"
        default:      return "Salut 👋"
        }
    }
}
