import SwiftUI
import SolomonCore

// MARK: - Ecran 6 — Obiectiv (Solomon DS · goal-edit pattern)

struct OnboardingScreen6Goal: View {
    @Environment(OnboardingState.self) var state: OnboardingState
    @FocusState private var focusedField: Field?

    enum Field: Hashable { case destination, target }

    var body: some View {
        @Bindable var state = state

        ZStack {
            MeshBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {

                    // Eyebrow + title
                    VStack(alignment: .leading, spacing: 6) {
                        Text("PASUL 6")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.solMintLight)
                            .tracking(1.4)
                        Text("Ai un vis financiar?")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(Color.white)
                            .tracking(-0.6)
                        Text("Solomon te ajută să ajungi acolo cu plan clar.")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.white.opacity(0.55))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 4)

                    // Kind selector — horizontal SolPill row
                    VStack(alignment: .leading, spacing: 6) {
                        fieldLabel("TIP OBIECTIV")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(GoalKind.allCases, id: \.self) { k in
                                    SolPill(k.displayNameRO, isActive: state.firstGoalKind == k) {
                                        state.firstGoalKind = k
                                    }
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }

                    // Destination
                    VStack(alignment: .leading, spacing: 6) {
                        fieldLabel("DESTINAȚIA")
                        glassInput(isFocused: focusedField == .destination) {
                            TextField(placeholder(for: state.firstGoalKind), text: $state.firstGoalDestination)
                                .textFieldStyle(.plain)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color.white)
                                .focused($focusedField, equals: .destination)
                        }
                    }

                    // Target amount
                    VStack(alignment: .leading, spacing: 6) {
                        fieldLabel("SUMA ȚINTĂ")
                        glassInput(isFocused: focusedField == .target) {
                            HStack(spacing: 4) {
                                TextField("5000", text: $state.firstGoalTargetText)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(Color.white)
                                    .tracking(-0.4)
                                    .keyboardType(.numberPad)
                                    .monospacedDigit()
                                    .focused($focusedField, equals: .target)
                                Text("RON")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Color.white.opacity(0.4))
                            }
                        }
                    }

                    // Deadline
                    VStack(alignment: .leading, spacing: 6) {
                        fieldLabel("DEADLINE")
                        ZStack {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.white.opacity(0.04))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                            HStack {
                                DatePicker(
                                    "",
                                    selection: $state.firstGoalDeadline,
                                    in: minDeadline...,
                                    displayedComponents: .date
                                )
                                .labelsHidden()
                                .datePickerStyle(.compact)
                                .tint(Color.solMintExact)
                                .colorScheme(.dark)
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 12)
                        }
                        .frame(height: 50)
                    }

                    // Projection insight
                    if targetRON > 0 {
                        SolInsightCard(
                            icon: "sparkles",
                            label: "PROIECȚIE",
                            timestamp: "auto",
                            accent: .mint
                        ) {
                            (Text("Trebuie să pui ~")
                                .foregroundStyle(Color.white.opacity(0.85))
                             + Text("\(monthlyRequiredRON) RON/lună")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.solMintExact)
                             + Text(" până în ")
                                .foregroundStyle(Color.white.opacity(0.85))
                             + Text(deadlineLabelRO)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.white)
                             + Text(" ca să atingi ținta.")
                                .foregroundStyle(Color.white.opacity(0.85)))
                                .font(.system(size: 14))
                                .lineSpacing(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    // Actions
                    VStack(spacing: 10) {
                        SolPrimaryButton("Continuă", accent: .mint, fullWidth: true) {
                            Haptics.medium()
                            state.next()
                        }
                        SolSecondaryButton("Sar peste, voi seta mai târziu", fullWidth: true) {
                            Haptics.light()
                            state.next()
                        }
                    }
                    .padding(.top, 6)

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, SolSpacing.screenHorizontal)
                .padding(.bottom, SolSpacing.xxxl)
            }
        }
    }

    // MARK: - Derived

    private var targetRON: Int { Int(state.firstGoalTargetText) ?? 0 }

    private var monthsToDeadline: Int {
        let comps = Calendar.current.dateComponents([.month], from: Date(), to: state.firstGoalDeadline)
        return max(1, comps.month ?? 1)
    }

    private var monthlyRequiredRON: Int {
        Int((Double(targetRON) / Double(monthsToDeadline)).rounded())
    }

    private var deadlineLabelRO: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ro_RO")
        f.dateFormat = "LLLL yyyy"
        return f.string(from: state.firstGoalDeadline).lowercased()
    }

    private var minDeadline: Date {
        Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    }

    // MARK: - Helpers

    @ViewBuilder
    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(Color.white.opacity(0.5))
            .tracking(0.5)
            .textCase(.uppercase)
    }

    @ViewBuilder
    private func glassInput<C: View>(isFocused: Bool, @ViewBuilder content: () -> C) -> some View {
        HStack {
            content()
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isFocused ? Color.solMintExact.opacity(0.04) : Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    isFocused ? Color.solMintExact.opacity(0.4) : Color.white.opacity(0.08),
                    lineWidth: 1
                )
        )
        .animation(.easeInOut(duration: 0.18), value: isFocused)
    }

    private func placeholder(for kind: GoalKind) -> String {
        switch kind {
        case .vacation:      return "ex: Grecia"
        case .car:           return "ex: Tesla Model 3"
        case .house:         return "ex: Apartament Cluj"
        case .emergencyFund: return "Fond pentru 3 luni"
        case .debtPayoff:    return "Card credit"
        case .custom:        return "Descriere obiectiv"
        }
    }
}

#Preview {
    OnboardingScreen6Goal()
        .environment(OnboardingState())
        .preferredColorScheme(.dark)
}
