import SwiftUI
import SolomonCore
import SolomonStorage

// MARK: - SubscriptionEditView
//
// Create / edit / delete un abonament activ.
// Validări: name nu e gol, amount > 0.

struct SubscriptionEditView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var moc

    // MARK: - Init

    let editingSubscription: Subscription?

    init(editingSubscription: Subscription? = nil) {
        self.editingSubscription = editingSubscription
    }

    // MARK: - Form state

    @State private var name: String = ""
    @State private var amountText: String = "0"
    @State private var cancellationDifficulty: CancellationDifficulty = .medium

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
                            Text(editingSubscription == nil ? "Abonament nou" : "Editează abonament")
                                .font(.solH2)
                                .foregroundStyle(Color.solForeground)
                            Text("Solomon detectează abonamentele neutilizate și te ajută să economisești.")
                                .font(.solBody)
                                .foregroundStyle(Color.solMuted)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, SolSpacing.lg)

                        // Nume
                        VStack(alignment: .leading, spacing: SolSpacing.xs) {
                            sectionLabel("NUME")
                            SolomonTextInput(
                                placeholder: "ex: Netflix, Spotify",
                                text: $name,
                                icon: "star.fill"
                            )
                        }

                        // Sumă lunară
                        VStack(alignment: .leading, spacing: SolSpacing.xs) {
                            sectionLabel("SUMĂ LUNARĂ (RON)")
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

                        // Dificultate anulare
                        VStack(alignment: .leading, spacing: SolSpacing.sm) {
                            sectionLabel("DIFICULTATE ANULARE")
                            HStack(spacing: SolSpacing.sm) {
                                ForEach(CancellationDifficulty.allCases, id: \.self) { difficulty in
                                    SelectableChip(
                                        title: difficulty.displayNameRO,
                                        icon: iconFor(difficulty),
                                        isSelected: cancellationDifficulty == difficulty
                                    ) {
                                        Haptics.light()
                                        cancellationDifficulty = difficulty
                                    }
                                }
                                Spacer()
                            }
                        }

                        // Cost anual preview
                        if amountValue > 0 {
                            VStack(alignment: .leading, spacing: SolSpacing.xs) {
                                sectionLabel("COST ANUAL ESTIMAT")
                                HStack {
                                    Image(systemName: "calendar.badge.clock")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(Color.solMuted)
                                    Text("\(amountValue * 12) RON / an")
                                        .font(.solBodyBold)
                                        .foregroundStyle(Color.solForeground)
                                    Spacer()
                                }
                                .padding(SolSpacing.base)
                                .background(Color.solCard)
                                .clipShape(RoundedRectangle(cornerRadius: SolRadius.lg))
                            }
                        }

                        // Eroare salvare
                        if let saveError {
                            Text(saveError)
                                .font(.solCaption)
                                .foregroundStyle(Color.solDestructive)
                        }

                        // Buton salvează
                        SolomonButton(
                            editingSubscription == nil ? "Adaugă abonament" : "Salvează modificările",
                            icon: "checkmark"
                        ) {
                            save()
                        }
                        .opacity(isFormValid ? 1 : 0.4)
                        .disabled(!isFormValid)

                        // Buton ștergere (doar edit mode)
                        if editingSubscription != nil {
                            Button(role: .destructive) {
                                Haptics.warning()
                                showDeleteConfirmation = true
                            } label: {
                                Label("Șterge abonamentul", systemImage: "trash")
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
            .navigationTitle(editingSubscription == nil ? "Abonament nou" : "Editează abonament")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Renunță") { dismiss() }
                        .foregroundStyle(Color.solMuted)
                }
                if editingSubscription != nil {
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
                "Șterge abonamentul?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Șterge abonamentul", role: .destructive) {
                    deleteSubscription()
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

    private func iconFor(_ difficulty: CancellationDifficulty) -> String {
        switch difficulty {
        case .easy:   return "checkmark.circle.fill"
        case .medium: return "minus.circle.fill"
        case .hard:   return "xmark.circle.fill"
        }
    }

    // MARK: - Actions

    private func loadIfEditing() {
        guard let s = editingSubscription else { return }
        name = s.name
        amountText = String(s.amountMonthly.amount)
        cancellationDifficulty = s.cancellationDifficulty
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            saveError = "Numele abonamentului nu poate fi gol."
            return
        }
        guard amountValue > 0 else {
            saveError = "Suma trebuie să fie mai mare decât 0."
            return
        }

        let repo = CoreDataSubscriptionRepository(context: moc)
        do {
            let subscription = Subscription(
                id: editingSubscription?.id ?? UUID(),
                name: trimmedName,
                amountMonthly: Money(amountValue),
                lastUsedDaysAgo: nil,
                cancellationDifficulty: cancellationDifficulty
            )
            try repo.upsert(subscription)
            Haptics.success()
            dismiss()
        } catch {
            saveError = "Nu am putut salva: \(error.localizedDescription)"
        }
    }

    private func deleteSubscription() {
        guard let id = editingSubscription?.id else { return }
        let repo = CoreDataSubscriptionRepository(context: moc)
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

#Preview("Abonament nou") {
    SubscriptionEditView()
        .preferredColorScheme(.dark)
}

#Preview("Editează abonament") {
    SubscriptionEditView(editingSubscription: Subscription(
        id: UUID(),
        name: "Netflix",
        amountMonthly: Money(42),
        lastUsedDaysAgo: nil,
        cancellationDifficulty: .medium
    ))
    .preferredColorScheme(.dark)
}
