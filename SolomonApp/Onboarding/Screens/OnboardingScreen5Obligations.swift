import SwiftUI
import SolomonCore

// MARK: - Ecran 5 — Obligații cunoscute (HIG aligned)
//
// Pattern: List + plus button + skip option.

struct OnboardingScreen5Obligations: View {
    @EnvironmentObject var state: OnboardingState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SolSpacing.xl) {

                VStack(alignment: .leading, spacing: SolSpacing.xs) {
                    Text("Plățile tale lunare")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(Color.solForeground)
                    Text("Solomon le va găsi automat din email. Adaugă acum doar ce-ți amintești.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, SolSpacing.lg)

                if state.draftObligations.isEmpty {
                    EmptyStateView(
                        icon: "list.bullet.rectangle",
                        title: "Nicio plată adăugată",
                        subtitle: "Adaugă chiria, abonamentele și ratele dacă le știi.",
                        cta: .init(title: "Adaugă plată", icon: "plus") {
                            Haptics.light()
                            state.addDraftObligation()
                        }
                    )
                    .solCard()
                } else {
                    VStack(spacing: SolSpacing.sm) {
                        ForEach($state.draftObligations) { $draft in
                            DraftObligationRow(draft: $draft) {
                                Haptics.warning()
                                state.removeDraftObligation(draft.id)
                            }
                        }

                        Button {
                            Haptics.light()
                            state.addDraftObligation()
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.body)
                                    .foregroundStyle(Color.solPrimary)
                                Text("Adaugă încă o plată")
                                    .font(.body)
                                    .foregroundStyle(Color.solPrimary)
                                Spacer()
                            }
                            .padding(.horizontal, SolSpacing.base)
                            .frame(height: 50)
                            .background(Color.solPrimary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: SolRadius.lg))
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer(minLength: SolSpacing.lg)
            }
            .padding(.horizontal, SolSpacing.lg)
            .padding(.bottom, SolSpacing.xxxl)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: SolSpacing.sm) {
                SolomonButton("Continuă", icon: "arrow.right") {
                    Haptics.medium()
                    state.next()
                }
                if state.draftObligations.isEmpty {
                    Button("Sări peste, le găsește Solomon") {
                        Haptics.light()
                        state.next()
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, SolSpacing.lg)
            .padding(.vertical, SolSpacing.base)
            .background(.ultraThinMaterial)
        }
    }
}

private struct DraftObligationRow: View {
    @Binding var draft: OnboardingState.DraftObligation
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: SolSpacing.sm) {
            HStack {
                Picker("Tip", selection: $draft.kind) {
                    ForEach(ObligationKind.allCases, id: \.self) { k in
                        Text(k.displayNameRO).tag(k)
                    }
                }
                .pickerStyle(.menu)
                .tint(Color.solPrimary)

                Spacer()

                Button {
                    onDelete()
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.solDestructive)
                        .symbolRenderingMode(.hierarchical)
                }
            }

            HStack(spacing: SolSpacing.sm) {
                TextField("Nume (ex: Netflix)", text: $draft.name)
                    .font(.body)
                    .padding(.horizontal, SolSpacing.md)
                    .frame(height: 44)
                    .background(Color.solSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: SolRadius.lg))

                TextField("Sumă", value: $draft.amountRON, format: .number)
                    .font(.body)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .padding(.horizontal, SolSpacing.md)
                    .frame(width: 90, height: 44)
                    .background(Color.solSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: SolRadius.lg))
            }

            HStack {
                Text("Ziua")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Stepper("Ziua \(draft.dayOfMonth)", value: $draft.dayOfMonth, in: 1...31)
                    .labelsHidden()
                Text("\(draft.dayOfMonth)")
                    .font(.body.monospacedDigit())
                    .foregroundStyle(Color.solForeground)
                Spacer()
            }
        }
        .padding(SolSpacing.base)
        .solCard()
    }
}

#Preview {
    ZStack {
        Color.solCanvas.ignoresSafeArea()
        OnboardingScreen5Obligations()
            .environmentObject(OnboardingState())
    }
    .preferredColorScheme(.dark)
}
