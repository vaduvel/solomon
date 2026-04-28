import SwiftUI
import SolomonCore
import SolomonStorage
import SolomonAnalytics

// MARK: - AnalysisView (Tab 2 — Analiză)
//
// Prezintă breakdown-ul cheltuielilor pe categorii, trend lunar, și predicții.
// Faza 10: layout complet cu date mock. Faza 11+: SolomonAnalytics real.

struct AnalysisView: View {

    @StateObject private var vm = AnalysisViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SolSpacing.xl) {

                    // KPI summary card
                    monthSummaryCard

                    // Categorii top
                    categoryBreakdown

                    // Trend 3 luni
                    trendSection

                    Spacer(minLength: SolSpacing.xxxl)
                }
                .padding(.top, SolSpacing.sm)
            }
            .background(Color.solCanvas)
            .navigationTitle("Analiză")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            vm.configure(persistence: SolomonPersistenceController.shared)
            await vm.load()
        }
    }

    // MARK: - Sub-views

    @ViewBuilder
    private var monthSummaryCard: some View {
        VStack(spacing: SolSpacing.base) {
            HStack(spacing: 0) {
                summaryKPI(
                    label: "Cheltuieli \(vm.currentMonthLabel.lowercased())",
                    value: vm.currentMonthSpentRON > 0 ? "\(vm.currentMonthSpentRON) RON" : "—",
                    color: Color.solForeground
                )
                Divider().frame(height: 40)
                summaryKPI(
                    label: "vs. luna trecută",
                    value: vm.deltaPercentText,
                    color: vm.deltaIsWarning ? .solWarning : .solPrimary
                )
                Divider().frame(height: 40)
                summaryKPI(
                    label: "Diferență",
                    value: vm.savingsText,
                    color: vm.savingsText.hasPrefix("+") ? .solPrimary : .secondary
                )
            }
        }
        .padding(SolSpacing.cardStandard)
        .solCard()
        .padding(.horizontal, SolSpacing.lg)
    }

    @ViewBuilder
    private func summaryKPI(label: String, value: String, color: Color) -> some View {
        VStack(spacing: SolSpacing.xs) {
            Text(value)
                .font(.title3.weight(.semibold))
                .foregroundStyle(color)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, SolSpacing.xs)
    }

    @ViewBuilder
    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: SolSpacing.sm) {
            Text("Top categorii")
                .solSectionHeader()
                .padding(.horizontal, SolSpacing.lg)

            if vm.categories.isEmpty {
                EmptyStateView(
                    icon: "chart.pie",
                    title: "Nicio cheltuială",
                    subtitle: "Adaugă tranzacții ca Solomon să vadă pattern-uri."
                )
                .solCard()
                .padding(.horizontal, SolSpacing.lg)
            } else {
                VStack(spacing: SolSpacing.sm) {
                    ForEach(vm.categories) { cat in
                        categoryRow(cat)
                    }
                }
                .padding(.horizontal, SolSpacing.lg)
            }
        }
    }

    @ViewBuilder
    private func categoryRow(_ cat: CategoryBreakdown) -> some View {
        HStack(spacing: SolSpacing.md) {
            Image(systemName: cat.iconName)
                .font(.title3)
                .foregroundStyle(cat.color)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(cat.name)
                        .font(.body)
                        .foregroundStyle(Color.solForeground)
                    Spacer()
                    Text(cat.amountFormatted)
                        .font(.solMono)
                        .foregroundStyle(Color.solForeground)
                }

                NeonProgressBar(
                    progress: cat.fraction,
                    variant: .info,
                    height: 3
                )
            }
        }
        .padding(SolSpacing.base)
        .solCard()
    }

    @ViewBuilder
    private var trendSection: some View {
        VStack(alignment: .leading, spacing: SolSpacing.sm) {
            Text("Tendință 3 luni")
                .solSectionHeader()
                .padding(.horizontal, SolSpacing.lg)

            HStack(alignment: .bottom, spacing: SolSpacing.md) {
                ForEach(vm.monthlyTrend) { month in
                    trendBar(month)
                }
            }
            .frame(height: 140)
            .padding(SolSpacing.lg)
            .solCard()
            .padding(.horizontal, SolSpacing.lg)
        }
    }

    @ViewBuilder
    private func trendBar(_ month: MonthTrend) -> some View {
        VStack(spacing: SolSpacing.xs) {
            Text("\(Int(month.amount))")
                .font(.caption.monospacedDigit())
                .foregroundStyle(month.isCurrentMonth ? Color.solPrimary : .secondary)
            Spacer()
            RoundedRectangle(cornerRadius: SolRadius.sm, style: .continuous)
                .fill(month.isCurrentMonth ? AnyShapeStyle(LinearGradient.solHero) : AnyShapeStyle(Color.solCard))
                .frame(maxWidth: 48)
                .frame(height: month.barHeight)
                .overlay(
                    RoundedRectangle(cornerRadius: SolRadius.sm, style: .continuous)
                        .stroke(month.isCurrentMonth ? Color.clear : Color.solBorder, lineWidth: 1)
                )
            Text(month.label)
                .font(.footnote)
                .foregroundStyle(month.isCurrentMonth ? Color.solPrimary : .secondary)
        }
        .frame(maxWidth: .infinity)
    }

}

// MARK: - Supporting models

struct CategoryBreakdown: Identifiable {
    let id = UUID()
    let name: String
    let amount: Double
    let totalAmount: Double
    let iconName: String
    let color: Color

    var fraction: Double { min(amount / totalAmount, 1.0) }
    var amountFormatted: String { "\(Int(amount)) RON" }
}

struct MonthTrend: Identifiable {
    let id = UUID()
    let label: String
    let amount: Double
    let maxAmount: Double
    let isCurrentMonth: Bool

    var barHeight: CGFloat { CGFloat(80 * (amount / maxAmount)) }
}

// MARK: - AnalysisViewModel

@MainActor
final class AnalysisViewModel: ObservableObject {

    @Published var categories: [CategoryBreakdown] = []
    @Published var monthlyTrend: [MonthTrend] = []
    @Published var currentMonthSpentRON: Int = 0
    @Published var lastMonthSpentRON: Int = 0
    @Published var currentMonthLabel: String = ""
    @Published var deltaPercentText: String = ""
    @Published var savingsText: String = ""
    @Published var deltaIsWarning: Bool = false

    private var transactionRepo: (any TransactionRepository)?
    private let patternDetector = PatternDetector()
    private let cashFlowAnalyzer = CashFlowAnalyzer()

    func configure(persistence: SolomonPersistenceController) {
        let ctx = persistence.container.viewContext
        self.transactionRepo = CoreDataTransactionRepository(context: ctx)
    }

    func load() async {
        guard let repo = transactionRepo else { return }
        let now = Date()
        let cal = Calendar.current

        // Fetch ultimele 90 zile pentru pattern detection
        guard let from90 = cal.date(byAdding: .day, value: -90, to: now) else { return }
        let txs = (try? repo.fetch(from: from90, to: now)) ?? []

        // Pattern detection
        let report = patternDetector.detect(transactions: txs, windowDays: 90, referenceDate: now)

        // Top categorii (max 6 pentru afișare)
        let totalSpent = txs.filter { $0.isOutgoing }.reduce(0) { $0 + $1.amount.amount }
        let totalDouble = max(1.0, Double(totalSpent))

        categories = report.topCategories.prefix(6).map { c in
            CategoryBreakdown(
                name: c.category.displayNameRO,
                amount: Double(c.totalAmount.amount),
                totalAmount: totalDouble,
                iconName: iconForCategory(c.category),
                color: colorForCategory(c.category)
            )
        }

        // Trend lunar (3 luni)
        var trend: [MonthTrend] = []
        var maxMonth = 0
        for offset in stride(from: 2, through: 0, by: -1) {
            guard let monthDate = cal.date(byAdding: .month, value: -offset, to: now) else { continue }
            let comps = cal.dateComponents([.year, .month], from: monthDate)
            guard let monthStart = cal.date(from: comps),
                  let nextMonth = cal.date(byAdding: .month, value: 1, to: monthStart),
                  let monthEnd = cal.date(byAdding: .day, value: -1, to: nextMonth) else { continue }

            let monthTxs = (try? repo.fetch(from: monthStart, to: monthEnd)) ?? []
            let spent = monthTxs.filter { $0.isOutgoing }.reduce(0) { $0 + $1.amount.amount }
            maxMonth = max(maxMonth, spent)

            let label = monthLabel(monthDate)
            trend.append(MonthTrend(
                label: label,
                amount: Double(spent),
                maxAmount: Double(maxMonth),
                isCurrentMonth: offset == 0
            ))
        }
        // Recalculează maxAmount pe toate
        let trueMax = trend.map { $0.amount }.max() ?? 1
        monthlyTrend = trend.map { m in
            MonthTrend(label: m.label, amount: m.amount, maxAmount: max(trueMax, 1), isCurrentMonth: m.isCurrentMonth)
        }

        // KPI summary
        currentMonthSpentRON = Int(monthlyTrend.last?.amount ?? 0)
        lastMonthSpentRON = monthlyTrend.count >= 2 ? Int(monthlyTrend[monthlyTrend.count - 2].amount) : 0
        currentMonthLabel = monthlyTrend.last?.label ?? ""

        if lastMonthSpentRON > 0 && currentMonthSpentRON > 0 {
            let delta = ((Double(currentMonthSpentRON) - Double(lastMonthSpentRON)) / Double(lastMonthSpentRON)) * 100
            let prefix = delta > 0 ? "+" : ""
            deltaPercentText = "\(prefix)\(Int(delta.rounded()))%"
            deltaIsWarning = delta > 5
        } else {
            deltaPercentText = "—"
            deltaIsWarning = false
        }

        // Savings (positive = economisit prin reducere cheltuieli)
        if lastMonthSpentRON > currentMonthSpentRON {
            savingsText = "+\(lastMonthSpentRON - currentMonthSpentRON) RON"
        } else if currentMonthSpentRON > lastMonthSpentRON {
            savingsText = "−\(currentMonthSpentRON - lastMonthSpentRON) RON"
        } else {
            savingsText = "0 RON"
        }
    }

    // MARK: - Helpers

    private func monthLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ro_RO")
        f.dateFormat = "MMM"
        return f.string(from: date).capitalized
    }

    private func iconForCategory(_ c: TransactionCategory) -> String {
        switch c {
        case .foodDelivery:    return "bag.fill"
        case .foodDining:      return "fork.knife"
        case .foodGrocery:     return "cart.fill"
        case .transport:       return "car.fill"
        case .utilities:       return "bolt.fill"
        case .rentMortgage:    return "house.fill"
        case .subscriptions:   return "play.circle.fill"
        case .shoppingOnline:  return "shippingbox.fill"
        case .shoppingOffline: return "bag.fill"
        case .entertainment:   return "ticket.fill"
        case .health:          return "cross.fill"
        case .loansBank, .loansIFN, .bnpl: return "creditcard.fill"
        case .travel:          return "airplane"
        case .savings:         return "banknote.fill"
        case .unknown:         return "questionmark.circle.fill"
        }
    }

    private func colorForCategory(_ c: TransactionCategory) -> Color {
        switch c.group {
        case .essentials: return .solInfo
        case .lifestyle:  return .solWarning
        case .debt:       return .solDestructive
        case .savings:    return .solPrimary
        case .other:      return .solMuted
        }
    }
}

// MARK: - Preview

#Preview {
    AnalysisView()
}
