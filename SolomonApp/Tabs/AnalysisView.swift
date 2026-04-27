import SwiftUI

// MARK: - AnalysisView (Tab 2 — Analiză)
//
// Prezintă breakdown-ul cheltuielilor pe categorii, trend lunar, și predicții.
// Faza 10: layout complet cu date mock. Faza 11+: SolomonAnalytics real.

struct AnalysisView: View {

    @StateObject private var vm = AnalysisViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.solCanvas.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: SolSpacing.sectionGap) {

                        // Sumar lună curentă
                        monthSummaryCard

                        // Breakdown categorii
                        categoryBreakdown

                        // Trend 3 luni
                        trendSection

                        Spacer(minLength: SolSpacing.hh)
                    }
                    .padding(.top, SolSpacing.xl)
                }
            }
            .navigationTitle("Analiză")
            .navigationBarTitleDisplayMode(.large)
        }
        .task { await vm.load() }
    }

    // MARK: - Sub-views

    @ViewBuilder
    private var monthSummaryCard: some View {
        VStack(spacing: SolSpacing.base) {
            HStack {
                summaryKPI(label: "Cheltuieli april", value: "3.240 RON", color: .solTextPrimary)
                Divider()
                    .frame(height: 40)
                    .background(Color.solBorder)
                summaryKPI(label: "vs. luna trecută", value: "+8%", color: .solWarning)
                Divider()
                    .frame(height: 40)
                    .background(Color.solBorder)
                summaryKPI(label: "Economisit", value: "450 RON", color: .solMint)
            }
        }
        .padding(SolSpacing.xl)
        .solCard()
        .padding(.horizontal, SolSpacing.screenHorizontal)
    }

    @ViewBuilder
    private func summaryKPI(label: String, value: String, color: Color) -> some View {
        VStack(spacing: SolSpacing.xs) {
            Text(value)
                .font(.solHeadingMD)
                .foregroundStyle(color)
                .monospacedDigit()
            Text(label)
                .font(.solCaption)
                .foregroundStyle(Color.solTextMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var categoryBreakdown: some View {
        VStack(spacing: SolSpacing.base) {
            sectionHeader("Top categorii")

            VStack(spacing: SolSpacing.sm) {
                ForEach(vm.categories) { cat in
                    categoryRow(cat)
                }
            }
            .padding(.horizontal, SolSpacing.screenHorizontal)
        }
    }

    @ViewBuilder
    private func categoryRow(_ cat: CategoryBreakdown) -> some View {
        HStack(spacing: SolSpacing.md) {
            ZStack {
                Circle()
                    .fill(cat.color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: cat.iconName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(cat.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(cat.name)
                    .font(.solBodyMD)
                    .foregroundStyle(Color.solTextPrimary)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.solSurface)
                            .frame(height: 4)
                        Capsule()
                            .fill(cat.color)
                            .frame(width: geo.size.width * cat.fraction, height: 4)
                    }
                }
                .frame(height: 4)
            }

            Text(cat.amountFormatted)
                .font(.solMonoSM)
                .foregroundStyle(Color.solTextPrimary)
                .monospacedDigit()
        }
        .padding(SolSpacing.md)
        .solCard()
    }

    @ViewBuilder
    private var trendSection: some View {
        VStack(spacing: SolSpacing.base) {
            sectionHeader("Tendință 3 luni")

            HStack(alignment: .bottom, spacing: SolSpacing.sm) {
                ForEach(vm.monthlyTrend) { month in
                    trendBar(month)
                }
            }
            .frame(height: 120)
            .padding(SolSpacing.xl)
            .solCard()
            .padding(.horizontal, SolSpacing.screenHorizontal)
        }
    }

    @ViewBuilder
    private func trendBar(_ month: MonthTrend) -> some View {
        VStack(spacing: SolSpacing.xs) {
            Spacer()
            RoundedRectangle(cornerRadius: SolRadius.sm, style: .continuous)
                .fill(month.isCurrentMonth ? Color.solMint : Color.solSurface)
                .frame(width: 40, height: month.barHeight)
                .overlay(
                    RoundedRectangle(cornerRadius: SolRadius.sm, style: .continuous)
                        .stroke(month.isCurrentMonth ? Color.clear : Color.solBorder, lineWidth: 1)
                )
            Text(month.label)
                .font(.solCaption)
                .foregroundStyle(month.isCurrentMonth ? Color.solMint : Color.solTextMuted)
        }
        .frame(maxWidth: .infinity)
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.solCaption)
                .foregroundStyle(Color.solTextMuted)
                .textCase(.uppercase)
                .tracking(1.2)
            Spacer()
        }
        .padding(.horizontal, SolSpacing.screenHorizontal)
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

    func load() async {
        // Mock data — Faza 11 va folosi SolomonAnalytics real
        let total = 3240.0
        categories = [
            CategoryBreakdown(name: "Livrare mâncare", amount: 680, totalAmount: total, iconName: "bag.fill", color: .solWarning),
            CategoryBreakdown(name: "Rate + chirie", amount: 1500, totalAmount: total, iconName: "house.fill", color: .solInfo),
            CategoryBreakdown(name: "Abonamente", amount: 320, totalAmount: total, iconName: "play.circle.fill", color: .solMintDim),
            CategoryBreakdown(name: "Transport", amount: 280, totalAmount: total, iconName: "car.fill", color: .solTextSecondary),
            CategoryBreakdown(name: "Sănătate", amount: 160, totalAmount: total, iconName: "cross.fill", color: .solDanger),
        ]

        let maxAmount = 4100.0
        monthlyTrend = [
            MonthTrend(label: "Feb", amount: 4100, maxAmount: maxAmount, isCurrentMonth: false),
            MonthTrend(label: "Mar", amount: 3810, maxAmount: maxAmount, isCurrentMonth: false),
            MonthTrend(label: "Apr", amount: 3240, maxAmount: maxAmount, isCurrentMonth: true),
        ]
    }
}

// MARK: - Preview

#Preview {
    AnalysisView()
}
