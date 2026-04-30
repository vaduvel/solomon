import SwiftUI
import SolomonCore
import SolomonStorage

// MARK: - ObligationEditView (Claude Design v3 — goal-edit.html pattern 1:1)
//
// Editare/creare obligație recurentă: sheet handle + back + brand "SOLOMON · OBLIGAȚIE" +
// titlu + trash (edit) + glass form fields + insight impact lunar/anual + save / delete.
// Validări: name nu e gol, amount > 0.
// Business logic păstrat: editingObligation, save() complet, CoreDataObligationRepository,
// validation, ObligationKind selector, dayOfMonth (1–31).

struct ObligationEditView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var moc

    // MARK: - Init

    let editingObligation: Obligation?

    init(editingObligation: Obligation? = nil) {
        self.editingObligation = editingObligation
    }

    // MARK: - Form state

    @State private var name: String = ""
    @State private var amountText: String = "0"
    @State private var kind: ObligationKind = .rentMortgage
    @State private var dayOfMonth: Int = 1
    @State private var frequency: ObligationFrequency = .monthly

    @State private var saveError: String?
    @State private var showDeleteConfirm = false
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case name, amount
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            MeshBackground(
                topLeftAccent: .mint,
                midRightAccent: .blue,
                bottomLeftAccent: .violet
            )

            ScrollView {
                VStack(spacing: SolSpacing.md) {
                    sheetHandle
                    appBar
                    kindField
                    nameField
                    amountAndFrequencyRow
                    dayOfMonthField
                    impactInsight

                    if let saveError {
                        Text(saveError)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.solRoseExact)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                    }

                    SolPrimaryButton(
                        editingObligation == nil ? "Adaugă" : "Salvează",
                        accent: .mint,
                        fullWidth: true
                    ) {
                        save()
                    }
                    .opacity(isFormValid ? 1 : 0.4)
                    .disabled(!isFormValid)
                    .padding(.top, 4)

                    if editingObligation != nil {
                        SolSecondaryButton("Șterge", fullWidth: true) {
                            Haptics.warning()
                            showDeleteConfirm = true
                        }
                    }
                }
                .padding(.horizontal, SolSpacing.screenHorizontal)
                .padding(.bottom, SolSpacing.hh)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.dark)
        .onAppear { loadIfEditing() }
        .alert("Ștergi această obligație?", isPresented: $showDeleteConfirm) {
            Button("Anulează", role: .cancel) {}
            Button("Șterge", role: .destructive) { deleteObligation() }
        } message: {
            Text("Acțiunea nu poate fi anulată.")
        }
    }

    // MARK: - Sheet handle

    private var sheetHandle: some View {
        HStack {
            Spacer()
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Color.white.opacity(0.18))
                .frame(width: 36, height: 5)
            Spacer()
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: - App bar

    private var appBar: some View {
        HStack(alignment: .center, spacing: 12) {
            SolBackButton { dismiss() }

            VStack(spacing: 4) {
                Text("SOLOMON · OBLIGAȚIE")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.45))
                    .tracking(1.4)
                    .textCase(.uppercase)
                Text(editingObligation == nil ? "Adaugă obligație" : "Editează obligație")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .tracking(-0.4)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)

            if editingObligation != nil {
                SolIconButton(systemName: "trash") {
                    Haptics.warning()
                    showDeleteConfirm = true
                }
            } else {
                Color.clear.frame(width: 38, height: 38)
            }
        }
        .padding(.bottom, SolSpacing.md)
    }

    // MARK: - Kind selector (pills row, scrollable)

    private var kindField: some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel("TIP OBLIGAȚIE")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(ObligationKind.allCases, id: \.self) { k in
                        SolPill(k.displayNameRO, isActive: kind == k) {
                            kind = k
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(.bottom, 4)
    }

    // MARK: - Name field

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel("NUME")
            glassInput(isFocused: focusedField == .name) {
                TextField(placeholder(for: kind), text: $name)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.white)
                    .focused($focusedField, equals: .name)
            }
        }
        .padding(.bottom, 4)
    }

    // MARK: - Amount + Frequency row (split 2 col)

    private var amountAndFrequencyRow: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                fieldLabel("SUMĂ")
                glassInput(isFocused: focusedField == .amount) {
                    HStack(spacing: 4) {
                        TextField("0", text: $amountText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color.white)
                            .tracking(-0.4)
                            .keyboardType(.numberPad)
                            .monospacedDigit()
                            .focused($focusedField, equals: .amount)
                            .onChange(of: amountText) { _, newValue in
                                let filtered = newValue.filter(\.isNumber)
                                if filtered != newValue { amountText = filtered }
                                if filtered.hasPrefix("0") && filtered.count > 1 {
                                    amountText = String(filtered.drop(while: { $0 == "0" }))
                                }
                            }
                        Text("RON")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.4))
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                fieldLabel("FRECVENȚĂ")
                Menu {
                    ForEach(ObligationFrequency.allCases, id: \.self) { freq in
                        Button {
                            Haptics.light()
                            frequency = freq
                        } label: {
                            if frequency == freq {
                                Label(freq.displayName, systemImage: "checkmark")
                            } else {
                                Text(freq.displayName)
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(frequency.displayName)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.white)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.45))
                    }
                    .contentShape(Rectangle())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white.opacity(0.04))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, 4)
    }

    // MARK: - Day of month picker (1–31)

    private var dayOfMonthField: some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel("ZIUA PLĂȚII")
            Menu {
                ForEach(1...31, id: \.self) { day in
                    Button {
                        Haptics.light()
                        dayOfMonth = day
                    } label: {
                        if dayOfMonth == day {
                            Label("Ziua \(day)", systemImage: "checkmark")
                        } else {
                            Text("Ziua \(day)")
                        }
                    }
                }
            } label: {
                HStack {
                    Text("Ziua \(dayOfMonth) a fiecărei luni")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.white)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.45))
                }
                .contentShape(Rectangle())
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.bottom, 4)
    }

    // MARK: - Impact insight (amber)

    private var impactInsight: some View {
        SolInsightCard(
            icon: "sparkles",
            label: "SOLOMON SUGEREAZĂ",
            timestamp: "auto",
            accent: .amber
        ) {
            VStack(alignment: .leading, spacing: 10) {
                let monthlyImpact = monthlyImpactRON
                let annualImpact = annualImpactRON

                let prefix = Text("Această obligație înseamnă ")
                    .foregroundStyle(Color.white.opacity(0.85))
                let monthlyText = Text("\(RomanianMoneyFormatter.thousands(monthlyImpact)) RON/lună")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.solAmberExact)
                let connector = Text(" sau ")
                    .foregroundStyle(Color.white.opacity(0.85))
                let annualText = Text("\(RomanianMoneyFormatter.thousands(annualImpact)) RON/an")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.white)
                let suffix = Text(" din venitul tău.")
                    .foregroundStyle(Color.white.opacity(0.85))

                (prefix + monthlyText + connector + annualText + suffix)
                    .font(.system(size: 14))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack {
                    Text("plată: ziua \(dayOfMonth) · \(frequency.displayName.lowercased())")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.5))
                    Spacer()
                    Text(kind.displayNameRO)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.solAmberExact.opacity(0.85))
                }
            }
        }
    }

    // MARK: - Computed

    private var amountValue: Int {
        Int(amountText) ?? 0
    }

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && amountValue > 0
    }

    private var monthlyImpactRON: Int {
        switch frequency {
        case .monthly:   return amountValue
        case .quarterly: return amountValue / 3
        case .annual:    return amountValue / 12
        }
    }

    private var annualImpactRON: Int {
        amountValue * frequency.monthsPerYear
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

    private func placeholder(for kind: ObligationKind) -> String {
        switch kind {
        case .rentMortgage: return "ex: Chirie apartament"
        case .utility:      return "ex: Enel, ENGIE, Apa"
        case .subscription: return "ex: Netflix, iCloud"
        case .loanBank:     return "ex: Credit ipotecar BT"
        case .loanIFN:      return "ex: Provident, Cetelem"
        case .bnpl:         return "ex: PayPo, Klarna"
        case .insurance:    return "ex: RCA, asigurare casă"
        case .other:        return "ex: Pensie facultativă"
        }
    }

    // MARK: - Actions

    private func loadIfEditing() {
        guard let o = editingObligation else { return }
        name = o.name
        amountText = String(o.amount.amount)
        kind = o.kind
        dayOfMonth = o.dayOfMonth
        // Frequency nu e persistat în model — păstrăm default monthly
        frequency = .monthly
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            saveError = "Numele obligației nu poate fi gol."
            return
        }
        guard amountValue > 0 else {
            saveError = "Suma trebuie să fie mai mare decât 0."
            return
        }

        let repo = CoreDataObligationRepository(context: moc)
        do {
            let obligation = Obligation(
                id: editingObligation?.id ?? UUID(),
                name: trimmedName,
                amount: Money(amountValue),
                dayOfMonth: dayOfMonth,
                kind: kind,
                confidence: .declared,
                since: editingObligation?.since ?? Date()
            )
            try repo.upsert(obligation)
            Haptics.success()
            dismiss()
        } catch {
            saveError = "Nu am putut salva: \(error.localizedDescription)"
        }
    }

    private func deleteObligation() {
        guard let id = editingObligation?.id else { return }
        let repo = CoreDataObligationRepository(context: moc)
        do {
            try repo.delete(id: id)
            Haptics.success()
            dismiss()
        } catch {
            saveError = "Nu am putut șterge: \(error.localizedDescription)"
        }
    }
}

// MARK: - ObligationFrequency (UI-only — model nu persistă frecvență)

private enum ObligationFrequency: String, CaseIterable, Hashable {
    case monthly, quarterly, annual

    var displayName: String {
        switch self {
        case .monthly:   return "Lunar"
        case .quarterly: return "Trimestrial"
        case .annual:    return "Anual"
        }
    }

    var monthsPerYear: Int {
        switch self {
        case .monthly:   return 12
        case .quarterly: return 4
        case .annual:    return 1
        }
    }
}

// MARK: - Preview

#Preview("Obligație nouă") {
    ObligationEditView()
        .preferredColorScheme(.dark)
}

#Preview("Editează obligație") {
    ObligationEditView(editingObligation: Obligation(
        id: UUID(),
        name: "Chirie",
        amount: Money(1500),
        dayOfMonth: 5,
        kind: .rentMortgage,
        confidence: .declared,
        since: Date()
    ))
    .preferredColorScheme(.dark)
}
