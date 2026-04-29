import SwiftUI
import SolomonCore

// MARK: - Ecran 3 — Venit (Apple HIG aligned)

struct OnboardingScreen3Income: View {
    @Environment(OnboardingState.self) var state: OnboardingState

    var body: some View {
        @Bindable var state = state
        ScrollView {
            VStack(alignment: .leading, spacing: SolSpacing.xxl) {

                VStack(alignment: .leading, spacing: SolSpacing.xs) {
                    Text("Câteva detalii financiare")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(Color.solForeground)
                    Text("Ne ajută să calculăm Safe to Spend cu acuratețe.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, SolSpacing.lg)

                // Salary
                VStack(alignment: .leading, spacing: SolSpacing.sm) {
                    Text("Cât câștigi lunar, aproximativ?")
                        .font(.headline)
                        .foregroundStyle(Color.solForeground)
                    Text("Net, în mână")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    salaryGrid
                        .padding(.top, SolSpacing.xs)
                }

                // Day picker
                VStack(alignment: .leading, spacing: SolSpacing.sm) {
                    Text("Pe ce dată intră salariul?")
                        .font(.headline)
                        .foregroundStyle(Color.solForeground)

                    DayOfMonthPicker(selectedDay: $state.paydayDay)
                        .padding(SolSpacing.base)
                        .solCard()
                }

                // Secondary income
                VStack(alignment: .leading, spacing: SolSpacing.sm) {
                    SolomonToggle(
                        title: "Ai venituri extra?",
                        subtitle: "Freelance, chirii, etc.",
                        isOn: $state.hasSecondaryIncome
                    )

                    if state.hasSecondaryIncome {
                        VStack(alignment: .leading, spacing: SolSpacing.xs) {
                            Text("Aproximativ cât? (RON / lună)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            SolomonTextInput(
                                placeholder: "ex: 1500",
                                text: Binding(
                                    get: {
                                        state.secondaryIncomeApprox > 0
                                            ? "\(state.secondaryIncomeApprox)"
                                            : ""
                                    },
                                    set: { state.secondaryIncomeApprox = Int($0) ?? 0 }
                                ),
                                icon: "banknote"
                            )
                            .keyboardType(.numberPad)
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.85), value: state.hasSecondaryIncome)

                Spacer(minLength: SolSpacing.lg)
            }
            .padding(.horizontal, SolSpacing.lg)
            .padding(.bottom, SolSpacing.xxxl)
        }
        .safeAreaInset(edge: .bottom) {
            SolomonButton("Continuă", icon: "arrow.right") {
                Haptics.medium()
                state.next()
            }
            .opacity(state.canProceedFromCurrentStep ? 1 : 0.4)
            .disabled(!state.canProceedFromCurrentStep)
            .padding(.horizontal, SolSpacing.lg)
            .padding(.vertical, SolSpacing.base)
            .background(.ultraThinMaterial)
        }
    }

    @ViewBuilder
    private var salaryGrid: some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible())]
        LazyVGrid(columns: columns, spacing: SolSpacing.sm) {
            salaryButton(.under3k, label: "<3.000")
            salaryButton(.range3to5, label: "3-5.000")
            salaryButton(.range5to8, label: "5-8.000")
            salaryButton(.range8to15, label: "8-15.000")
            salaryButton(.over15k, label: ">15.000")
        }
    }

    @ViewBuilder
    private func salaryButton(_ range: SalaryRange, label: String) -> some View {
        let isSelected = state.salaryRange == range
        Button {
            Haptics.selection()
            state.salaryRange = range
        } label: {
            HStack {
                Text(label)
                    .font(.body.weight(isSelected ? .semibold : .regular))
                Spacer()
                Text("RON")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(isSelected ? Color.solPrimary : Color.solForeground)
            .padding(.horizontal, SolSpacing.base)
            .frame(height: 50)
            .background(isSelected ? Color.solPrimary.opacity(0.12) : Color.solCard)
            .clipShape(RoundedRectangle(cornerRadius: SolRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: SolRadius.lg)
                    .stroke(isSelected ? Color.solPrimary : Color.solBorder, lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        Color.solCanvas.ignoresSafeArea()
        OnboardingScreen3Income()
            .environment(OnboardingState())
    }
    .preferredColorScheme(.dark)
}
