import SwiftUI
import SolomonCore
import SolomonStorage
import SolomonAnalytics

// MARK: - GoalsListView
//
// Lista obiectivelor financiare ale user-ului + buton "+" pentru add.
// Fiecare goal: card cu progress bar + suma curentă/target + deadline.

struct GoalsListView: View {

    @State private var goalReports: [GoalProgressReport] = []
    @State private var showAddGoal = false
    @State private var editingGoal: Goal?

    private let goalProgress = GoalProgress()
    private let cashFlow = CashFlowAnalyzer()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.solCanvas.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: SolSpacing.md) {
                        if goalReports.isEmpty {
                            emptyState
                        } else {
                            ForEach(goalReports, id: \.goal.id) { report in
                                GoalCard(report: report) {
                                    editingGoal = report.goal
                                }
                            }
                        }
                    }
                    .padding(.horizontal, SolSpacing.screenHorizontal)
                    .padding(.top, SolSpacing.lg)
                    .padding(.bottom, SolSpacing.hh)
                }
            }
            .navigationTitle("Obiective")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddGoal = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(LinearGradient.solHero)
                    }
                }
            }
            .sheet(isPresented: $showAddGoal, onDismiss: load) {
                GoalEditView()
            }
            .sheet(item: $editingGoal, onDismiss: load) { g in
                GoalEditView(editingGoal: g)
            }
            .onAppear { load() }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: SolSpacing.md) {
            IconContainer(systemName: "target", variant: .neon, size: 64, iconSize: 26)
            Text("Niciun obiectiv încă")
                .font(.solH3)
                .foregroundStyle(Color.solForeground)
            Text("Adaugă primul tău obiectiv financiar și Solomon te ajută să ajungi acolo.")
                .font(.solBody)
                .foregroundStyle(Color.solMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, SolSpacing.lg)

            SolomonButton("Adaugă obiectiv", icon: "plus") {
                showAddGoal = true
            }
            .padding(.top, SolSpacing.md)
        }
        .padding(SolSpacing.xl)
        .frame(maxWidth: .infinity, minHeight: 360)
        .solCard()
    }

    private func load() {
        let ctx = SolomonPersistenceController.shared.container.viewContext
        let goalRepo = CoreDataGoalRepository(context: ctx)
        let txRepo = CoreDataTransactionRepository(context: ctx)
        let goals = (try? goalRepo.fetchAll()) ?? []

        // Calculează savings pace din cash flow analysis
        let transactions = (try? txRepo.fetchAll()) ?? []
        let analysis = cashFlow.analyze(transactions: transactions)
        let pace = analysis.monthlySavingsAvg

        // Generează GoalProgressReport per goal
        goalReports = goals.map { goalProgress.evaluate(goal: $0, monthlyCurrentSavingPace: pace) }
    }
}

// MARK: - GoalCard

struct GoalCard: View {
    let report: GoalProgressReport
    let onTap: () -> Void

    private var goal: Goal { report.goal }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: SolSpacing.md) {
                HStack(alignment: .top, spacing: SolSpacing.md) {
                    IconContainer(
                        systemName: iconFor(goal.kind),
                        variant: variantFor(goal.kind),
                        size: 44,
                        iconSize: 18
                    )
                    VStack(alignment: .leading, spacing: 2) {
                        Text(goal.destination ?? goal.kind.displayNameRO)
                            .font(.solH3)
                            .foregroundStyle(Color.solForeground)
                        Text(goal.kind.displayNameRO)
                            .font(.solCaption)
                            .foregroundStyle(Color.solMuted)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.solMuted)
                }

                NeonProgressBar(
                    progress: report.progressFraction,
                    variant: variantForFeasibility,
                    label: "\(goal.amountSaved.amount) / \(goal.amountTarget.amount) RON",
                    trailing: "\(Int(report.progressFraction * 100))%"
                )

                // Feasibility info
                HStack(spacing: SolSpacing.xs) {
                    Image(systemName: feasibilityIcon)
                        .font(.system(size: 11))
                        .foregroundStyle(feasibilityColor)
                    Text(report.feasibility.displayNameRO)
                        .font(.solCaption)
                        .foregroundStyle(feasibilityColor)
                    Spacer()
                    if report.monthlyRequired.amount > 0 {
                        Text("\(report.monthlyRequired.amount) RON/lună necesar")
                            .font(.solCaption)
                            .foregroundStyle(Color.solMuted)
                    }
                }

                // Deadline info
                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.solMuted)
                    Text("Deadline: \(formatDate(goal.deadline))")
                        .font(.solCaption)
                        .foregroundStyle(Color.solMuted)
                    Spacer()
                    if report.monthsRemaining > 0 {
                        StatusBadge(
                            title: "\(report.monthsRemaining) luni",
                            kind: report.monthsRemaining <= 3 ? .warning : .neutral
                        )
                    }
                }
            }
            .padding(SolSpacing.cardStandard)
            .solCard()
        }
        .buttonStyle(.plain)
    }

    private var variantForFeasibility: NeonProgressBar.Variant {
        switch report.feasibility {
        case .easy, .onTrack:               return .success
        case .challengingButPossible:       return .warning
        case .unrealistic:                  return .danger
        }
    }

    private var feasibilityIcon: String {
        switch report.feasibility {
        case .easy:                         return "hare.fill"
        case .onTrack:                      return "checkmark.circle.fill"
        case .challengingButPossible:       return "exclamationmark.triangle.fill"
        case .unrealistic:                  return "xmark.octagon.fill"
        }
    }

    private var feasibilityColor: Color {
        switch report.feasibility {
        case .easy, .onTrack:               return .solPrimary
        case .challengingButPossible:       return .solWarning
        case .unrealistic:                  return .solDestructive
        }
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

    private func variantFor(_ kind: GoalKind) -> IconContainer.Variant {
        switch kind {
        case .vacation:      return .cyan
        case .car:           return .neon
        case .house:         return .cyan
        case .emergencyFund: return .warn
        case .debtPayoff:    return .danger
        case .custom:        return .tinted
        }
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "d MMM yyyy"
        f.locale = Locale(identifier: "ro_RO")
        return f.string(from: date)
    }
}

#Preview {
    GoalsListView()
        .preferredColorScheme(.dark)
}
