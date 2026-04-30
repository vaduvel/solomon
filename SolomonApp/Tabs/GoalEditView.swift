import SwiftUI
import SolomonCore
import SolomonStorage

// MARK: - GoalEditView (Claude Design v3)
//
// Pixel-fidel cu `Solomon DS / screens/goal-edit.html`:
//   - MeshBackground (mint/blue/violet)
//   - Sheet handle + back button + titlu "Obiectiv nou" / "Editează obiectiv"
//   - Form fields glass cu label uppercase tracked + input + focus state mint
//   - SolPill row pentru GoalKind selector (vacation/car/house/emergency/debt/custom)
//   - Auto-deduce insight (mint) când user a setat target + deadline
//   - Salvează + Șterge butoane fullWidth
//
// Business logic păstrat: editingGoal init, save() complet, validation, GoalRepository, dismiss.

struct GoalEditView: View {

    @Environment(\.dismiss) private var dismiss

    let editingGoal: Goal?

    @State private var kind: GoalKind = .vacation
    @State private var destination: String = ""
    @State private var amountTargetText: String = "5000"
    @State private var amountSavedText: String = "0"
    @State private var deadline: Date = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()
    @State private var saveError: String?
    @State private var showDeleteConfirm = false
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case destination, target, saved
    }

    init(editingGoal: Goal? = nil) {
        self.editingGoal = editingGoal
    }

    private var amountTargetRON: Int { Int(amountTargetText) ?? 0 }
    private var amountSavedRON: Int { Int(amountSavedText) ?? 0 }

    var body: some View {
        ZStack {
            MeshBackground()

            ScrollView {
                VStack(spacing: SolSpacing.md) {
                    sheetHandle
                    appBar
                    kindField
                    destinationField
                    amountFieldsRow
                    savedField
                    if shouldShowInsight {
                        autoDeduceInsight
                    }
                    if let saveError {
                        Text(saveError)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.solRoseExact)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                    }
                    SolPrimaryButton(
                        editingGoal == nil ? "Adaugă obiectiv" : "Salvează modificările",
                        accent: .mint,
                        fullWidth: true
                    ) {
                        save()
                    }
                    .opacity(amountTargetRON > 0 ? 1 : 0.4)
                    .disabled(amountTargetRON == 0)

                    if editingGoal != nil {
                        SolSecondaryButton("Șterge obiectiv", fullWidth: true) {
                            showDeleteConfirm = true
                        }
                    }
                }
                .padding(.horizontal, SolSpacing.screenHorizontal)
                .padding(.bottom, SolSpacing.hh)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { loadIfEditing() }
        .alert("Ștergi acest obiectiv?", isPresented: $showDeleteConfirm) {
            Button("Anulează", role: .cancel) {}
            Button("Șterge", role: .destructive) { delete() }
        } message: {
            Text("Acțiunea nu poate fi anulată.")
        }
    }

    // MARK: - Sub-views

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

    private var appBar: some View {
        HStack(alignment: .center, spacing: 12) {
            SolBackButton { dismiss() }

            VStack(spacing: 4) {
                Text(editingGoal == nil ? "SOLOMON · OBIECTIV NOU" : "SOLOMON · EDITEAZĂ")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.45))
                    .tracking(1.4)
                    .textCase(.uppercase)
                Text(headerTitle)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .tracking(-0.4)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)

            // Mirror back-button width to keep title centered
            if editingGoal != nil {
                SolIconButton(systemName: "trash") {
                    showDeleteConfirm = true
                }
            } else {
                Color.clear.frame(width: 38, height: 38)
            }
        }
        .padding(.bottom, SolSpacing.md)
    }

    private var headerTitle: String {
        if let g = editingGoal {
            if let dest = g.destination, !dest.isEmpty { return dest }
            return g.kind.displayNameRO
        }
        if !destination.isEmpty { return destination }
        return kind.displayNameRO
    }

    // MARK: Field — Tip obiectiv (kind selector)

    private var kindField: some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel("TIP OBIECTIV")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(GoalKind.allCases, id: \.self) { k in
                        SolPill(k.displayNameRO, isActive: kind == k) {
                            kind = k
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(.bottom, 8)
    }

    // MARK: Field — Nume / destinație

    private var destinationField: some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel("NUME")
            glassInput(isFocused: focusedField == .destination) {
                TextField(placeholder(for: kind), text: $destination)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.white)
                    .focused($focusedField, equals: .destination)
            }
        }
        .padding(.bottom, 8)
    }

    // MARK: Field — Sumă țintă + Deadline (row)

    private var amountFieldsRow: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                fieldLabel("SUMA ȚINTĂ")
                glassInput(isFocused: focusedField == .target) {
                    HStack(spacing: 4) {
                        TextField("5000", text: $amountTargetText)
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

            VStack(alignment: .leading, spacing: 6) {
                fieldLabel("DEADLINE")
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(focusedField == nil ? Color.white.opacity(0.04) : Color.white.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                    HStack {
                        DatePicker("", selection: $deadline, in: minDeadline..., displayedComponents: .date)
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
        }
        .padding(.bottom, 8)
    }

    // MARK: Field — Sumă strânsă

    private var savedField: some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel("SUMA STRÂNSĂ DEJA")
            glassInput(isFocused: focusedField == .saved) {
                HStack(spacing: 4) {
                    TextField("0", text: $amountSavedText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.white)
                        .keyboardType(.numberPad)
                        .monospacedDigit()
                        .focused($focusedField, equals: .saved)
                    Text("RON")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.4))
                }
            }
        }
        .padding(.bottom, 8)
    }

    // MARK: Auto-deduce insight (mint)

    private var shouldShowInsight: Bool {
        amountTargetRON > 0 && monthsToDeadline >= 1
    }

    private var monthsToDeadline: Int {
        let comps = Calendar.current.dateComponents([.month], from: Date(), to: deadline)
        return max(0, comps.month ?? 0)
    }

    private var monthlyRequiredRON: Int {
        let remaining = max(0, amountTargetRON - amountSavedRON)
        let months = max(1, monthsToDeadline)
        return Int((Double(remaining) / Double(months)).rounded())
    }

    private var deadlineLabelRO: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ro_RO")
        f.dateFormat = "LLLL yyyy"
        return f.string(from: deadline).lowercased()
    }

    private var autoDeduceInsight: some View {
        SolInsightCard(
            icon: "sparkles",
            label: "SOLOMON · PROIECȚIE",
            timestamp: "auto",
            accent: .mint
        ) {
            VStack(alignment: .leading, spacing: 10) {
                let prefix = Text("Trebuie să pui ~")
                    .foregroundStyle(Color.white.opacity(0.85))
                let amountText = Text("\(RomanianMoneyFormatter.thousands(monthlyRequiredRON)) RON/lună")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.solMintExact)
                let connector = Text(" până în ")
                    .foregroundStyle(Color.white.opacity(0.85))
                let dateText = Text(deadlineLabelRO)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.white)
                let suffix = Text(" ca să atingi ținta.")
                    .foregroundStyle(Color.white.opacity(0.85))

                (prefix + amountText + connector + dateText + suffix)
                    .font(.system(size: 14))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

                // Mini progress preview
                if amountSavedRON > 0 {
                    SolLinearProgress(
                        progress: CGFloat(min(1, Double(amountSavedRON) / Double(max(1, amountTargetRON)))),
                        accent: .mint,
                        height: 5,
                        glow: false
                    )
                    HStack {
                        Text("strâns: \(RomanianMoneyFormatter.thousands(amountSavedRON)) RON")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.white.opacity(0.5))
                        Spacer()
                        Text("rămas: \(RomanianMoneyFormatter.thousands(max(0, amountTargetRON - amountSavedRON))) RON")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.white.opacity(0.5))
                    }
                }
            }
        }
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

    private var minDeadline: Date {
        Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    }

    private func placeholder(for kind: GoalKind) -> String {
        switch kind {
        case .vacation:      return "ex: Grecia 2 săpt."
        case .car:           return "ex: Tesla Model 3"
        case .house:         return "ex: Apartament Cluj"
        case .emergencyFund: return "Fond pentru 3 luni"
        case .debtPayoff:    return "Rambursare card credit"
        case .custom:        return "Descriere obiectiv"
        }
    }

    private func loadIfEditing() {
        guard let g = editingGoal else { return }
        kind = g.kind
        destination = g.destination ?? ""
        amountTargetText = String(g.amountTarget.amount)
        amountSavedText = String(g.amountSaved.amount)
        deadline = g.deadline
    }

    // MARK: - Persistence

    private func save() {
        let ctx = SolomonPersistenceController.shared.container.viewContext
        let repo = CoreDataGoalRepository(context: ctx)

        guard amountTargetRON > 0 else {
            saveError = "Suma țintă trebuie să fie mai mare decât 0."
            return
        }

        do {
            let goal = Goal(
                id: editingGoal?.id ?? UUID(),
                kind: kind,
                destination: destination.isEmpty ? nil : destination,
                amountTarget: Money(amountTargetRON),
                amountSaved: Money(amountSavedRON),
                deadline: deadline
            )
            try repo.upsert(goal)
            dismiss()
        } catch {
            saveError = error.localizedDescription
        }
    }

    private func delete() {
        guard let g = editingGoal else { return }
        let ctx = SolomonPersistenceController.shared.container.viewContext
        let repo = CoreDataGoalRepository(context: ctx)
        do {
            try repo.delete(id: g.id)
            dismiss()
        } catch {
            saveError = error.localizedDescription
        }
    }
}

#Preview {
    GoalEditView()
        .preferredColorScheme(.dark)
}
