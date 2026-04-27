import SwiftUI

// MARK: - DayOfMonthPicker
//
// Hero number central + grid 7x5 cu zile 1-31.
// Folosit în Ecran 3 onboarding (data salariu).

struct DayOfMonthPicker: View {

    @Binding var selectedDay: Int  // 1...31

    var body: some View {
        VStack(spacing: SolSpacing.lg) {
            // Hero number
            VStack(spacing: 4) {
                Text("\(selectedDay)")
                    .font(.solDisplay)
                    .foregroundStyle(LinearGradient.solPrimaryCTA)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text(selectedDay == 1 ? "ziua salariului" : "data salariului")
                    .font(.solCaption)
                    .foregroundStyle(Color.solMuted)
            }

            // 7-column grid (Mo Tu We Th Fr Sa Su style)
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7),
                spacing: 6
            ) {
                ForEach(1...31, id: \.self) { day in
                    DayCell(
                        day: day,
                        isSelected: selectedDay == day
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedDay = day
                        }
                    }
                }
            }
        }
    }
}

private struct DayCell: View {
    let day: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(day)")
                .font(.system(size: 15, weight: isSelected ? .semibold : .regular, design: .default))
                .foregroundStyle(isSelected ? Color.solCanvas : Color.solForeground)
                .frame(maxWidth: .infinity, minHeight: 38)
                .background(
                    RoundedRectangle(cornerRadius: SolRadius.md, style: .continuous)
                        .fill(isSelected ? AnyShapeStyle(LinearGradient.solPrimaryCTA) : AnyShapeStyle(Color.solCard))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: SolRadius.md, style: .continuous)
                        .stroke(Color.solBorder, lineWidth: isSelected ? 0 : 1)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    @Previewable @State var day = 28

    ZStack {
        Color.solCanvas.ignoresSafeArea()
        DayOfMonthPicker(selectedDay: $day)
            .padding(SolSpacing.lg)
    }
    .preferredColorScheme(.dark)
}
