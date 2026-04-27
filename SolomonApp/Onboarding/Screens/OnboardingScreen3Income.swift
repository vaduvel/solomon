import SwiftUI
import SolomonCore

// MARK: - Ecran 3 — Venit (30 sec)
//
// Conform spec §11 ecran 3:
//   - Întrebare: "Cât câștigi lunar, aproximativ?"
//   - Chips: <3.000 / 3-5.000 / 5-8.000 / 8-15.000 / >15.000 RON
//   - "Pe ce dată intră salariul?" (calendar 1-31)
//   - Toggle: "Ai venituri extra? [Da/Nu]"

struct OnboardingScreen3Income: View {
    @EnvironmentObject var state: OnboardingState

    var body: some View {
        ScrollView {
            VStack(spacing: SolSpacing.xl) {
                // Header
                VStack(alignment: .leading, spacing: SolSpacing.sm) {
                    Text("Câteva detalii financiare")
                        .font(.solH1)
                        .foregroundStyle(Color.solForeground)
                    Text("Ne ajută să calculăm Safe to Spend cu acuratețe.")
                        .font(.solBody)
                        .foregroundStyle(Color.solMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, SolSpacing.lg)

                // Salariu
                VStack(alignment: .leading, spacing: SolSpacing.sm) {
                    Text("Cât câștigi lunar, aproximativ?")
                        .font(.solBodyBold)
                        .foregroundStyle(Color.solForeground)
                    Text("Net, în mână")
                        .font(.solCaption)
                        .foregroundStyle(Color.solMuted)

                    VStack(spacing: SolSpacing.sm) {
                        salaryRow([.under3k, .range3to5])
                        salaryRow([.range5to8, .range8to15])
                        salaryRow([.over15k])
                    }
                }

                // Data salariu
                VStack(alignment: .leading, spacing: SolSpacing.sm) {
                    Text("Pe ce dată intră salariul?")
                        .font(.solBodyBold)
                        .foregroundStyle(Color.solForeground)

                    DayOfMonthPicker(selectedDay: $state.paydayDay)
                        .padding(SolSpacing.base)
                        .solCard()
                }

                // Venit extra
                SolomonToggle(
                    title: "Ai venituri extra?",
                    subtitle: "Freelance, chirii, etc.",
                    isOn: $state.hasSecondaryIncome
                )

                Spacer().frame(height: SolSpacing.lg)

                SolomonButton("Continuă", icon: "arrow.right") {
                    state.next()
                }
                .opacity(state.canProceedFromCurrentStep ? 1 : 0.4)
                .disabled(!state.canProceedFromCurrentStep)
            }
            .padding(.horizontal, SolSpacing.screenHorizontal)
            .padding(.bottom, SolSpacing.xl)
        }
    }

    private func salaryRow(_ ranges: [SalaryRange]) -> some View {
        HStack(spacing: SolSpacing.sm) {
            ForEach(ranges, id: \.self) { range in
                SelectableChip(
                    title: salaryLabel(range),
                    isSelected: state.salaryRange == range
                ) {
                    state.salaryRange = range
                }
            }
            Spacer()
        }
    }

    private func salaryLabel(_ range: SalaryRange) -> String {
        switch range {
        case .under3k:    return "<3.000"
        case .range3to5:  return "3-5.000"
        case .range5to8:  return "5-8.000"
        case .range8to15: return "8-15.000"
        case .over15k:    return ">15.000"
        }
    }
}

#Preview {
    ZStack {
        Color.solCanvas.ignoresSafeArea()
        OnboardingScreen3Income()
            .environmentObject(OnboardingState())
    }
    .preferredColorScheme(.dark)
}
