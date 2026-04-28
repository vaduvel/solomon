import SwiftUI
import SolomonCore
import SolomonStorage

// MARK: - GoalEditView
//
// Create / edit obiectiv financiar (vacanță, mașină, casă, etc.).
// Validări: amountTarget > 0, deadline >= 1 lună de la azi.

struct GoalEditView: View {

    @Environment(\.dismiss) private var dismiss

    let editingGoal: Goal?

    @State private var kind: GoalKind = .vacation
    @State private var destination: String = ""
    @State private var amountTargetRON: Int = 5000
    @State private var amountSavedRON: Int = 0
    @State private var deadline: Date = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()
    @State private var saveError: String?

    init(editingGoal: Goal? = nil) {
        self.editingGoal = editingGoal
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.solCanvas.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: SolSpacing.lg) {
                        VStack(alignment: .leading, spacing: SolSpacing.sm) {
                            Text(editingGoal == nil ? "Obiectiv nou" : "Editează obiectiv")
                                .font(.solH2)
                                .foregroundStyle(Color.solForeground)
                            Text("Solomon te ajută să ajungi acolo cu mici economii lunare.")
                                .font(.solBody)
                                .foregroundStyle(Color.solMuted)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, SolSpacing.lg)

                        // Tip — picker stil HIG
                        VStack(alignment: .leading, spacing: SolSpacing.sm) {
                            sectionLabel("TIP OBIECTIV")
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: SolSpacing.sm) {
                                ForEach(GoalKind.allCases, id: \.self) { k in
                                    SelectableChip(
                                        title: k.displayNameRO,
                                        icon: iconFor(k),
                                        isSelected: kind == k
                                    ) {
                                        kind = k
                                    }
                                }
                            }
                        }

                        // Destination
                        VStack(alignment: .leading, spacing: SolSpacing.xs) {
                            sectionLabel("DESCRIERE (OPȚIONAL)")
                            SolomonTextInput(
                                placeholder: placeholder(for: kind),
                                text: $destination,
                                icon: iconFor(kind)
                            )
                        }

                        // Amount target
                        VStack(alignment: .leading, spacing: SolSpacing.xs) {
                            sectionLabel("SUMA TARGET (RON)")
                            HStack {
                                TextField("5000", value: $amountTargetRON, format: .number)
                                    .font(.solDisplay)
                                    .foregroundStyle(LinearGradient.solHero)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.center)
                                    .padding(.vertical, SolSpacing.lg)
                                Text("RON")
                                    .font(.solH2)
                                    .foregroundStyle(Color.solMuted)
                            }
                            .frame(maxWidth: .infinity)
                            .background(Color.solCard)
                            .clipShape(RoundedRectangle(cornerRadius: SolRadius.xxl))
                        }

                        // Saved amount
                        VStack(alignment: .leading, spacing: SolSpacing.xs) {
                            sectionLabel("SUMA STRÂNSĂ DEJA (RON)")
                            SolomonTextInput(
                                placeholder: "0",
                                text: Binding(
                                    get: { String(amountSavedRON) },
                                    set: { amountSavedRON = Int($0) ?? 0 }
                                ),
                                icon: "banknote.fill",
                                keyboardType: .numberPad
                            )
                        }

                        // Deadline
                        VStack(alignment: .leading, spacing: SolSpacing.xs) {
                            sectionLabel("DEADLINE")
                            HStack {
                                Image(systemName: "calendar")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(Color.solMuted)
                                DatePicker("", selection: $deadline,
                                           in: nextMonth...,
                                           displayedComponents: [.date])
                                    .labelsHidden()
                                    .tint(Color.solPrimary)
                                Spacer()
                            }
                            .padding(SolSpacing.base)
                            .frame(height: 56)
                            .background(Color.solCard)
                            .clipShape(RoundedRectangle(cornerRadius: SolRadius.xxl))
                        }

                        // Progress preview
                        if amountSavedRON > 0 && amountTargetRON > 0 {
                            VStack(alignment: .leading, spacing: SolSpacing.sm) {
                                sectionLabel("PROGRES")
                                NeonProgressBar(
                                    progress: min(1, Double(amountSavedRON) / Double(amountTargetRON)),
                                    variant: .success,
                                    label: "\(amountSavedRON) / \(amountTargetRON) RON",
                                    trailing: "\(Int(Double(amountSavedRON) / Double(amountTargetRON) * 100))%"
                                )
                                .padding(SolSpacing.base)
                                .solCard()
                            }
                        }

                        if let saveError {
                            Text(saveError)
                                .font(.solCaption)
                                .foregroundStyle(Color.solDestructive)
                        }

                        SolomonButton(
                            editingGoal == nil ? "Adaugă obiectiv" : "Salvează modificările",
                            icon: "checkmark"
                        ) {
                            save()
                        }
                        .opacity(amountTargetRON > 0 ? 1 : 0.4)
                        .disabled(amountTargetRON == 0)
                    }
                    .padding(.horizontal, SolSpacing.screenHorizontal)
                    .padding(.bottom, SolSpacing.hh)
                }
            }
            .navigationTitle("Obiectiv")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Anulează") { dismiss() }
                        .foregroundStyle(Color.solMuted)
                }
            }
            .onAppear { loadIfEditing() }
        }
    }

    private var nextMonth: Date {
        Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    }

    private func iconFor(_ kind: GoalKind) -> String {
        switch kind {
        case .vacation:      return "airplane"
        case .car:           return "car.fill"
        case .house:         return "house.fill"
        case .emergencyFund: return "shield.fill"
        case .debtPayoff:    return "creditcard.fill"
        case .custom:        return "target"
        }
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

    @ViewBuilder
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.solMicro)
            .foregroundStyle(Color.solMuted)
            .tracking(1.2)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func loadIfEditing() {
        guard let g = editingGoal else { return }
        kind = g.kind
        destination = g.destination ?? ""
        amountTargetRON = g.amountTarget.amount
        amountSavedRON = g.amountSaved.amount
        deadline = g.deadline
    }

    private func save() {
        let ctx = SolomonPersistenceController.shared.container.viewContext
        let repo = CoreDataGoalRepository(context: ctx)

        guard amountTargetRON > 0 else {
            saveError = "Suma target trebuie să fie mai mare decât 0."
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
}

#Preview {
    GoalEditView()
        .preferredColorScheme(.dark)
}
