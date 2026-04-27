import SwiftUI
import SolomonCore
import SolomonStorage
import SolomonAnalytics

// MARK: - TodayViewModel
//
// Faza 17: wired la repositories CoreData + SafeToSpendCalculator + CashFlowAnalyzer.
// Calculează Safe-to-Spend real din salariul user-ului + obligații rămase + velocity.

@MainActor
final class TodayViewModel: ObservableObject {

    // MARK: - Published state

    @Published var currentMoment: DisplayMoment?
    @Published var recentMoments: [DisplayMoment] = []
    @Published var safeToSpendFormatted: String = "..."
    @Published var perDayFormatted: String?
    @Published var greetingText: String = ""
    @Published var userName: String = ""
    @Published var hasUnreadAlert: Bool = false
    @Published var showCanIAfford: Bool = false

    /// True dacă bugetul e foarte strâns
    @Published var isBudgetTight: Bool = false

    // MARK: - Dependencies

    private var transactionRepo: (any TransactionRepository)?
    private var obligationRepo: (any ObligationRepository)?
    private var userProfileRepo: (any UserProfileRepository)?

    private let safeToSpendCalc = SafeToSpendCalculator()
    private let cashFlowAnalyzer = CashFlowAnalyzer()

    // MARK: - Configuration

    func configure(persistence: SolomonPersistenceController) {
        let ctx = persistence.container.viewContext
        self.transactionRepo  = CoreDataTransactionRepository(context: ctx)
        self.obligationRepo   = CoreDataObligationRepository(context: ctx)
        self.userProfileRepo  = CoreDataUserProfileRepository(context: ctx)
    }

    // MARK: - Load

    func load() async {
        // Greeting + user name
        let profile = try? userProfileRepo?.fetchProfile()
        userName = profile?.demographics.name ?? "prieten"
        greetingText = greetingForCurrentHour()

        // Calculează Safe-to-Spend real
        await refreshBudget(profile: profile)

        // Mock moments (vor veni din MomentOrchestrator în Faza 19)
        currentMoment = .previewCanIAfford
        recentMoments = [.previewPayday, .previewSpiral]
    }

    // MARK: - Budget calculation

    private func refreshBudget(profile: UserProfile?) async {
        guard let txRepo = transactionRepo else {
            safeToSpendFormatted = "—"
            return
        }

        // Cum aproximăm currentBalance?
        // În absența integrării bancare reale, calculăm:
        //   balance ≈ salariu_lunar - cheltuieli din ziua salariului până azi
        guard let profile else {
            safeToSpendFormatted = "Adaugă date"
            perDayFormatted = "Setează profilul în Setări"
            return
        }

        // 1) Daysuntilnext payday
        let paydayDay: Int
        switch profile.financials.salaryFrequency {
        case .monthly(let day): paydayDay = day
        case .bimonthly(_, let secondDay): paydayDay = secondDay
        case .variable: paydayDay = 28  // default
        }
        let daysUntilNext = daysUntilDayOfMonth(paydayDay)

        // 2) Currentbalance estimate: salary midpoint - spent since payday
        let salaryMid = profile.financials.salaryRange.midpointRON
        let lastPaydayDate = lastPaydayDate(payDay: paydayDay)
        let spentSincePayday = (try? txRepo.fetch(from: lastPaydayDate, to: Date()))?
            .filter { $0.isOutgoing }
            .reduce(0) { $0 + $1.amount.amount } ?? 0
        let estimatedBalance = max(0, salaryMid - spentSincePayday)

        // 3) Obligations remaining până la următorul payday
        let obligations = (try? obligationRepo?.fetchAll()) ?? []
        let obligationsRemaining = obligations.filter { o in
            // dayOfMonth e în viitor (până la payday)
            let today = Calendar.current.component(.day, from: Date())
            if paydayDay > today {
                return o.dayOfMonth > today && o.dayOfMonth <= paydayDay
            } else {
                return o.dayOfMonth > today || o.dayOfMonth <= paydayDay
            }
        }.reduce(0) { $0 + $1.amount.amount }

        // 4) Velocity (cheltuieli ultimele 30 zile / 30)
        let cal = Calendar.current
        let from30 = cal.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let last30 = (try? txRepo.fetch(from: from30, to: Date()))?
            .filter { $0.isOutgoing } ?? []
        let velocity = last30.isEmpty ? 0 : last30.reduce(0) { $0 + $1.amount.amount } / 30

        // 5) Compute
        let budget = safeToSpendCalc.calculate(
            currentBalance: Money(estimatedBalance),
            obligationsRemaining: Money(obligationsRemaining),
            daysUntilNextPayday: daysUntilNext,
            velocityRONPerDay: Money(velocity)
        )

        // 6) Format output
        safeToSpendFormatted = formatRON(budget.availableAfterObligations.amount)
        perDayFormatted = "≈ \(budget.availablePerDay.amount) RON/zi · \(daysUntilNext) zile rămase"
        isBudgetTight = budget.isTight
    }

    // MARK: - Helpers

    private func formatRON(_ amount: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = "."
        f.locale = Locale(identifier: "ro_RO")
        let str = f.string(from: NSNumber(value: amount)) ?? "\(amount)"
        return "\(str) RON"
    }

    private func daysUntilDayOfMonth(_ targetDay: Int) -> Int {
        let cal = Calendar.current
        let today = cal.component(.day, from: Date())
        if targetDay > today {
            return targetDay - today
        } else {
            // Trecem de luna asta — calculăm până la luna viitoare
            let daysInMonth = cal.range(of: .day, in: .month, for: Date())?.count ?? 30
            return daysInMonth - today + targetDay
        }
    }

    private func lastPaydayDate(payDay: Int) -> Date {
        let cal = Calendar.current
        let today = cal.component(.day, from: Date())
        let now = Date()
        if today >= payDay {
            // Salariul a fost luna asta
            return cal.date(bySetting: .day, value: payDay, of: now) ?? now
        } else {
            // Salariul a fost luna trecută
            let lastMonth = cal.date(byAdding: .month, value: -1, to: now) ?? now
            return cal.date(bySetting: .day, value: payDay, of: lastMonth) ?? lastMonth
        }
    }

    private func greetingForCurrentHour() -> String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12:  return "Bună dimineața 👋"
        case 12..<18: return "Bună ziua 👋"
        case 18..<22: return "Bună seara 👋"
        default:      return "Salut 👋"
        }
    }
}
