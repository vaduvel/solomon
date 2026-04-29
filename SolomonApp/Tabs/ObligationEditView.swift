import SwiftUI
import SolomonCore
import SolomonStorage

// MARK: - ObligationEditView
//
// Create / edit / delete o obligație recurentă (chirie, rată, utilitate, etc.).
// Validări: name nu e gol, amount > 0.

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

    @State private var saveError: String?
    @State private var showDeleteConfirmation = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.solCanvas.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: SolSpacing.lg) {

                        // Header
                        VStack(alignment: .leading, spacing: SolSpacing.sm) {
                            Text(editingObligation == nil ? "Obligație nouă" : "Editează obligație")
                                .font(.solH2)
                                .foregroundStyle(Color.solForeground)
                            Text("Solomon urmărește automat plățile recurente.")
                                .font(.solBody)
                                .foregroundStyle(Color.solMuted)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, SolSpacing.lg)

                        // Nume
                        VStack(alignment: .leading, spacing: SolSpacing.xs) {
                            sectionLabel("NUME")
                            SolomonTextInput(
                                placeholder: "ex: Chirie, Rată BT",
                                text: $name,
                                icon: "doc.text"
                            )
                        }

                        // Sumă
                        VStack(alignment: .leading, spacing: SolSpacing.xs) {
                            sectionLabel("SUMĂ (RON)")
                            HStack {
                                TextField("0", text: $amountText)
                                    .font(.solDisplay)
                                    .foregroundStyle(LinearGradient.solHero)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.center)
                                    .padding(.vertical, SolSpacing.lg)
                                    .onChange(of: amountText) { _, newValue in
                                        let filtered = newValue.filter(\.isNumber)
                                        if filtered != newValue { amountText = filtered }
                                        if filtered.hasPrefix("0") && filtered.count > 1 {
                                            amountText = String(filtered.drop(while: { $0 == "0" }))
                                        }
                                    }
                                Text("RON")
                                    .font(.solH2)
                                    .foregroundStyle(Color.solMuted)
                            }
                            .frame(maxWidth: .infinity)
                            .background(Color.solCard)
                            .clipShape(RoundedRectangle(cornerRadius: SolRadius.xxl))
                        }

                        // Tip obligație
                        VStack(alignment: .leading, spacing: SolSpacing.sm) {
                            sectionLabel("TIP")
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: SolSpacing.sm) {
                                    ForEach(ObligationKind.allCases, id: \.self) { k in
                                        SelectableChip(
                                            title: k.displayNameRO,
                                            icon: iconFor(k),
                                            isSelected: kind == k
                                        ) {
                                            Haptics.light()
                                            kind = k
                                        }
                                    }
                                }
                                .padding(.horizontal, 1)
                            }
                        }

                        // Ziua lunii
                        VStack(alignment: .leading, spacing: SolSpacing.sm) {
                            sectionLabel("ZIUA LUNII")
                            DayOfMonthPicker(selectedDay: $dayOfMonth)
                                .padding(SolSpacing.base)
                                .background(Color.solCard)
                                .clipShape(RoundedRectangle(cornerRadius: SolRadius.xl))
                        }

                        // Eroare salvare
                        if let saveError {
                            Text(saveError)
                                .font(.solCaption)
                                .foregroundStyle(Color.solDestructive)
                        }

                        // Buton salvează
                        SolomonButton(
                            editingObligation == nil ? "Adaugă obligație" : "Salvează modificările",
                            icon: "checkmark"
                        ) {
                            save()
                        }
                        .opacity(isFormValid ? 1 : 0.4)
                        .disabled(!isFormValid)

                        // Buton ștergere (doar edit mode)
                        if editingObligation != nil {
                            Button(role: .destructive) {
                                Haptics.warning()
                                showDeleteConfirmation = true
                            } label: {
                                Label("Șterge obligația", systemImage: "trash")
                                    .font(.solBodyBold)
                                    .foregroundStyle(Color.solDestructive)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, SolSpacing.base)
                            }
                        }
                    }
                    .padding(.horizontal, SolSpacing.screenHorizontal)
                    .padding(.bottom, SolSpacing.hh)
                }
            }
            .navigationTitle(editingObligation == nil ? "Obligație nouă" : "Editează obligație")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Renunță") { dismiss() }
                        .foregroundStyle(Color.solMuted)
                }
                if editingObligation != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            Haptics.warning()
                            showDeleteConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(Color.solDestructive)
                        }
                    }
                }
            }
            .confirmationDialog(
                "Șterge obligația?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Șterge obligația", role: .destructive) {
                    deleteObligation()
                }
                Button("Anulează", role: .cancel) {}
            } message: {
                Text("Nu se poate recupera.")
            }
            .onAppear { loadIfEditing() }
        }
    }

    // MARK: - Computed

    private var amountValue: Int {
        Int(amountText) ?? 0
    }

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && amountValue > 0
    }

    // MARK: - Helpers

    @ViewBuilder
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.solMicro)
            .foregroundStyle(Color.solMuted)
            .tracking(1.2)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func iconFor(_ k: ObligationKind) -> String {
        switch k {
        case .rentMortgage: return "house.fill"
        case .utility:      return "bolt.fill"
        case .subscription: return "play.rectangle.fill"
        case .loanBank:     return "building.columns.fill"
        case .loanIFN:      return "creditcard.fill"
        case .bnpl:         return "cart.fill"
        case .insurance:    return "shield.fill"
        case .other:        return "ellipsis.circle.fill"
        }
    }

    // MARK: - Actions

    private func loadIfEditing() {
        guard let o = editingObligation else { return }
        name = o.name
        amountText = String(o.amount.amount)
        kind = o.kind
        dayOfMonth = o.dayOfMonth
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
