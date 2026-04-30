import SwiftUI
import SolomonCore

// MARK: - Ecran 3 — Venit (Solomon DS · Claude Design v3)
//
// Layout:
//   - MeshBackground full-screen (mint/blue/violet)
//   - ScrollView VStack:
//       · Eyebrow "PASUL 3" + h-page "Cât câștigi lunar?"
//       · Subtitle muted
//       · Field "VENIT NET" — pills VERTICAL pentru SalaryRange.allCases
//       · Field "ZIUA SALARIULUI" — DayOfMonthPicker în glass container
//       · Toggle glass "Ai venit extra?" → state.hasSecondaryIncome
//       · (conditional) Field "SUMĂ EXTRA" TextField glass
//       · SolInsightCard(.mint) cu mesaj despre estimare
//   - Bottom safeArea: SolPrimaryButton fullWidth → state.next()

struct OnboardingScreen3Income: View {
    @Environment(OnboardingState.self) var state: OnboardingState
    @FocusState private var extraFocused: Bool

    var body: some View {
        @Bindable var state = state

        ZStack {
            MeshBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Eyebrow + title + subtitle
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PASUL 3")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.solMintLight)
                            .tracking(1.4)
                            .textCase(.uppercase)

                        Text("Cât câștigi lunar?")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(Color.white)
                            .tracking(-0.8)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Solomon are nevoie să știe ca să calculeze Safe to Spend")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(Color.white.opacity(0.55))
                            .tracking(-0.1)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 2)
                    }
                    .padding(.top, 8)

                    // Field — VENIT NET (vertical pills)
                    VStack(alignment: .leading, spacing: 10) {
                        fieldLabel("VENIT NET")

                        VStack(spacing: 8) {
                            ForEach(SalaryRange.allCases, id: \.self) { range in
                                salaryRow(range)
                            }
                        }
                    }

                    // Field — ZIUA SALARIULUI (glass container)
                    VStack(alignment: .leading, spacing: 10) {
                        fieldLabel("ZIUA SALARIULUI")

                        DayOfMonthPicker(selectedDay: $state.paydayDay)
                            .padding(SolSpacing.lg)
                            .background(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.035), Color.white.opacity(0.015)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .background(.ultraThinMaterial.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.white.opacity(0.07), lineWidth: 1)
                            )
                    }

                    // Toggle glass — Ai venit extra?
                    secondaryIncomeToggle(isOn: $state.hasSecondaryIncome)

                    // Conditional — SUMĂ EXTRA
                    if state.hasSecondaryIncome {
                        VStack(alignment: .leading, spacing: 10) {
                            fieldLabel("SUMĂ EXTRA")
                            extraIncomeField(amount: $state.secondaryIncomeApprox)
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // Solomon insight (when range selected)
                    if let range = state.salaryRange {
                        SolInsightCard(
                            icon: "sparkles",
                            label: "SOLOMON SUGEREAZĂ",
                            accent: .mint
                        ) {
                            Text(insightMessage(for: range, hasExtra: state.hasSecondaryIncome, extra: state.secondaryIncomeApprox))
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(Color.white.opacity(0.85))
                                .lineSpacing(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .transition(.opacity)
                    }

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, SolSpacing.lg)
                .padding(.bottom, 100)
            }
            .scrollDismissesKeyboard(.immediately)
            .animation(.spring(response: 0.32, dampingFraction: 0.85), value: state.hasSecondaryIncome)
            .animation(.easeInOut(duration: 0.2), value: state.salaryRange)
        }
        .safeAreaInset(edge: .bottom) {
            SolPrimaryButton("Continuă", fullWidth: true) {
                state.next()
            }
            .opacity(state.canProceedFromCurrentStep ? 1 : 0.4)
            .disabled(!state.canProceedFromCurrentStep)
            .padding(.horizontal, SolSpacing.lg)
            .padding(.vertical, SolSpacing.base)
            .background(.ultraThinMaterial.opacity(0.6))
        }
    }

    // MARK: - Field label (uppercase tracked)

    @ViewBuilder
    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Color.white.opacity(0.5))
            .tracking(0.6)
            .textCase(.uppercase)
            .padding(.horizontal, 4)
    }

    // MARK: - Salary row (vertical pill)

    @ViewBuilder
    private func salaryRow(_ range: SalaryRange) -> some View {
        let isSelected = state.salaryRange == range

        Button {
            Haptics.selection()
            state.salaryRange = range
        } label: {
            HStack(spacing: 12) {
                // Leading dot indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.solMintExact : Color.white.opacity(0.18), lineWidth: 1.5)
                        .frame(width: 18, height: 18)
                    if isSelected {
                        Circle()
                            .fill(Color.solMintExact)
                            .frame(width: 10, height: 10)
                            .shadow(color: Color.solMintExact.opacity(0.6), radius: 4)
                    }
                }

                Text(salaryLabel(range))
                    .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.85))
                    .tracking(-0.2)

                Spacer()

                Text("RON / lună")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.4))
                    .tracking(0.3)
                    .textCase(.uppercase)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: isSelected
                        ? [Color.solMintExact.opacity(0.12), Color.solMintExact.opacity(0.04)]
                        : [Color.white.opacity(0.04), Color.white.opacity(0.015)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .background(.ultraThinMaterial.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? Color.solMintExact.opacity(0.35) : Color.white.opacity(0.07), lineWidth: 1)
            )
            .shadow(color: isSelected ? Color.solMintExact.opacity(0.15) : .clear, radius: 12)
        }
        .buttonStyle(.plain)
    }

    private func salaryLabel(_ range: SalaryRange) -> String {
        switch range {
        case .under3k:    return "Sub 3.000"
        case .range3to5:  return "3.000 – 5.000"
        case .range5to8:  return "5.000 – 8.000"
        case .range8to15: return "8.000 – 15.000"
        case .over15k:    return "Peste 15.000"
        }
    }

    // MARK: - Secondary income toggle (glass)

    @ViewBuilder
    private func secondaryIncomeToggle(isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(SolAccent.blue.iconGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .stroke(Color.solBlueExact.opacity(0.25), lineWidth: 1)
                    )
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.solBlueExact)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text("Ai venit extra?")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.white)
                Text("Freelance, chirii, dividende")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.45))
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Color.solMintExact)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.04), Color.white.opacity(0.015)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .background(.ultraThinMaterial.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
    }

    // MARK: - Extra income TextField (glass)

    @ViewBuilder
    private func extraIncomeField(amount: Binding<Int>) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "banknote.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.solMintLight)

            TextField(
                "ex: 1.500",
                text: Binding(
                    get: { amount.wrappedValue > 0 ? "\(amount.wrappedValue)" : "" },
                    set: { amount.wrappedValue = Int($0.filter { $0.isNumber }) ?? 0 }
                )
            )
            .keyboardType(.numberPad)
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(Color.white)
            .tint(Color.solMintExact)
            .focused($extraFocused)

            Text("RON")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.4))
                .tracking(0.4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.04), Color.white.opacity(0.015)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .background(.ultraThinMaterial.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(extraFocused ? Color.solMintExact.opacity(0.35) : Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Insight message

    private func insightMessage(for range: SalaryRange, hasExtra: Bool, extra: Int) -> String {
        let base = range.midpointRON
        let total = base + (hasExtra ? max(0, extra) : 0)
        let formatted = NumberFormatter.solRON.string(from: NSNumber(value: total)) ?? "\(total)"
        if hasExtra && extra > 0 {
            return "Estimez ~\(formatted) RON / lună (salariu + extra). Pe baza asta calculez Safe to Spend după obligații."
        }
        return "Estimez ~\(formatted) RON / lună ca punct de plecare. Rafinez cifra când văd primele tranzacții."
    }
}

// MARK: - Helpers

private extension NumberFormatter {
    static let solRON: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = "."
        f.maximumFractionDigits = 0
        return f
    }()
}

#Preview {
    OnboardingScreen3Income()
        .environment({
            let s = OnboardingState()
            s.salaryRange = .range5to8
            s.paydayDay = 15
            return s
        }())
        .preferredColorScheme(.dark)
}
