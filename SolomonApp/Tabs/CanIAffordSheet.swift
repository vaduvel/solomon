import SwiftUI
import SolomonCore
import SolomonStorage
import SolomonAnalytics
import SolomonMoments
import SolomonLLM
import SolomonWeb

// MARK: - CanIAffordSheet
//
// Bottom sheet pentru întrebarea „Pot să-mi permit X?".
// User: tastează sumă (+ opțional descriere) → Solomon răspunde cu verdict +
// matematica vizibilă, folosind SafeToSpendCalculator + CanIAffordBuilder.

struct CanIAffordSheet: View {

    @Environment(\.dismiss) private var dismiss

    @State private var amountText: String = "0"
    @State private var description: String = ""
    @State private var verdict: SafeToSpendBudget.Verdict?
    @State private var isCalculating: Bool = false
    @State private var llmResponse: String?
    @State private var calculatedBudget: SafeToSpendBudget?
    @State private var webSnippet: String?
    @State private var isScamRisk: Bool = false

    private let calc = SafeToSpendCalculator()
    private let webClient = SolomonWebClient()
    private let scamMatcher = ScamPatternMatcher()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.solCanvas.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: SolSpacing.lg) {
                        if verdict != nil {
                            verdictCard
                        } else {
                            amountInputSection
                        }
                        Spacer()
                    }
                    .padding(.horizontal, SolSpacing.screenHorizontal)
                    .padding(.top, SolSpacing.lg)
                    .padding(.bottom, SolSpacing.hh)
                }
            }
            .navigationTitle("Pot să-mi permit?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Închide") { dismiss() }
                        .foregroundStyle(Color.solMuted)
                }
            }
        }
    }

    // MARK: - Amount input

    @ViewBuilder
    private var amountInputSection: some View {
        VStack(spacing: SolSpacing.lg) {
            HStack(alignment: .firstTextBaseline, spacing: SolSpacing.xs) {
                Text(amountText)
                    .font(.system(size: 56, weight: .bold, design: .monospaced))
                    .foregroundStyle(LinearGradient.solHero)
                    .monospacedDigit()
                Text("RON")
                    .font(.solH2)
                    .foregroundStyle(Color.solMuted)
            }
            .padding(.vertical, SolSpacing.lg)

            VStack(alignment: .leading, spacing: SolSpacing.xs) {
                Text("CE CUMPERI? (OPȚIONAL)")
                    .font(.solMicro)
                    .foregroundStyle(Color.solMuted)
                    .tracking(1.2)
                SolomonTextInput(
                    placeholder: "ex: pizza de la Glovo",
                    text: $description,
                    icon: "cart"
                )
            }

            numberPad

            SolomonButton(
                "Solomon, pot?",
                isLoading: isCalculating,
                icon: "arrow.right"
            ) {
                Task { await calculate() }
            }
            .opacity(amountValue > 0 ? 1 : 0.4)
            .disabled(amountValue == 0 || isCalculating)
        }
    }

    @ViewBuilder
    private var numberPad: some View {
        let rows: [[String]] = [["1","2","3"], ["4","5","6"], ["7","8","9"], ["", "0", "⌫"]]
        VStack(spacing: SolSpacing.sm) {
            ForEach(0..<rows.count, id: \.self) { rowIndex in
                HStack(spacing: SolSpacing.sm) {
                    ForEach(rows[rowIndex], id: \.self) { key in
                        padKey(key)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func padKey(_ key: String) -> some View {
        Button {
            tapKey(key)
        } label: {
            Group {
                if key == "⌫" {
                    Image(systemName: "delete.left")
                        .font(.system(size: 22, weight: .medium))
                } else if !key.isEmpty {
                    Text(key)
                        .font(.system(size: 28, weight: .medium))
                } else {
                    Color.clear
                }
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .foregroundStyle(Color.solForeground)
            .background(key.isEmpty ? Color.clear : Color.solCard)
            .clipShape(RoundedRectangle(cornerRadius: SolRadius.lg))
        }
        .disabled(key.isEmpty)
    }

    // MARK: - Verdict

    @ViewBuilder
    private var verdictCard: some View {
        if let v = verdict {
            verdictCardImpl(v: v)
        }
    }

    @ViewBuilder
    private func verdictCardImpl(v: SafeToSpendBudget.Verdict) -> some View {
        VStack(alignment: .leading, spacing: SolSpacing.lg) {
            switch v {
            case .yes(let perDay):
                IconContainer(systemName: "checkmark.circle.fill", variant: .neon, size: 56, iconSize: 24)
                Text("Da, poți. ✓")
                    .font(.solH1)
                    .foregroundStyle(Color.solPrimary)
                Text("După această cheltuială rămân \(perDay.amount) RON/zi pentru \(calculatedBudget?.daysUntilNextPayday ?? 0) zile.")
                    .font(.solBody)
                    .foregroundStyle(Color.solForeground)

            case .yesWithCaution(_, let perDay):
                IconContainer(systemName: "exclamationmark.triangle.fill", variant: .warn, size: 56, iconSize: 24)
                Text("Da, dar e strâns.")
                    .font(.solH1)
                    .foregroundStyle(Color.solWarning)
                Text("După plată rămân doar \(perDay.amount) RON/zi până la salariu. Atenție la celelalte cheltuieli.")
                    .font(.solBody)
                    .foregroundStyle(Color.solForeground)

            case .no(let reason):
                IconContainer(systemName: "xmark.octagon.fill", variant: .danger, size: 56, iconSize: 24)
                Text("Nu acum.")
                    .font(.solH1)
                    .foregroundStyle(Color.solDestructive)
                Text(reasonText(reason))
                    .font(.solBody)
                    .foregroundStyle(Color.solForeground)
            }

            if isScamRisk {
                HStack(spacing: SolSpacing.sm) {
                    Image(systemName: "exclamationmark.shield.fill")
                        .foregroundStyle(Color.solDestructive)
                    Text("Solomon a detectat risc de scam în descriere. Verifică sursa înainte să plătești.")
                        .font(.solCaption)
                        .foregroundStyle(Color.solDestructive)
                }
                .padding(SolSpacing.base)
                .background(Color.solDestructive.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: SolRadius.lg))
            }

            if let llm = llmResponse {
                Divider().background(Color.solBorder)
                Text(llm)
                    .font(.solBody)
                    .foregroundStyle(Color.solMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let snippet = webSnippet {
                Divider().background(Color.solBorder)
                VStack(alignment: .leading, spacing: SolSpacing.xs) {
                    Label("Context web", systemImage: "globe")
                        .font(.solCaption)
                        .foregroundStyle(Color.solMuted)
                    Text(snippet)
                        .font(.solCaption)
                        .foregroundStyle(Color.solForeground)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: SolSpacing.sm) {
                SolomonButton("Întreabă altceva", style: .secondary) { reset() }
                SolomonButton("Gata", action: { dismiss() })
            }
            .padding(.top, SolSpacing.md)
        }
        .padding(SolSpacing.cardHero)
        .frame(maxWidth: .infinity, alignment: .leading)
        .solCard()
    }

    private func reasonText(_ reason: CanIAffordVerdictReason) -> String {
        switch reason {
        case .comfortableMargin:    return "Marja confortabilă."
        case .tightButWorkable:     return "Strâns, dar fezabil."
        case .wouldCreateOverdraft: return "Ar crea descoperit de cont."
        case .wouldBreakObligation: return "Ar afecta o obligație care urmează."
        case .categoryAlreadyOver:  return "Ai depășit deja bugetul pe această categorie."
        }
    }

    // MARK: - Logic

    private var amountValue: Int {
        Int(amountText) ?? 0
    }

    private func tapKey(_ key: String) {
        switch key {
        case "⌫":
            if amountText.count <= 1 {
                amountText = "0"
            } else {
                amountText.removeLast()
            }
        default:
            if amountText == "0" {
                amountText = key
            } else if amountText.count < 7 {
                amountText.append(key)
            }
        }
    }

    private func reset() {
        amountText = "0"
        description = ""
        verdict = nil
        llmResponse = nil
        calculatedBudget = nil
        webSnippet = nil
        isScamRisk = false
    }

    private func calculate() async {
        isCalculating = true
        defer { isCalculating = false }

        let ctx = SolomonPersistenceController.shared.container.viewContext
        let txRepo = CoreDataTransactionRepository(context: ctx)
        let oblRepo = CoreDataObligationRepository(context: ctx)
        let userRepo = CoreDataUserProfileRepository(context: ctx)

        guard let profile = try? userRepo.fetchProfile() else {
            verdict = .no(reason: .wouldBreakObligation)
            return
        }

        let paydayDay: Int
        switch profile.financials.salaryFrequency {
        case .monthly(let d): paydayDay = d
        case .bimonthly(_, let d2): paydayDay = d2
        case .variable: paydayDay = 28
        }

        let cal = Calendar.current
        let today = cal.component(.day, from: Date())
        let daysUntilNext = paydayDay > today ? (paydayDay - today) : (30 - today + paydayDay)

        let salaryMid = profile.financials.salaryRange.midpointRON
        let lastPayday: Date = {
            if today >= paydayDay {
                return cal.date(bySetting: .day, value: paydayDay, of: Date()) ?? Date()
            }
            let lastMonth = cal.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            return cal.date(bySetting: .day, value: paydayDay, of: lastMonth) ?? lastMonth
        }()
        let spentSince = (try? txRepo.fetch(from: lastPayday, to: Date()))?
            .filter { $0.isOutgoing }
            .reduce(0) { $0 + $1.amount.amount } ?? 0
        let estBalance = max(0, salaryMid - spentSince)

        let obligations = (try? oblRepo.fetchAll()) ?? []
        let obligationsRemaining = obligations.filter { o in
            paydayDay > today
                ? (o.dayOfMonth > today && o.dayOfMonth <= paydayDay)
                : (o.dayOfMonth > today || o.dayOfMonth <= paydayDay)
        }.reduce(0) { $0 + $1.amount.amount }

        let from30 = cal.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let last30 = (try? txRepo.fetch(from: from30, to: Date()))?.filter { $0.isOutgoing } ?? []
        let velocity = last30.isEmpty ? 0 : last30.reduce(0) { $0 + $1.amount.amount } / 30

        let budget = calc.calculate(
            currentBalance: Money(estBalance),
            obligationsRemaining: Money(obligationsRemaining),
            daysUntilNextPayday: daysUntilNext,
            velocityRONPerDay: Money(velocity)
        )
        calculatedBudget = budget

        let askedAmount = Money(amountValue)
        verdict = budget.verdict(for: askedAmount)

        // Build LLM context for richer response
        let item = description.isEmpty ? "achiziția" : description
        let user = MomentUser(
            name: profile.demographics.name,
            addressing: profile.demographics.addressing,
            ageRange: profile.demographics.ageRange
        )

        let projectedAvailable = budget.availableAfterObligations - askedAmount
        let perDayAfter = budget.daysUntilNextPayday > 0
            ? Money(projectedAvailable.amount / budget.daysUntilNextPayday)
            : projectedAvailable

        guard let currentVerdict = verdict else { return }

        let verdictReason: CanIAffordVerdictReason
        switch currentVerdict {
        case .yes:                                           verdictReason = .comfortableMargin
        case .yesWithCaution(let reason, _):                 verdictReason = reason
        case .no(let reason):                                verdictReason = reason
        }

        let context = CanIAffordContext(
            user: user,
            query: CanIAffordQuery(
                rawText: item,
                amountRequested: askedAmount,
                categoryInferred: .unknown
            ),
            context: CanIAffordContextBlock(
                today: Date(),
                daysUntilPayday: budget.daysUntilNextPayday,
                currentBalance: budget.currentBalance,
                obligationsRemainingThisPeriod: [],
                obligationsTotalRemaining: budget.obligationsRemaining,
                availableAfterObligations: budget.availableAfterObligations,
                availablePerDayAfter: budget.availablePerDay,
                availablePerDayAfterPurchase: perDayAfter
            ),
            decision: CanIAffordDecision(
                verdict: currentVerdict.asContextVerdict,
                verdictReason: verdictReason,
                mathVisible: "după \(item): \(projectedAvailable.amount) RON / \(budget.daysUntilNextPayday) zile = \(perDayAfter.amount) RON/zi",
                alternativeToSuggest: .none
            ),
            userHistoryContext: CanIAffordHistoryContext(
                thisCategoryThisMonth: Money(0),
                thisCategoryAvgMonthly: Money(0),
                isAboveAverageToday: false
            )
        )

        // Scam check — rulează pe descrierea dată de user
        if !description.isEmpty {
            isScamRisk = scamMatcher.hasAnyRisk(in: description)
        }

        // Web search — price comparison dacă descrierea e non-trivială (> 3 cuvinte sau sumă mare)
        if !description.isEmpty && (description.split(separator: " ").count >= 2 || amountValue >= 500) {
            let query = WebSearchQuery(
                text: "\(description) pret RON",
                queryType: .priceComparison
            )
            if let result = try? await webClient.search(query) {
                let snippet = result.answer ?? result.abstractText
                if let s = snippet, !s.isEmpty {
                    webSnippet = String(s.prefix(200))
                }
            }
        }

        do {
            let builder = CanIAffordBuilder()
            // Folosim provider-ul real (MLX dacă e descărcat, Template fallback)
            let llm = ModelDownloadService.shared.makeLLMProvider()
            let output = try await builder.build(context, using: llm)
            llmResponse = output.llmResponse
        } catch {
            llmResponse = nil
        }
    }
}

#Preview {
    CanIAffordSheet()
        .preferredColorScheme(.dark)
}
