import SwiftUI
import Observation
import SolomonCore
import SolomonStorage
import SolomonAnalytics

// MARK: - AnalysisView (Tab 2 — Analiză)
//
// Design 1:1 cu Solomon DS / screens/analysis.html.
// MeshBackground (blue top-left) + AppBar + filtre pills + Hero blue (cu bars chart) +
// InsightCard rose + StatGrid 2x2 + lista categorii cu progress.

struct AnalysisView: View {

    @State private var vm = AnalysisViewModel()
    @State private var selectedRange: String = "Lună"

    private let ranges: [String] = ["Săpt.", "Lună", "3 luni", "An"]

    var body: some View {
        NavigationStack {
            ZStack {
                MeshBackground(
                    topLeftAccent: .blue,
                    midRightAccent: .blue,
                    bottomLeftAccent: .violet
                )

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // App bar
                        SolAppBar(
                            brand: "SOLOMON · ANALIZĂ",
                            greeting: vm.currentMonthLabel.isEmpty ? "Aprilie" : vm.currentMonthLabel
                        ) {
                            SolIconButton(systemName: "line.3.horizontal.decrease") { }
                            SolIconButton(systemName: "arrow.up") { }
                        }

                        // Pills row
                        rangePills

                        // Hero — total cheltuit
                        heroSpentCard
                            .padding(.top, 4)

                        // Insight rose — detecție pattern
                        insightDetectionCard

                        // Stats 2x2 (Venit + Rate ECON.)
                        statsGrid

                        // Section header CATEGORII
                        SolSectionHeaderRow(
                            "CATEGORII · \(currentMonthUpper)",
                            meta: "\(vm.categories.count) din 12"
                        )
                        .padding(.top, 4)

                        // Categories list
                        categoriesList

                        Spacer(minLength: 32)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, SolSpacing.sm)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .task {
            vm.configure(persistence: SolomonPersistenceController.shared)
            await vm.load()
        }
    }

    // MARK: - Sub-views

    private var currentMonthUpper: String {
        vm.currentMonthLabel.isEmpty ? "APRILIE" : vm.currentMonthLabel.uppercased()
    }

    @ViewBuilder
    private var rangePills: some View {
        HStack(spacing: 8) {
            ForEach(ranges, id: \.self) { r in
                SolPill(r, isActive: selectedRange == r) {
                    selectedRange = r
                }
            }
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var heroSpentCard: some View {
        SolHeroCard(accent: .blue) {
            VStack(alignment: .leading, spacing: 10) {
                SolHeroLabel("TOTAL \(currentMonthUpper) · 22 ZILE")

                SolHeroAmount(
                    amount: heroBigAmount,
                    decimals: heroDecimals,
                    currency: "RON",
                    accent: .blue
                )

                // Meta row (delta + per-day)
                HStack(spacing: 8) {
                    Text(deltaWithArrow)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(vm.deltaIsWarning ? Color.solRoseExact : Color.solMintExact)
                    Rectangle()
                        .fill(Color.white.opacity(0.10))
                        .frame(width: 1, height: 9)
                    Text("\(perDayRON)/zi")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.45))
                    Spacer(minLength: 0)
                }
                .padding(.top, 2)

                // Bars chart
                barsChart
                    .padding(.top, 6)

                // Bar labels
                HStack {
                    ForEach(barLabels.indices, id: \.self) { i in
                        Text(barLabels[i])
                            .font(.system(size: 10))
                            .foregroundStyle(Color.white.opacity(0.35))
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        } badge: {
            SolHeroBadge("CHELTUIT", accent: .blue)
        }
    }

    /// Bars din 7 săptămâni — folosim `vm.monthlyTrend` extins (sau valori procentuale fallback dacă < 7).
    @ViewBuilder
    private var barsChart: some View {
        let heights = barHeights
        let activeIdx = activeBarIndex
        let overIdx = overBarIndex

        HStack(alignment: .bottom, spacing: 6) {
            ForEach(heights.indices, id: \.self) { i in
                let pct = heights[i]
                let state: BarState = {
                    if i == overIdx { return .over }
                    if i == activeIdx { return .active }
                    return .calm
                }()

                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(barFill(state))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(barStroke(state), lineWidth: 1)
                    )
                    .shadow(color: state == .active ? Color.solBlueExact.opacity(0.4) : .clear, radius: 12)
                    .frame(maxWidth: .infinity)
                    .frame(height: max(20, 120 * pct))
            }
        }
        .frame(height: 120)
    }

    private enum BarState { case calm, active, over }

    private func barFill(_ s: BarState) -> LinearGradient {
        switch s {
        case .calm:
            return LinearGradient(
                colors: [Color.solBlueExact.opacity(0.40), Color.solBlueExact.opacity(0.10)],
                startPoint: .top, endPoint: .bottom
            )
        case .active:
            return LinearGradient(
                colors: [Color.solBlueExact, Color.solBlueExact.opacity(0.30)],
                startPoint: .top, endPoint: .bottom
            )
        case .over:
            return LinearGradient(
                colors: [Color.solRoseExact, Color.solRoseExact.opacity(0.20)],
                startPoint: .top, endPoint: .bottom
            )
        }
    }

    private func barStroke(_ s: BarState) -> Color {
        switch s {
        case .calm:   return Color.solBlueExact.opacity(0.15)
        case .active: return Color.solBlueExact.opacity(0.30)
        case .over:   return Color.solRoseExact.opacity(0.30)
        }
    }

    /// 7 înălțimi normalizate (0...1) din monthlyTrend (rezamplat) sau fallback decorativ.
    private var barHeights: [Double] {
        let trend = vm.monthlyTrend
        let fallback: [Double] = [0.42, 0.58, 0.88, 0.64, 0.72, 0.38, 0.54]
        guard !trend.isEmpty else { return fallback }

        // Dacă avem măcar valori, le mapăm la 7 sloturi (cu repeat dacă e nevoie)
        let maxVal = max(trend.map { $0.amount }.max() ?? 1, 1)
        var out: [Double] = []
        for i in 0..<7 {
            let idx = trend.count == 1 ? 0 : Int(round(Double(i) * Double(trend.count - 1) / 6.0))
            let v = trend[min(idx, trend.count - 1)].amount / maxVal
            out.append(min(max(v, 0.15), 1.0))
        }
        return out
    }

    private var activeBarIndex: Int { 4 }
    private var overBarIndex: Int { 2 }

    private let barLabels: [String] = ["S1", "S2", "S3 ↑", "S4", "S5 ←", "S6", "S7"]

    private var heroBigAmount: String {
        let v = vm.currentMonthSpentRON
        if v == 0 { return "4.187" }
        // Format RO cu separator de mii „."
        return formatThousands(v)
    }

    private var heroDecimals: String? { vm.currentMonthSpentRON == 0 ? ",40" : nil }

    private var deltaWithArrow: String {
        guard !vm.deltaPercentText.isEmpty, vm.deltaPercentText != "—" else {
            return "↑ +12% vs luna trecută"
        }
        let arrow = vm.deltaIsWarning ? "↑" : "↓"
        return "\(arrow) \(vm.deltaPercentText) vs luna trecută"
    }

    private var perDayRON: String {
        let v = vm.currentMonthSpentRON > 0 ? vm.currentMonthSpentRON / 22 : 190
        return "\(v)"
    }

    private func formatThousands(_ v: Int) -> String {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "ro_RO")
        f.numberStyle = .decimal
        f.groupingSeparator = "."
        return f.string(from: NSNumber(value: v)) ?? "\(v)"
    }

    @ViewBuilder
    private var insightDetectionCard: some View {
        SolInsightCard(
            icon: "exclamationmark.triangle.fill",
            label: "SOLOMON · DETECȚIE",
            timestamp: "săpt. 3",
            accent: .rose
        ) {
            VStack(alignment: .leading, spacing: 12) {
                (Text("Cheltuielile pe ")
                    + Text("Mâncare livrată").bold()
                    + Text(" au crescut ")
                    + Text("+187 RON").foregroundColor(.solRoseExact)
                    + Text(" săptămâna 3. Pattern: vineri-seară Glovo + sâmbătă Bolt Food."))
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.75))
                    .lineSpacing(2)

                HStack(spacing: 8) {
                    SolPrimaryButton("Setează limită", accent: .rose) { }
                    SolSecondaryButton("Vezi tranzacții") { }
                }
            }
        }
    }

    @ViewBuilder
    private var statsGrid: some View {
        HStack(spacing: 10) {
            SolStatCard(
                label: "VENIT",
                name: "Salariu + freelance",
                value: "8.450 RON",
                meta: "+450 vs martie",
                metaAccent: .mint,
                icon: "chart.line.uptrend.xyaxis",
                iconAccent: .mint
            )
            SolStatCard(
                label: "RATE ECON.",
                name: "din venit",
                value: "31%",
                meta: "țintă 35%",
                metaAccent: nil,
                icon: "plus",
                iconAccent: .violet
            )
        }
    }

    @ViewBuilder
    private var categoriesList: some View {
        if vm.categories.isEmpty {
            SolListCard {
                VStack(spacing: 6) {
                    Image(systemName: "chart.pie")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.white.opacity(0.4))
                    Text("Nicio cheltuială")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.7))
                    Text("Adaugă tranzacții ca Solomon să vadă pattern-uri.")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .padding(.horizontal, 16)
            }
        } else {
            SolListCard {
                ForEach(Array(vm.categories.enumerated()), id: \.element.id) { idx, cat in
                    categoryRow(cat)
                    if idx < vm.categories.count - 1 {
                        SolHairlineDivider()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func categoryRow(_ cat: CategoryBreakdown) -> some View {
        let accent = accentForCategory(cat)
        let chipInfo = chipForCategory(cat)
        let amountColor: Color = (cat.fraction > 1.0) ? Color.solRoseExact : Color.white
        let limitText = limitTextForCategory(cat)

        HStack(alignment: .center, spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(accent.iconGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(accent.color.opacity(0.25), lineWidth: 1)
                    )
                Image(systemName: cat.iconName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(accent.color)
            }
            .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(cat.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.white)
                    Spacer()
                    Text(cat.amountFormatted)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(amountColor)
                        .monospacedDigit()
                }

                HStack {
                    Text(limitText)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.4))
                    Spacer()
                    SolChip(chipInfo.label, kind: chipInfo.kind)
                }

                SolLinearProgress(
                    progress: CGFloat(min(cat.fraction, 1.0)),
                    accent: accent,
                    height: 4
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    // MARK: - Category accent / chip helpers

    private func accentForCategory(_ cat: CategoryBreakdown) -> SolAccent {
        if cat.fraction > 1.0 { return .rose }
        if cat.fraction > 0.85 { return .amber }
        // Mapare grosieră pe baza color-ului din VM (care vine de la grupul de categorie)
        // Fallback la blue.
        return .blue
    }

    private struct ChipInfo {
        let label: String
        let kind: SolChip.Kind
    }

    private func chipForCategory(_ cat: CategoryBreakdown) -> ChipInfo {
        let limit = cat.totalAmount
        let amount = cat.amount
        if cat.fraction > 1.0 {
            let over = Int((amount - limit).rounded())
            return ChipInfo(label: "+\(over)", kind: .rose)
        }
        if cat.fraction > 0.85 {
            let pct = Int((cat.fraction * 100).rounded())
            return ChipInfo(label: "\(pct)%", kind: .warn)
        }
        let diff = Int((limit - amount).rounded())
        return ChipInfo(label: "-\(diff)", kind: .mint)
    }

    private func limitTextForCategory(_ cat: CategoryBreakdown) -> String {
        if cat.fraction > 1.0 {
            return "peste limită \(Int(cat.totalAmount))"
        }
        return "limită \(Int(cat.totalAmount))"
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

@Observable @MainActor
final class AnalysisViewModel {

    var categories: [CategoryBreakdown] = []
    var monthlyTrend: [MonthTrend] = []
    var currentMonthSpentRON: Int = 0
    var lastMonthSpentRON: Int = 0
    var currentMonthLabel: String = ""
    var deltaPercentText: String = ""
    var savingsText: String = ""
    var deltaIsWarning: Bool = false
    /// Guard împotriva fetch-urilor concurente (NU împotriva re-fetch — în-flight only).
    private var isLoading: Bool = false
    /// Cache key bazat pe (count, latest date) — invalidează când userul adaugă/șterge tranzacții.
    private var lastSnapshotKey: String = ""

    private var transactionRepo: (any TransactionRepository)?
    private let patternDetector = PatternDetector()
    private let cashFlowAnalyzer = CashFlowAnalyzer()

    func configure(persistence: SolomonPersistenceController) {
        let ctx = persistence.container.viewContext
        self.transactionRepo = CoreDataTransactionRepository(context: ctx)
    }

    func load() async {
        // FIX 3: invalidăm cache-ul când nr de tranzacții sau data ultimei tranzacții
        // s-au schimbat (user a adăugat/șters din alt tab) → datele rămân fresh,
        // dar nu refacem fetch dacă nimic nu s-a schimbat.
        guard !isLoading, let repo = transactionRepo else { return }
        isLoading = true
        defer { isLoading = false }

        let now = Date()
        let cal = Calendar.current

        // Fetch ultimele 90 zile pentru pattern detection
        guard let from90 = cal.date(byAdding: .day, value: -90, to: now) else { return }
        let txs = (try? repo.fetch(from: from90, to: now)) ?? []

        // Cache key — invalidare automată la modificări
        let latestDate = txs.first?.date.timeIntervalSince1970 ?? 0
        let snapshotKey = "\(txs.count)|\(Int(latestDate))"
        if snapshotKey == lastSnapshotKey { return }
        lastSnapshotKey = snapshotKey

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
