import SwiftUI
import os
import Observation
import SolomonCore
import SolomonStorage
import SolomonAnalytics
import SolomonMoments

// MARK: - TodayViewModel
//
// Orchestrează state-ul pentru TodayView:
//   - Safe-to-Spend real (SafeToSpendCalculator + CashFlowAnalyzer)
//   - Moment curent (MomentEngine cu TemplateLLMProvider fallback)
//   - Greeting personalizat din UserProfile

@Observable @MainActor
final class TodayViewModel {

    // MARK: - State

    var currentMoment: DisplayMoment?
    var recentMoments: [DisplayMoment] = []
    var safeToSpendFormatted: String = "..."
    var perDayFormatted: String?
    var greetingText: String = ""
    var userName: String = ""
    var hasUnreadAlert: Bool = false

    var isBudgetTight: Bool = false
    var isLoadingMoment: Bool = false

    // MARK: - Hero card display properties (v4 design)

    var safeToSpendRON: Int = 0
    var perDayRON: Int = 0
    var spentThisMonthRON: Int = 0
    var paydayDateFormatted: String = "—"
    var daysUntilPayday: Int = 0
    var safeToSpendStatus: String = "SIGUR"

    // MARK: - Editorial v3 — section 01 SOLOMON SPUNE / 02 OBIECTIV / 03 ISTORIC

    /// Toate abonamentele user-ului — folosit în moment-card "Audit abonamente"
    /// pentru a afișa sub-rows cu fiecare subscription (Netflix/HBO/Spotify, etc.).
    var subscriptions: [Subscription] = []
    /// Goal-ul activ cu cea mai recentă activitate (pentru section 02 OBIECTIV ACTIV)
    var activeGoal: Goal?

    /// Numărul formatat cu separator de mii românesc: "2.847"
    var safeToSpendAmountFormatted: String {
        guard safeToSpendRON > 0 else { return "..." }
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = "."
        f.usesGroupingSeparator = true
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: safeToSpendRON)) ?? "\(safeToSpendRON)"
    }

    /// Formatare sumă RON cu separator de mii: "1.353 RON"
    func formatRON(_ amount: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = "."
        f.usesGroupingSeparator = true
        f.maximumFractionDigits = 0
        return (f.string(from: NSNumber(value: amount)) ?? "\(amount)") + " RON"
    }

    // MARK: - Dependencies

    private var transactionRepo: (any TransactionRepository)?
    private var obligationRepo: (any ObligationRepository)?
    private var subscriptionRepo: (any SubscriptionRepository)?
    private var goalRepo: (any GoalRepository)?
    private var userProfileRepo: (any UserProfileRepository)?

    private let safeToSpendCalc = SafeToSpendCalculator()
    private var momentEngine = MomentEngine()    // recreat cu provider real în configure()

    // MARK: - Moment history (UserDefaults)

    private static let recentMomentsKey = "ro.solomon.recentMoments.v1"
    private static let maxRecentMoments = 5

    // MARK: - Configuration

    func configure(persistence: SolomonPersistenceController) {
        let ctx = persistence.container.viewContext
        self.transactionRepo  = CoreDataTransactionRepository(context: ctx)
        self.obligationRepo   = CoreDataObligationRepository(context: ctx)
        self.subscriptionRepo = CoreDataSubscriptionRepository(context: ctx)
        self.goalRepo         = CoreDataGoalRepository(context: ctx)
        self.userProfileRepo  = CoreDataUserProfileRepository(context: ctx)

        // Injectăm provider-ul real (MLX dacă e descărcat, Template fallback)
        let llm = ModelDownloadService.shared.makeLLMProvider()
        momentEngine = MomentEngine(llm: llm)

        // Restaurăm istoricul de momente din UserDefaults
        loadRecentMomentsCache()
    }

    // MARK: - Load

    func load() async {
        let profile = try? userProfileRepo?.fetchProfile()
        userName = profile?.demographics.name ?? "prietene"
        greetingText = greetingForCurrentHour()
        hasUnreadAlert = false

        // Lansăm budget și moment concurent:
        // refreshBudget e rapid (CoreData sync), refreshMoment suspendă pe LLM inference.
        // Cu async let, bugetul apare în UI fără să aștepte inferența LLM.
        // Load subscriptions + active goal pentru editorial v3 layout
        subscriptions = (try? subscriptionRepo?.fetchAll()) ?? []
        activeGoal = (try? goalRepo?.fetchAll())?.first

        async let budget: Void = refreshBudget(profile: profile)
        async let moment: Void = refreshMoment(profile: profile)
        await budget
        await moment
    }

    // MARK: - Budget calculation

    private func refreshBudget(profile: UserProfile?) async {
        guard let txRepo = transactionRepo else {
            safeToSpendFormatted = "—"
            return
        }

        guard let profile else {
            safeToSpendFormatted = "Adaugă date"
            perDayFormatted = "Setează profilul în Setări"
            safeToSpendStatus = "—"
            paydayDateFormatted = "—"
            return
        }

        let paydayDay: Int
        switch profile.financials.salaryFrequency {
        case .monthly(let day): paydayDay = day
        case .bimonthly(_, let secondDay): paydayDay = secondDay
        case .variable: paydayDay = 28
        }
        let daysUntilNext = daysUntilDayOfMonth(paydayDay)

        let salaryMid = profile.financials.salaryRange.midpointRON
        let lastPaydayDate = lastPaydayDate(payDay: paydayDay)
        let spentSincePayday = (try? txRepo.fetch(from: lastPaydayDate, to: Date()))?
            .filter { $0.isOutgoing }
            .reduce(0) { $0 + $1.amount.amount } ?? 0
        let estimatedBalance = max(0, salaryMid - spentSincePayday)

        let obligations = (try? obligationRepo?.fetchAll()) ?? []
        let obligationsRemaining = obligations.filter { o in
            let today = Calendar.current.component(.day, from: Date())
            if paydayDay > today {
                return o.dayOfMonth > today && o.dayOfMonth <= paydayDay
            } else {
                return o.dayOfMonth > today || o.dayOfMonth <= paydayDay
            }
        }.reduce(0) { $0 + $1.amount.amount }

        let cal = Calendar.current
        let from30 = cal.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let last30 = (try? txRepo.fetch(from: from30, to: Date()))?
            .filter { $0.isOutgoing } ?? []
        let velocity = last30.isEmpty ? 0 : last30.reduce(0) { $0 + $1.amount.amount } / 30

        // FAZA C5: pasăm venitul declarat ca referință → isTight devine relativ
        let budget = safeToSpendCalc.calculate(
            currentBalance: Money(estimatedBalance),
            obligationsRemaining: Money(obligationsRemaining),
            daysUntilNextPayday: daysUntilNext,
            velocityRONPerDay: Money(velocity),
            monthlyIncomeReference: Money(salaryMid)
        )

        safeToSpendFormatted = RomanianMoneyFormatter.format(budget.availableAfterObligations)
        perDayFormatted = "≈ \(budget.availablePerDay.amount) RON/zi · \(daysUntilNext) zile rămase"
        isBudgetTight = budget.isTight

        // v4 hero card properties
        safeToSpendRON      = max(0, Int(budget.availableAfterObligations.amount))
        perDayRON           = max(0, Int(budget.availablePerDay.amount))
        spentThisMonthRON   = Int(spentSincePayday)
        daysUntilPayday     = daysUntilNext
        paydayDateFormatted = formatPaydayDate(paydayDay: paydayDay)
        safeToSpendStatus   = budget.isTight ? "ATENȚIE" : "SIGUR"
    }

    // MARK: - Moment generation

    private func refreshMoment(profile: UserProfile?) async {
        guard let txRepo = transactionRepo else { return }
        isLoadingMoment = true
        defer { isLoadingMoment = false }

        // Construim snapshot
        let transactions = (try? txRepo.fetchAll()) ?? []
        let obligations = (try? obligationRepo?.fetchAll()) ?? []
        let subscriptions = (try? subscriptionRepo?.fetchAll()) ?? []
        let goals = (try? goalRepo?.fetchAll()) ?? []

        let snapshot = MomentEngine.Snapshot(
            userProfile: profile,
            transactions: transactions,
            obligations: obligations,
            subscriptions: subscriptions,
            goals: goals
        )

        // Verifică ce moment ar fi selectat (pentru unread badge + push critic)
        let selectedType = momentEngine.selectedType(snapshot: snapshot)
        hasUnreadAlert = selectedType == .spiralAlert || selectedType == .upcomingObligation || selectedType == .payday

        do {
            if let output = try await momentEngine.generateBestMoment(snapshot: snapshot) {
                let dm = DisplayMoment.from(output)
                currentMoment = dm
                // Push critic dacă app e în foreground și momentul e urgency-high
                if let type = selectedType, isCriticalMomentType(type) {
                    await BackgroundTaskService.shared.sendPushNotification(for: type)
                }
                // Salvăm în history
                appendToRecentMoments(dm)
            } else {
                currentMoment = nil
            }
        } catch {
            // Fallback: arătăm un moment static minim cu greeting-ul
            currentMoment = nil
            Logger.moments.error("Moment generation failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Helpers

    private func formatPaydayDate(paydayDay: Int) -> String {
        let cal = Calendar.current
        let today = cal.component(.day, from: Date())
        // FAZA A2: safeDate clamp-uiește dacă paydayDay > zilele lunii
        let referenceDate: Date = paydayDay <= today
            ? (cal.date(byAdding: .month, value: 1, to: Date()) ?? Date())
            : Date()
        let date = cal.safeDate(dayOfMonth: paydayDay, in: referenceDate)
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ro_RO")
        fmt.dateFormat = "d MMM"
        return fmt.string(from: date)
    }

    private func daysUntilDayOfMonth(_ targetDay: Int) -> Int {
        let cal = Calendar.current
        let today = cal.component(.day, from: Date())
        let daysInThisMonth = cal.range(of: .day, in: .month, for: Date())?.count ?? 30
        // FAZA A2: clamp targetDay la zilele disponibile (29/30/31 → 28/30 după lună)
        let clampedTarget = min(targetDay, daysInThisMonth)
        if clampedTarget > today {
            return clampedTarget - today
        } else {
            return daysInThisMonth - today + clampedTarget
        }
    }

    private func lastPaydayDate(payDay: Int) -> Date {
        let cal = Calendar.current
        let today = cal.component(.day, from: Date())
        let now = Date()
        // FAZA A2: safeDate clamp-uiește la ultima zi a lunii dacă payDay > daysInMonth
        if today >= payDay {
            return cal.safeDate(dayOfMonth: payDay, in: now)
        } else {
            let lastMonth = cal.date(byAdding: .month, value: -1, to: now) ?? now
            return cal.safeDate(dayOfMonth: payDay, in: lastMonth)
        }
    }

    private func greetingForCurrentHour() -> String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12:  return "Bună dimineața"
        case 12..<18: return "Bună ziua"
        case 18..<22: return "Bună seara"
        default:      return "Salut"
        }
    }

    /// True pentru momentele care justifică o notificare push chiar dacă app-ul e foreground.
    private func isCriticalMomentType(_ type: MomentType) -> Bool {
        switch type {
        case .spiralAlert, .upcomingObligation: return true
        default: return false
        }
    }

    // MARK: - Moment history cache

    /// Struct minimal Codable pentru persistare în UserDefaults.
    /// (DisplayMoment conține Color care nu e Codable direct.)
    private struct CachedMoment: Codable {
        let id: UUID
        let momentTypeRaw: String
        let title: String
        let subtitle: String
        let llmResponse: String
        let generatedAt: Date
        let systemIconName: String
        let badge: String?
    }

    private func appendToRecentMoments(_ moment: DisplayMoment) {
        var history = recentMoments
        // Evităm duplicate consecutive (același titlu + aceeași zi)
        if let last = history.first, last.title == moment.title { return }
        history.insert(moment, at: 0)
        if history.count > Self.maxRecentMoments {
            history = Array(history.prefix(Self.maxRecentMoments))
        }
        recentMoments = history
        saveRecentMomentsCache(history)
    }

    private func loadRecentMomentsCache() {
        guard let data = UserDefaults.standard.data(forKey: Self.recentMomentsKey),
              let cached = try? JSONDecoder().decode([CachedMoment].self, from: data)
        else { return }
        recentMoments = cached.map { c in
            DisplayMoment(
                id: c.id,
                momentTypeRaw: c.momentTypeRaw,
                title: c.title,
                subtitle: c.subtitle,
                llmResponse: c.llmResponse,
                generatedAt: c.generatedAt,
                systemIconName: c.systemIconName,
                badge: c.badge
            )
        }
    }

    private func saveRecentMomentsCache(_ moments: [DisplayMoment]) {
        let cached = moments.map { m in
            CachedMoment(
                id: m.id,
                momentTypeRaw: m.momentTypeRaw,
                title: m.title,
                subtitle: m.subtitle,
                llmResponse: m.llmResponse,
                generatedAt: m.generatedAt,
                systemIconName: m.systemIconName,
                badge: m.badge
            )
        }
        guard let data = try? JSONEncoder().encode(cached) else { return }
        UserDefaults.standard.set(data, forKey: Self.recentMomentsKey)
    }
}
