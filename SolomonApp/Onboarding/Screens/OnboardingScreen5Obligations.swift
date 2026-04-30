import SwiftUI
import SolomonCore

// MARK: - Ecran 5 — Obligații (Solomon DS · Claude Design v3)

struct OnboardingScreen5Obligations: View {
    @Environment(OnboardingState.self) var state: OnboardingState

    @State private var showForm = false
    @State private var draftKind: ObligationKind = .rentMortgage
    @State private var draftName: String = ""
    @State private var draftAmount: String = ""
    @State private var draftDay: Int = 1
    @State private var editingId: UUID? = nil

    private let kinds: [ObligationKind] = [
        .rentMortgage, .utility, .subscription, .loanBank, .loanIFN, .bnpl, .insurance, .other
    ]

    var body: some View {
        @Bindable var state = state
        ZStack {
            MeshBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: SolSpacing.xl) {

                    VStack(alignment: .leading, spacing: 6) {
                        Text("PASUL 5")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.solMintLight)
                            .tracking(1.4)
                        Text("Ce plăți fixe ai în fiecare lună?")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(Color.white)
                            .tracking(-0.5)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Chirie, rate, abonamente... Solomon le păstrează deoparte ca să-ți spună ce poți cheltui.")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.white.opacity(0.55))
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 4)
                    }
                    .padding(.top, SolSpacing.lg)

                    // Lista
                    if state.draftObligations.isEmpty && !showForm {
                        emptyCard
                    } else if !state.draftObligations.isEmpty {
                        SolListCard {
                            ForEach(Array(state.draftObligations.enumerated()), id: \.element.id) { idx, draft in
                                if idx > 0 { SolHairlineDivider() }
                                obligationRow(draft)
                            }
                        }

                        if !showForm {
                            Button {
                                Haptics.light()
                                resetForm()
                                showForm = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 14, weight: .medium))
                                    Text("Adaugă încă o plată")
                                        .font(.system(size: 13, weight: .medium))
                                    Spacer()
                                }
                                .foregroundStyle(Color.solMintLight)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(Color.solMintExact.opacity(0.06))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(Color.solMintExact.opacity(0.20), lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Form inline
                    if showForm {
                        inlineForm
                    }

                    Spacer(minLength: SolSpacing.lg)

                    VStack(spacing: 10) {
                        SolPrimaryButton("Continuă", fullWidth: true) {
                            state.next()
                        }
                        SolSecondaryButton("Sar peste", fullWidth: true) {
                            state.next()
                        }
                    }
                }
                .padding(.horizontal, SolSpacing.lg)
                .padding(.bottom, SolSpacing.xxxl)
            }
        }
    }

    // MARK: - Empty state (mint insight)

    private var emptyCard: some View {
        SolInsightCard(
            icon: "list.bullet.rectangle.fill",
            label: "ÎNCEPE LISTA",
            accent: .mint
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Nicio plată fixă încă. Adaugă chiria, ratele și abonamentele pe care le știi.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    Haptics.light()
                    resetForm()
                    showForm = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Adaugă prima obligație")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(Color(red: 0x05/255, green: 0x2E/255, blue: 0x16/255))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(SolAccent.mint.primaryButtonGradient)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Row

    @ViewBuilder
    private func obligationRow(_ draft: OnboardingState.DraftObligation) -> some View {
        SolListRow(
            title: draft.name.isEmpty ? draft.kind.displayNameRO : draft.name,
            subtitle: "\(draft.kind.displayNameRO) · ziua \(draft.dayOfMonth)",
            onTap: {
                beginEdit(draft)
            },
            leading: { kindLogo(draft.kind) },
            trailing: {
                HStack(spacing: 8) {
                    Text("\(draft.amountRON) RON")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .monospacedDigit()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.3))
                }
            }
        )
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                Haptics.warning()
                state.removeDraftObligation(draft.id)
            } label: {
                Label("Șterge", systemImage: "trash")
            }
        }
    }

    // MARK: - Inline form

    private var inlineForm: some View {
        VStack(alignment: .leading, spacing: 14) {

            VStack(alignment: .leading, spacing: 8) {
                fieldLabel("TIP")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(kinds, id: \.self) { k in
                            SolPill(k.displayNameRO, isActive: draftKind == k) {
                                draftKind = k
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                fieldLabel("NUME")
                glassInput {
                    TextField("ex: Netflix", text: $draftName)
                        .textFieldStyle(.plain)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.white)
                }
            }

            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    fieldLabel("SUMĂ")
                    glassInput {
                        HStack(spacing: 4) {
                            TextField("0", text: $draftAmount)
                                .textFieldStyle(.plain)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Color.white)
                                .keyboardType(.numberPad)
                                .monospacedDigit()
                                .onChange(of: draftAmount) { _, newValue in
                                    let filtered = newValue.filter(\.isNumber)
                                    if filtered != newValue { draftAmount = filtered }
                                }
                            Text("RON")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.white.opacity(0.4))
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    fieldLabel("ZIUA")
                    Menu {
                        ForEach(1...31, id: \.self) { day in
                            Button("Ziua \(day)") {
                                Haptics.light()
                                draftDay = day
                            }
                        }
                    } label: {
                        HStack {
                            Text("Ziua \(draftDay)")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color.white)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color.white.opacity(0.45))
                        }
                        .contentShape(Rectangle())
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)
                        .background(Color.white.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 8) {
                SolPrimaryButton(editingId == nil ? "Adaugă" : "Salvează", fullWidth: true) {
                    commitForm()
                }
                SolSecondaryButton("Anulează", fullWidth: true) {
                    showForm = false
                    resetForm()
                }
            }
            .padding(.top, 4)
        }
        .padding(SolSpacing.base)
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

    // MARK: - Helpers

    private func beginEdit(_ draft: OnboardingState.DraftObligation) {
        editingId = draft.id
        draftKind = draft.kind
        draftName = draft.name
        draftAmount = draft.amountRON > 0 ? String(draft.amountRON) : ""
        draftDay = draft.dayOfMonth
        showForm = true
    }

    private func commitForm() {
        let amount = Int(draftAmount) ?? 0
        guard amount > 0 else { return }
        let trimmedName = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = trimmedName.isEmpty ? draftKind.displayNameRO : trimmedName

        if let id = editingId, let idx = state.draftObligations.firstIndex(where: { $0.id == id }) {
            state.draftObligations[idx].kind = draftKind
            state.draftObligations[idx].name = finalName
            state.draftObligations[idx].amountRON = amount
            state.draftObligations[idx].dayOfMonth = draftDay
        } else {
            state.draftObligations.append(
                OnboardingState.DraftObligation(
                    name: finalName,
                    amountRON: amount,
                    dayOfMonth: draftDay,
                    kind: draftKind
                )
            )
        }
        Haptics.medium()
        resetForm()
        showForm = false
    }

    private func resetForm() {
        editingId = nil
        draftKind = .rentMortgage
        draftName = ""
        draftAmount = ""
        draftDay = 1
    }

    @ViewBuilder
    private func kindLogo(_ kind: ObligationKind) -> some View {
        let (icon, accent) = iconForKind(kind)
        ZStack {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(accent.iconGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .stroke(accent.color.opacity(0.25), lineWidth: 1)
                )
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(accent.color)
        }
        .frame(width: 36, height: 36)
    }

    private func iconForKind(_ kind: ObligationKind) -> (String, SolAccent) {
        switch kind {
        case .rentMortgage: return ("house.fill", .blue)
        case .utility:      return ("bolt.fill", .amber)
        case .subscription: return ("play.rectangle.fill", .violet)
        case .loanBank:     return ("building.columns.fill", .blue)
        case .loanIFN:      return ("exclamationmark.octagon.fill", .rose)
        case .bnpl:         return ("creditcard.fill", .rose)
        case .insurance:    return ("shield.fill", .mint)
        case .other:        return ("doc.text.fill", .blue)
        }
    }

    @ViewBuilder
    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(Color.white.opacity(0.4))
            .tracking(0.6)
    }

    @ViewBuilder
    private func glassInput<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(Color.white.opacity(0.04))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview {
    OnboardingScreen5Obligations()
        .environment(OnboardingState())
        .preferredColorScheme(.dark)
}
