import SwiftUI

// MARK: - StandardSheet
//
// Wrapper modifier care aplică pattern-ul HIG standard pentru sheets:
//   - .presentationDetents([.medium, .large]) (configurable)
//   - .presentationDragIndicator(.visible)
//   - .presentationBackground(Color.solCanvas) — Solomon dark
//   - Optional: .interactiveDismissDisabled() pentru sheet blocant
//
// Folosit ca modifier pe orice content de sheet:
//   .sheet(isPresented: $show) {
//       MyContent().solStandardSheet()
//   }

public extension View {

    /// Sheet standard Solomon: medium + large detents, drag visible, canvas bg.
    func solStandardSheet(
        detents: Set<PresentationDetent> = [.medium, .large],
        dragVisible: Bool = true,
        interactiveDismissDisabled: Bool = false
    ) -> some View {
        self
            .presentationDetents(detents)
            .presentationDragIndicator(dragVisible ? .visible : .hidden)
            .presentationBackground(Color.solCanvas)
            .interactiveDismissDisabled(interactiveDismissDisabled)
    }

    /// Sheet large-only (acțiuni majore — onboarding-like)
    func solLargeSheet(interactiveDismissDisabled: Bool = false) -> some View {
        self
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
            .presentationBackground(Color.solCanvas)
            .interactiveDismissDisabled(interactiveDismissDisabled)
    }

    /// Sheet medium-only (acțiuni rapide — quick add)
    func solMediumSheet() -> some View {
        self
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color.solCanvas)
    }
}
