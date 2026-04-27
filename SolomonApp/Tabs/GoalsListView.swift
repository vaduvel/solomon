import SwiftUI
import SolomonCore
import SolomonStorage
import SolomonAnalytics

// MARK: - GoalsListView
//
// Lista obiectivelor financiare ale user-ului + buton "+" pentru add.
// Fiecare goal: card cu progress bar + suma curentă/target + deadline.

struct GoalsListView: View {

    @State private var goals: [Goal] = []
    @State private var showAddGoal = false
    @State private var editingGoal: Goal?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.solCanvas.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: SolSpacing.md) {
                        if goals.isEmpty {
                            emptyState
                        } else {
                            ForEach(goals) { goal in
                                GoalCard(goal: goal) {
                                    editingGoal = goal
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
        let repo = CoreDataGoalRepository(context: ctx)
        goals = (try? repo.fetchAll()) ?? []
    }
}

// MARK: - GoalCard

struct GoalCard: View {
    let goal: Goal
    let onTap: () -> Void

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
                    progress: goal.progressFraction,
                    variant: .success,
                    label: "\(goal.amountSaved.amount) / \(goal.amountTarget.amount) RON",
                    trailing: "\(Int(goal.progressFraction * 100))%"
                )

                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.solMuted)
                    Text("Deadline: \(formatDate(goal.deadline))")
                        .font(.solCaption)
                        .foregroundStyle(Color.solMuted)
                    Spacer()
                    if let monthsLeft = monthsUntil(goal.deadline) {
                        StatusBadge(
                            title: "\(monthsLeft) luni",
                            kind: monthsLeft <= 3 ? .warning : .neutral
                        )
                    }
                }
            }
            .padding(SolSpacing.cardStandard)
            .solCard()
        }
        .buttonStyle(.plain)
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

    private func monthsUntil(_ date: Date) -> Int? {
        let cal = Calendar.current
        let comps = cal.dateComponents([.month], from: Date(), to: date)
        return comps.month
    }
}

#Preview {
    GoalsListView()
        .preferredColorScheme(.dark)
}
