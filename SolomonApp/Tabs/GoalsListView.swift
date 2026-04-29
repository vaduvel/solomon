import SwiftUI
import SolomonCore
import SolomonStorage
import SolomonAnalytics

// MARK: - GoalsListView (Claude Design v3)
//
// Pixel-fidel cu `Solomon DS / screens/goals.html`:
//   - MeshBackground (mint/blue/violet)
//   - SolAppBar "SOLOMON · OBIECTIVE" + greeting "Pe drum" + "+" iconbtn
//   - Hero card mint cu SolProgressRing 120pt (% mediu) + total saved/target + chips
//   - InsightCard mint "SOLOMON · PROIECȚIE" cu CTA "Crește contribuția" / "Vezi proiecție"
//   - Section header "OBIECTIVELE TALE · X active"
//   - SolListCard cu goal-rows: icon colorat per kind + nume/deadline + chip + progress bar + meta
//   - Buton dashed "+ Adaugă obiectiv nou"
//
// Business logic păstrat 1:1: GoalProgressReport, GoalProgress, CashFlowAnalyzer, sheet add/edit.

struct GoalsListView: View {

    @State private var goalReports: [GoalProgressReport] = []
    @State private var showAddGoal = false
    @State private var editingGoal: Goal?

    private let goalProgress = GoalProgress()
    private let cashFlow = CashFlowAnalyzer()

    var body: some View {
        NavigationStack {
            ZStack {
                MeshBackground()

                ScrollView {
                    VStack(spacing: SolSpacing.md) {
                        // AppBar
                        SolAppBar(
                            brand: "SOLOMON · OBIECTIVE",
                            greeting: greetingText
                        ) {
                            SolIconButton(systemName: "plus") {
                                showAddGoal = true
                            }
                        }

                        if goalReports.isEmpty {
                            emptyState
                        } else {
                            heroCard
                            insightCard
                            sectionHeader
                            goalList
                            addGoalButton
                        }
                    }
                    .padding(.horizontal, SolSpacing.screenHorizontal)
                    .padding(.bottom, SolSpacing.hh)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showAddGoal, onDismiss: load) {
                GoalEditView().solStandardSheet()
            }
            .sheet(item: $editingGoal, onDismiss: load) { g in
                GoalEditView(editingGoal: g).solStandardSheet()
            }
            .onAppear { load() }
        }
    }

    // MARK: - Aggregate metrics

    private var totalSaved: Int {
        goalReports.reduce(0) { $0 + $1.goal.amountSaved.amount }
    }

    private var totalTarget: Int {
        goalReports.reduce(0) { $0 + $1.goal.amountTarget.amount }
    }

    private var averageProgress: Double {
        guard totalTarget > 0 else { return 0 }
        return Double(totalSaved) / Double(totalTarget)
    }

    private var totalMonthlyRequired: Int {
        goalReports.reduce(0) { $0 + $1.monthlyRequired.amount }
    }

    private var maxMonthsRemaining: Int {
        goalReports.map { $0.monthsRemaining }.max() ?? 0
    }

    private var greetingText: String {
        if goalReports.isEmpty { return "Începe" }
        let onTrackCount = goalReports.filter { $0.feasibility == .easy || $0.feasibility == .onTrack }.count
        if onTrackCount == goalReports.count { return "Pe drum" }
        if onTrackCount == 0 { return "Reajustează" }
        return "Aproape"
    }

    // MARK: - Hero

    @ViewBuilder
    private var heroCard: some View {
        SolHeroCard(accent: .mint) {
            HStack(alignment: .top, spacing: 18) {
                SolProgressRing(
                    progress: CGFloat(min(1.0, max(0.0, averageProgress))),
                    label: "PROGRES",
                    size: 120,
                    lineWidth: 9,
                    accent: .mint
                )

                VStack(alignment: .leading, spacing: 2) {
                    SolHeroLabel("ACUMULAT TOTAL")
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(formatNumber(totalSaved))
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(Color.white)
                            .tracking(-1)
                            .monospacedDigit()
                            .shadow(color: Color.solMintExact.opacity(0.18), radius: 30)
                        Text("RON")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.4))
                            .padding(.leading, 4)
                    }
                    .padding(.top, 2)
                    Text("din \(formatNumber(totalTarget)) țintă")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.5))
                        .padding(.top, 2)

                    HStack(spacing: 6) {
                        if totalMonthlyRequired > 0 {
                            SolChip("+\(formatNumber(totalMonthlyRequired)) lună", kind: .mint)
                        }
                        if maxMonthsRemaining > 0 {
                            SolChip("\(maxMonthsRemaining) luni", kind: .muted)
                        }
                    }
                    .padding(.top, 14)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } badge: {
            SolHeroBadge("\(goalReports.count) ACTIVE", accent: .mint)
        }
    }

    // MARK: - Insight

    @ViewBuilder
    private var insightCard: some View {
        SolInsightCard(
            icon: "clock",
            label: "SOLOMON · PROIECȚIE",
            timestamp: "recalc azi",
            accent: .mint
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text(projectionText)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.75))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    SolPrimaryButton("Crește contribuția", accent: .mint) {
                        if let first = goalReports.first {
                            editingGoal = first.goal
                        }
                    }
                    SolSecondaryButton("Vezi proiecție") { }
                }
            }
        }
    }

    private var projectionText: String {
        if let primary = goalReports.first {
            let monthly = max(1, primary.monthlyRequired.amount)
            let monthsLabel = primary.monthsRemaining > 0 ? "\(primary.monthsRemaining) luni" : "termen scurt"
            return "Dacă ții ritmul de +\(formatNumber(monthly)) RON/lună, ajungi la \(primary.goal.kind.displayNameRO) în \(monthsLabel)."
        }
        return "Setează o contribuție lunară și Solomon proiectează când ajungi la fiecare obiectiv."
    }

    // MARK: - Section header

    @ViewBuilder
    private var sectionHeader: some View {
        SolSectionHeaderRow("OBIECTIVELE TALE", meta: "\(goalReports.count) active")
            .padding(.top, SolSpacing.xs)
    }

    // MARK: - List

    @ViewBuilder
    private var goalList: some View {
        SolListCard {
            ForEach(Array(goalReports.enumerated()), id: \.element.goal.id) { index, report in
                if index > 0 { SolHairlineDivider() }
                goalRow(report: report)
            }
        }
    }

    @ViewBuilder
    private func goalRow(report: GoalProgressReport) -> some View {
        Button {
            Haptics.light()
            editingGoal = report.goal
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                // Head
                HStack(alignment: .center, spacing: 12) {
                    goalIcon(for: report.goal.kind)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(report.goal.destination ?? report.goal.kind.displayNameRO)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.white)
                        Text(deadlineSubtitle(for: report))
                            .font(.system(size: 11))
                            .foregroundStyle(Color.white.opacity(0.4))
                    }

                    Spacer()

                    let chip = chipFor(report.feasibility)
                    SolChip(chip.label, kind: chip.kind)
                }

                // Progress
                SolLinearProgress(
                    progress: CGFloat(min(1.0, max(0.0, report.progressFraction))),
                    accent: accentFor(report.goal.kind),
                    height: 6,
                    glow: true
                )

                // Meta
                HStack {
                    HStack(spacing: 0) {
                        Text(formatNumber(report.goal.amountSaved.amount))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.white)
                            .monospacedDigit()
                        Text(" / \(formatNumber(report.goal.amountTarget.amount)) RON")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.white.opacity(0.6))
                            .monospacedDigit()
                    }
                    Spacer()
                    if report.monthlyRequired.amount > 0 {
                        Text("+\(formatNumber(report.monthlyRequired.amount))/lună")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.white.opacity(0.4))
                            .monospacedDigit()
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func goalIcon(for kind: GoalKind) -> some View {
        let accent = accentFor(kind)
        ZStack {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(accent.iconGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .stroke(accent.color.opacity(0.25), lineWidth: 1)
                )
            Image(systemName: iconFor(kind))
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(accent.color)
        }
        .frame(width: 38, height: 38)
    }

    // MARK: - Add button

    @ViewBuilder
    private var addGoalButton: some View {
        Button {
            Haptics.light()
            showAddGoal = true
        } label: {
            Text("+ Adaugă obiectiv nou")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.6))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.03))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(
                            Color.white.opacity(0.15),
                            style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                        )
                )
        }
        .buttonStyle(.plain)
        .padding(.top, SolSpacing.xs)
    }

    // MARK: - Empty state

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: SolSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(SolAccent.mint.iconGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.solMintExact.opacity(0.25), lineWidth: 1)
                    )
                Image(systemName: "target")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(Color.solMintExact)
            }
            .frame(width: 64, height: 64)
            .padding(.top, SolSpacing.lg)

            Text("Niciun obiectiv încă")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.white)

            Text("Adaugă primul tău obiectiv financiar și Solomon te ajută să ajungi acolo.")
                .font(.system(size: 13))
                .foregroundStyle(Color.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, SolSpacing.lg)
                .lineSpacing(2)

            SolPrimaryButton("Adaugă primul obiectiv", accent: .mint, fullWidth: true) {
                showAddGoal = true
            }
            .padding(.top, SolSpacing.md)
            .padding(.horizontal, SolSpacing.xl)
        }
        .padding(SolSpacing.xl)
        .frame(maxWidth: .infinity, minHeight: 360)
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

    private func accentFor(_ kind: GoalKind) -> SolAccent {
        switch kind {
        case .emergencyFund:    return .mint
        case .vacation:         return .blue
        case .car, .house:      return .violet
        case .debtPayoff:       return .rose
        case .custom:           return .mint
        }
    }

    private func iconFor(_ kind: GoalKind) -> String {
        switch kind {
        case .vacation:         return "airplane"
        case .car:              return "car.fill"
        case .house:            return "house.fill"
        case .emergencyFund:    return "shield.fill"
        case .debtPayoff:       return "creditcard.fill"
        case .custom:           return "target"
        }
    }

    private func chipFor(_ feasibility: GoalFeasibility) -> (label: String, kind: SolChip.Kind) {
        switch feasibility {
        case .easy, .onTrack:               return ("on track", .mint)
        case .challengingButPossible:       return ("restant",  .warn)
        case .unrealistic:                  return ("blocat",   .rose)
        }
    }

    private func deadlineSubtitle(for report: GoalProgressReport) -> String {
        let monthYear = formatMonthYear(report.goal.deadline)
        if report.monthsRemaining > 0 {
            return "\(monthYear) · \(report.monthsRemaining) luni"
        }
        return monthYear
    }

    private func formatMonthYear(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM yyyy"
        f.locale = Locale(identifier: "ro_RO")
        return f.string(from: date)
    }

    private func formatNumber(_ value: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = "."
        f.locale = Locale(identifier: "ro_RO")
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    // MARK: - Data

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

#Preview {
    GoalsListView()
        .preferredColorScheme(.dark)
}
