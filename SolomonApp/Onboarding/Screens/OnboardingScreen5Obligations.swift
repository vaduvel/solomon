import SwiftUI
import SolomonCore

// MARK: - Ecran 5 — Obligații cunoscute (60 sec)
//
// Conform spec §11 ecran 5:
//   - Titlu: "Ce plăți știi că ai lunar?"
//   - Subtitle: "Solomon le va găsi automat din email."
//   - Buton "+": adăugare rapidă
//   - Buton: "Sări peste, le găsește Solomon"

struct OnboardingScreen5Obligations: View {
    @EnvironmentObject var state: OnboardingState

    var body: some View {
        VStack(spacing: SolSpacing.lg) {
            VStack(alignment: .leading, spacing: SolSpacing.sm) {
                Text("Plățile tale lunare")
                    .font(.solH1)
                    .foregroundStyle(Color.solForeground)
                Text("Solomon le va găsi automat din email. Adaugă acum doar ce-ți amintești — chirie, abonamente, rate.")
                    .font(.solBody)
                    .foregroundStyle(Color.solMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, SolSpacing.lg)

            ScrollView {
                VStack(spacing: SolSpacing.sm) {
                    ForEach($state.draftObligations) { $draft in
                        DraftObligationRow(draft: $draft) {
                            state.removeDraftObligation(draft.id)
                        }
                    }

                    Button {
                        state.addDraftObligation()
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(Color.solPrimary)
                            Text("Adaugă o plată recurentă")
                                .font(.solBody)
                                .foregroundStyle(Color.solPrimary)
                            Spacer()
                        }
                        .padding(SolSpacing.base)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.solPrimary.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: SolRadius.xl, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: SolRadius.xl, style: .continuous)
                                .stroke(Color.solPrimary.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4]))
                        )
                    }
                }
            }

            VStack(spacing: SolSpacing.sm) {
                SolomonButton("Continuă", icon: "arrow.right") {
                    state.next()
                }
                if state.draftObligations.isEmpty {
                    SolomonButton("Sări peste, le găsește Solomon", style: .ghost) {
                        state.next()
                    }
                }
            }
        }
        .padding(.horizontal, SolSpacing.screenHorizontal)
        .padding(.bottom, SolSpacing.xl)
    }
}

// MARK: - Draft obligation row

private struct DraftObligationRow: View {
    @Binding var draft: OnboardingState.DraftObligation
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: SolSpacing.sm) {
            HStack(spacing: SolSpacing.sm) {
                Picker("Tip", selection: $draft.kind) {
                    ForEach(ObligationKind.allCases, id: \.self) { k in
                        Text(k.displayNameRO).tag(k)
                    }
                }
                .pickerStyle(.menu)
                .tint(Color.solPrimary)

                Spacer()

                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.solMuted)
                }
            }

            HStack(spacing: SolSpacing.sm) {
                TextField("Nume (ex: Netflix)", text: $draft.name)
                    .font(.solBody)
                    .foregroundStyle(Color.solForeground)
                    .padding(.horizontal, SolSpacing.md)
                    .padding(.vertical, 10)
                    .background(Color.solSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: SolRadius.lg))

                TextField("Sumă RON", value: $draft.amountRON, format: .number)
                    .font(.solBody)
                    .foregroundStyle(Color.solForeground)
                    .keyboardType(.numberPad)
                    .padding(.horizontal, SolSpacing.md)
                    .padding(.vertical, 10)
                    .background(Color.solSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: SolRadius.lg))
                    .frame(width: 90)

                Stepper("Z. \(draft.dayOfMonth)", value: $draft.dayOfMonth, in: 1...31)
                    .labelsHidden()
                Text("\(draft.dayOfMonth)")
                    .font(.solCaption)
                    .foregroundStyle(Color.solMuted)
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
            .environmentObject({
                let s = OnboardingState()
                s.addDraftObligation()
                s.draftObligations[0].name = "Netflix"
                s.draftObligations[0].amountRON = 39
                s.draftObligations[0].kind = .subscription
                return s
            }())
    }
    .preferredColorScheme(.dark)
}
