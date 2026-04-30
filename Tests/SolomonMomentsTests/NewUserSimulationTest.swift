import Testing
import Foundation
@testable import SolomonMoments
import SolomonCore
import SolomonLLM
import SolomonAnalytics

// MARK: - New User Full Simulation
//
// Simulăm Daniel, utilizator nou, ING, 5-8k RON.
// Data referință: 30 aprilie 2026 (salariu intrat pe 28 apr, chirie scadentă pe 1 mai).
// HBO Max nefolosit 95 zile → ghost subscription.

private let today = ISO8601DateFormatter().date(from: "2026-04-30T10:00:00Z")!
private let cal = Calendar.current

private func daysAgo(_ n: Int) -> Date {
    cal.date(byAdding: .day, value: -n, to: today)!
}
private func daysFromNow(_ n: Int) -> Date {
    cal.date(byAdding: .day, value: n, to: today)!
}
private func monthsAgo(_ m: Int, day: Int) -> Date {
    var comps = cal.dateComponents([.year, .month], from: today)
    comps.month! -= m
    comps.day = day
    comps.hour = 10
    return cal.date(from: comps) ?? today
}

// MARK: - Profil Daniel

private let danielProfile = UserProfile(
    demographics: DemographicProfile(
        name: "Daniel",
        addressing: .tu,
        ageRange: .range25to35
    ),
    financials: FinancialProfile(
        salaryRange: .range5to8,
        salaryFrequency: .monthly(dayOfMonth: 28),
        hasSecondaryIncome: false,
        primaryBank: .ing
    )
)

// MARK: - Tranzacții 2 luni

private func buildTransactions() -> [Transaction] {
    var txs: [Transaction] = []

    // ── Luna aceasta — din 28 apr ─────────────────────────────
    txs.append(Transaction(date: daysAgo(2), amount: Money(5_800),
        direction: .incoming, category: .unknown,
        merchant: "ING SALARY", source: .notificationParsed))
    txs.append(Transaction(date: daysAgo(2), amount: Money(78),
        direction: .outgoing, category: .foodDelivery,
        merchant: "Glovo", source: .notificationParsed))
    txs.append(Transaction(date: daysAgo(1), amount: Money(213),
        direction: .outgoing, category: .foodGrocery,
        merchant: "Kaufland", source: .notificationParsed))
    txs.append(Transaction(date: today, amount: Money(52),
        direction: .outgoing, category: .foodDelivery,
        merchant: "Bolt Food", source: .notificationParsed))

    // ── Martie ────────────────────────────────────────────────
    txs.append(Transaction(date: monthsAgo(1, day: 28), amount: Money(5_800),
        direction: .incoming, category: .unknown,
        merchant: "ING SALARY", source: .notificationParsed))
    txs.append(Transaction(date: monthsAgo(1, day: 1), amount: Money(2_200),
        direction: .outgoing, category: .rentMortgage,
        merchant: "Chirie", source: .manualEntry))
    txs.append(Transaction(date: monthsAgo(1, day: 5), amount: Money(189),
        direction: .outgoing, category: .utilities,
        merchant: "Enel", source: .notificationParsed))
    txs.append(Transaction(date: monthsAgo(1, day: 10), amount: Money(60),
        direction: .outgoing, category: .utilities,
        merchant: "Digi RCS", source: .notificationParsed))
    txs.append(Transaction(date: monthsAgo(1, day: 15), amount: Money(45),
        direction: .outgoing, category: .subscriptions,
        merchant: "Netflix", source: .notificationParsed))
    txs.append(Transaction(date: monthsAgo(1, day: 16), amount: Money(29),
        direction: .outgoing, category: .subscriptions,
        merchant: "Spotify", source: .notificationParsed))
    // Glovo x4 martie
    for (d, amt) in [(3,89),(8,67),(14,112),(22,54)] {
        txs.append(Transaction(date: monthsAgo(1, day: d), amount: Money(amt),
            direction: .outgoing, category: .foodDelivery,
            merchant: "Glovo", source: .notificationParsed))
    }
    // Supermarket x3
    for (d, amt, m) in [(2,198,"Lidl"),(9,245,"Kaufland"),(18,167,"Mega Image")] {
        txs.append(Transaction(date: monthsAgo(1, day: d), amount: Money(amt),
            direction: .outgoing, category: .foodGrocery,
            merchant: m, source: .notificationParsed))
    }
    txs.append(Transaction(date: monthsAgo(1, day: 20), amount: Money(389),
        direction: .outgoing, category: .shoppingOnline,
        merchant: "eMAG", source: .emailParsed))
    txs.append(Transaction(date: monthsAgo(1, day: 25), amount: Money(67),
        direction: .outgoing, category: .transport,
        merchant: "Bolt", source: .notificationParsed))

    // ── Februarie ─────────────────────────────────────────────
    txs.append(Transaction(date: monthsAgo(2, day: 28), amount: Money(5_800),
        direction: .incoming, category: .unknown,
        merchant: "ING SALARY", source: .notificationParsed))
    txs.append(Transaction(date: monthsAgo(2, day: 1), amount: Money(2_200),
        direction: .outgoing, category: .rentMortgage,
        merchant: "Chirie", source: .manualEntry))
    txs.append(Transaction(date: monthsAgo(2, day: 5), amount: Money(201),
        direction: .outgoing, category: .utilities,
        merchant: "Enel", source: .notificationParsed))
    txs.append(Transaction(date: monthsAgo(2, day: 10), amount: Money(60),
        direction: .outgoing, category: .utilities,
        merchant: "Digi RCS", source: .notificationParsed))
    // Glovo x5 feb (pattern!)
    for (d, amt) in [(4,78),(7,95),(12,62),(19,108),(26,74)] {
        txs.append(Transaction(date: monthsAgo(2, day: d), amount: Money(amt),
            direction: .outgoing, category: .foodDelivery,
            merchant: "Glovo", source: .notificationParsed))
    }
    return txs
}

// MARK: - Obligații

private let obligations = [
    Obligation(name: "Chirie", amount: Money(2_200), dayOfMonth: 1,
               kind: .rentMortgage, confidence: .declared),
    Obligation(name: "Enel", amount: Money(190), dayOfMonth: 5,
               kind: .utility, confidence: .estimated),
    Obligation(name: "Digi RCS", amount: Money(60), dayOfMonth: 10,
               kind: .utility, confidence: .declared)
]

// MARK: - Subscriptions (HBO ghost!)

private let subscriptions = [
    Subscription(name: "Netflix", amountMonthly: Money(45),
                 lastUsedDaysAgo: 3, cancellationDifficulty: .easy),
    Subscription(name: "Spotify", amountMonthly: Money(29),
                 lastUsedDaysAgo: 1, cancellationDifficulty: .easy),
    Subscription(name: "HBO Max", amountMonthly: Money(38),
                 lastUsedDaysAgo: 95, cancellationDifficulty: .medium)  // GHOST
]

// MARK: - Goal

private let goals = [
    Goal(kind: .vacation,
         destination: "Vacanță Grecia",
         amountTarget: Money(3_000),
         amountSaved: Money(200),
         deadline: daysFromNow(90))
]

// MARK: - Suite

@Suite("🔬 Simulare utilizator nou — Daniel / ING")
struct NewUserSimulationTest {

    // ── 1. PARSER NOTIFICĂRI ING ─────────────────────────────────────────

    @Test("📱 Parser notificări ING — 5 formate reale")
    func testINGParsing() {
        let rawMessages = [
            "Plată 89,00 RON la Glovo",
            "Salariu creditat: 5.800,00 RON",
            "Ai efectuat o plată de 213,50 RON la Kaufland",
            "Tranzacție debitare 52,00 RON la Bolt Food",
            "Enel Energie  factura 189,00 RON"
        ]

        print("\n══════════════════════════════════════════════════")
        print("📱  PARSER NOTIFICĂRI ING")
        print("══════════════════════════════════════════════════")
        var parsed = 0
        for raw in rawMessages {
            if let tx = BankNotificationParser.parse(raw: raw) {
                let dir = tx.direction == .incoming ? "⬇ IN " : "⬆ OUT"
                let merchant = tx.merchant ?? "—"
                print("\(dir)  \(String(format: "%6.0f", tx.amount.amount)) RON  │  \(merchant)  │  \(tx.category.rawValue)")
                parsed += 1
            } else {
                print("❌  Nu parsat: \"\(raw)\"")
            }
        }
        print("Parsat \(parsed)/\(rawMessages.count) notificări")
        #expect(parsed >= 4)
    }

    // ── 2. SAFE TO SPEND ─────────────────────────────────────────────────

    @Test("💰 SafeToSpend — 2 zile după salariu, chirie mâine")
    func testSafeToSpend() {
        // Cheltuieli din 28 apr: 78+213+52 = 343 RON
        // Balance estimat: 5800 - 343 = 5457 RON
        // Obligații rămase: chirie 2200 + enel 190 + digi 60 = 2450 RON
        let calc = SafeToSpendCalculator()
        let result = calc.calculate(
            currentBalance: Money(5_457),
            obligationsRemaining: Money(2_450),
            daysUntilNextPayday: 29,
            velocityRONPerDay: Money(55),
            monthlyIncomeReference: Money(5_800)
        )

        print("\n══════════════════════════════════════════════════")
        print("💰  SAFE TO SPEND (30 apr, 2 zile după salariu)")
        print("══════════════════════════════════════════════════")
        print("Balance estimat:      5.457 RON  (5800 - 343 chelt.)")
        print("Obligații rămase:     2.450 RON  (chirie+enel+digi)")
        print("─────────────────────────────────────────────────")
        print("✅  Disponibil real:  \(result.availableAfterObligations.amount) RON")
        print("✅  Pe zi:            \(result.availablePerDay.amount) RON/zi × 29 zile")
        print("⚠️  Budget tight?     \(result.isTight ? "DA" : "Nu")")
        if let crit = result.daysUntilCritical {
            print("⏱  Zile critice:    \(crit) zile la ritmul actual")
        }

        #expect(result.availableAfterObligations.amount > 2_000)
        #expect(!result.isTight)
    }

    // ── 3. MOMENTUL SELECTAT ─────────────────────────────────────────────

    @Test("🎯 Ce moment alege Solomon pentru Daniel azi")
    @MainActor func testMomentSelection() async {
        let engine = MomentEngine(llm: TemplateLLMProvider())
        let snapshot = MomentEngine.Snapshot(
            userProfile: danielProfile,
            transactions: buildTransactions(),
            obligations: obligations,
            subscriptions: subscriptions,
            goals: goals,
            referenceDate: today
        )

        let selected = engine.selectedType(snapshot: snapshot)

        print("\n══════════════════════════════════════════════════")
        print("🎯  MOMENTUL SELECTAT DE SOLOMON")
        print("══════════════════════════════════════════════════")
        print("Selectat: \(selected?.rawValue ?? "nil — niciun moment")")
        print("")
        print("Context: Chirie 2200 RON scadentă mâine (1 mai)")
        print("         HBO ghost 95 zile (38 RON/lună)")
        print("         Glovo pattern: 9 comenzi în 2 luni")
    }

    // ── 4. MOMENTUL COMPLET GENERAT ──────────────────────────────────────

    @Test("💬 Solomon generează momentul complet (TemplateLLM)")
    @MainActor func testMomentGeneration() async throws {
        let engine = MomentEngine(llm: TemplateLLMProvider())
        let snapshot = MomentEngine.Snapshot(
            userProfile: danielProfile,
            transactions: buildTransactions(),
            obligations: obligations,
            subscriptions: subscriptions,
            goals: goals,
            referenceDate: today
        )

        guard let output = try await engine.generateBestMoment(snapshot: snapshot) else {
            print("\n⚠️  MomentEngine → nil (date insuficiente?)")
            return
        }

        print("\n══════════════════════════════════════════════════")
        print("💬  SOLOMON SPUNE (TemplateLLM):")
        print("══════════════════════════════════════════════════")
        print("Tip moment:  \(output.momentType.rawValue)")
        print("─────────────────────────────────────────────────")
        print(output.llmResponse)
        print("══════════════════════════════════════════════════")

        #expect(!output.llmResponse.isEmpty)
    }

    // ── 5. FORȚĂM SUBSCRIPTION AUDIT ─────────────────────────────────────

    @Test("👻 Subscription audit — HBO ghost 95 zile")
    @MainActor func testSubscriptionAudit() async throws {
        let engine = MomentEngine(llm: TemplateLLMProvider())
        let snapshot = MomentEngine.Snapshot(
            userProfile: danielProfile,
            transactions: buildTransactions(),
            obligations: obligations,
            subscriptions: subscriptions,
            goals: goals,
            referenceDate: today
        )

        guard let output = try await engine.generateSubscriptionAudit(snapshot: snapshot) else {
            print("\n⚠️  generateSubscriptionAudit → nil")
            return
        }

        print("\n══════════════════════════════════════════════════")
        print("👻  SUBSCRIPTION AUDIT — Solomon detectează HBO ghost:")
        print("══════════════════════════════════════════════════")
        print(output.llmResponse)
        print("══════════════════════════════════════════════════")
        #expect(output.llmResponse.lowercased().contains("hbo") ||
                output.llmResponse.lowercased().contains("38") ||
                output.llmResponse.lowercased().contains("abon"))
    }

    // ── 6. FORȚĂM SPIRAL (cu IFN) ────────────────────────────────────────

    @Test("🌀 Spiral alert — Daniel fără IFN (scor scăzut)")
    @MainActor func testSpiralAlert() async throws {
        let engine = MomentEngine(llm: TemplateLLMProvider())
        let snapshot = MomentEngine.Snapshot(
            userProfile: danielProfile,
            transactions: buildTransactions(),
            obligations: obligations,
            subscriptions: subscriptions,
            goals: goals,
            referenceDate: today
        )

        let output = try await engine.generateSpiralAlert(snapshot: snapshot)

        print("\n══════════════════════════════════════════════════")
        print("🌀  SPIRAL DETECTOR")
        print("══════════════════════════════════════════════════")
        if let out = output {
            print("⚠️  Spiral detectat!")
            print(out.llmResponse)
        } else {
            print("✅  Niciun spiral — Daniel e financiar sănătos:")
            print("   • Salariu stabil 5800 RON lunar")
            print("   • Nicio datorie IFN/BNPL")
            print("   • Obligații < 45% din venit")
        }
    }

    // ── 7. FLUX COMPLET: NOTIFICARE ING → MOMENT ─────────────────────────

    @Test("📲 Flux complet: notificare ING salariu → moment Solomon")
    @MainActor func testFullFlow() async throws {
        let engine = MomentEngine(llm: TemplateLLMProvider())

        // 1. Parser preia notificarea ING
        let rawNotif = "Salariu creditat: 5.800,00 RON"
        guard let salaryTx = BankNotificationParser.parse(raw: rawNotif) else {
            Issue.record("Parser nu a recunoscut notificarea de salariu")
            return
        }

        print("\n══════════════════════════════════════════════════")
        print("📲  FLUX COMPLET: ING → Solomon")
        print("══════════════════════════════════════════════════")
        print("1️⃣  Notificare ING: \"\(rawNotif)\"")
        print("   Parser → \(salaryTx.direction.rawValue) \(salaryTx.amount.amount) RON, merchant: \(salaryTx.merchant ?? "?")")

        // 2. Snapshot cu tranzacția nouă
        var allTxs = buildTransactions()
        allTxs.insert(salaryTx, at: 0)

        let snapshot = MomentEngine.Snapshot(
            userProfile: danielProfile,
            transactions: allTxs,
            obligations: obligations,
            subscriptions: subscriptions,
            goals: goals,
            referenceDate: today
        )
        print("2️⃣  Snapshot: \(allTxs.count) tranzacții total")

        // 3. Solomon decide momentul
        let momentType = engine.selectedType(snapshot: snapshot)
        print("3️⃣  Moment selectat: \(momentType?.rawValue ?? "nil")")

        // 4. Generăm răspunsul
        if let output = try await engine.generateBestMoment(snapshot: snapshot) {
            print("4️⃣  Solomon răspunde [\(output.momentType.rawValue)]:\n")
            let lines = output.llmResponse.components(separatedBy: "\n")
            for line in lines { print("   \(line)") }
        } else {
            print("4️⃣  ⚠️  Niciun moment generat")
        }
        print("══════════════════════════════════════════════════")
    }
}
