import SwiftUI
import SolomonCore
import SolomonStorage
import SolomonAnalytics
import SolomonMoments
import SolomonLLM
import SolomonWeb

// MARK: - CanIAffordSheet (Claude Design v3)
//
// Pixel-fidel cu `Solomon DS / screens/can-i-afford.html`:
//   - MeshBackground full-screen
//   - Sheet handle (36×5 capsule) + header back button + brand "SOLOMON · ASK"
//   - Calc display: PREȚ label + amount mare gradient + descriere context
//   - Numpad 4×3 cu glass keys
//   - Verdict: SolHeroCard cu accent dinamic (mint / amber / rose) după Verdict
//   - Math vizibilă în SolListCard (3 verdict-rows: balance, obligații, per-zi)
//   - Scam alert (rose) + LLM response InsightCard + web snippet
//   - Butoane "Întreabă altceva" / "Gata"
//
// Business logic păstrat 1:1: SafeToSpendCalculator, ScamPatternMatcher,
// SolomonWebClient, CanIAffordBuilder + CanIAffordContext, parsing logic.

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
        ZStack {
            MeshBackground(
                topLeftAccent: heroAccent,
                midRightAccent: .blue,
                bottomLeftAccent: .violet
            )

            VStack(spacing: 0) {
                // Sheet handle (36×5 pill)
                sheetHandle

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Header bar: back + centered brand+title
                        headerBar
                            .padding(.bottom, 8)

                        if verdict != nil {
                            // Verdict mode
                            calcDisplay
                            verdictHero
                            if !mathRows.isEmpty {
                                SolSectionHeaderRow("ANALIZĂ", meta: "\(mathRows.count) verificări")
                                    .padding(.top, 4)
                                analysisList
                            }
                            if isScamRisk {
                                scamAlert
                            }
                            if let llm = llmResponse, !llm.isEmpty {
                                llmResponseCard(llm)
                            }
                            if let snippet = webSnippet, !snippet.isEmpty {
                                webSnippetCard(snippet)
                            }
                            actionButtons
                                .padding(.top, 4)
                        } else {
                            // Input mode
                            descriptionField
                            calcDisplay
                            numberPad
                                .padding(.top, 4)
                            askButton
                                .padding(.top, 4)
                        }

                        Spacer(minLength: 32)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                    .padding(.bottom, SolSpacing.hh)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }

    // MARK: - Sheet handle

    @ViewBuilder
    private var sheetHandle: some View {
        Capsule()
            .fill(Color.white.opacity(0.18))
            .frame(width: 36, height: 5)
            .padding(.top, 8)
            .padding(.bottom, 4)
    }

    // MARK: - Header bar (back + centered title)

    @ViewBuilder
    private var headerBar: some View {
        HStack(alignment: .center) {
            SolBackButton { dismiss() }

            Spacer(minLength: 0)

            VStack(spacing: 4) {
                Text("SOLOMON · ASK")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.45))
                    .tracking(1.4)
                    .textCase(.uppercase)
                Text("Pot să-mi permit?")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .tracking(-0.4)
            }

            Spacer(minLength: 0)

            // Spacer to balance back button
            Color.clear.frame(width: 38, height: 38)
        }
    }

    // MARK: - Description field (label + input)

    @ViewBuilder
    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("OBIECTUL")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.5))
                .tracking(0.5)
                .textCase(.uppercase)

            TextField("", text: $description, prompt:
                Text("ex: pizza de la Glovo")
                    .foregroundStyle(Color.white.opacity(0.35))
            )
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }

    // MARK: - Calc display (label + big amount + ctx)

    @ViewBuilder
    private var calcDisplay: some View {
        VStack(spacing: 4) {
            Text("PREȚ")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.4))
                .tracking(0.5)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(formattedAmount)
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(amountGradient)
                    .tracking(-2)
                    .monospacedDigit()
                Text("RON")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.4))
            }
            .padding(.top, 2)

            if !description.isEmpty {
                Text(description)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .padding(.top, 2)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var amountGradient: LinearGradient {
        LinearGradient(
            colors: [Color.white, Color.white.opacity(0.85)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var formattedAmount: String {
        RomanianMoneyFormatter.thousands(amountValue)
    }

    // MARK: - Number pad (4 rows × 3 cols)

    @ViewBuilder
    private var numberPad: some View {
        let rows: [[String]] = [
            ["1","2","3"],
            ["4","5","6"],
            ["7","8","9"],
            ["",  "0", "⌫"]
        ]
        VStack(spacing: 8) {
            ForEach(rows.indices, id: \.self) { rowIndex in
                HStack(spacing: 8) {
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
            Haptics.light()
            tapKey(key)
        } label: {
            Group {
                if key == "⌫" {
                    Image(systemName: "delete.left")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.85))
                } else if !key.isEmpty {
                    Text(key)
                        .font(.system(size: 26, weight: .medium))
                        .foregroundStyle(Color.white)
                } else {
                    Color.clear
                }
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(
                Group {
                    if key.isEmpty {
                        Color.clear
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.white.opacity(0.04))
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        }
                    }
                }
            )
        }
        .buttonStyle(.plain)
        .disabled(key.isEmpty)
    }

    // MARK: - Ask button

    @ViewBuilder
    private var askButton: some View {
        Button {
            Haptics.medium()
            Task { await calculate() }
        } label: {
            HStack(spacing: 8) {
                if isCalculating {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(Color(red: 0x05/255, green: 0x2E/255, blue: 0x16/255))
                        .scaleEffect(0.85)
                } else {
                    Text("Solomon, pot?")
                        .font(.system(size: 14, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .semibold))
                }
            }
            .foregroundStyle(Color(red: 0x05/255, green: 0x2E/255, blue: 0x16/255))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(SolAccent.mint.primaryButtonGradient)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.20), lineWidth: 1)
                    .blendMode(.plusLighter)
            )
            .shadow(color: Color.solMintExact.opacity(0.4), radius: 12, x: 0, y: 4)
            .opacity(amountValue > 0 ? 1 : 0.45)
        }
        .buttonStyle(.plain)
        .disabled(amountValue == 0 || isCalculating)
    }

    // MARK: - Verdict hero

    @ViewBuilder
    private var verdictHero: some View {
        if let v = verdict {
            SolHeroCard(accent: heroAccent) {
                VStack(alignment: .leading, spacing: 6) {
                    SolHeroLabel("SOLOMON SUGEREAZĂ")

                    Text(headlineText(for: v))
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .tracking(-0.6)
                        .padding(.top, 6)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(detailText(for: v))
                        .font(.system(size: 13))
                        .foregroundStyle(Color.white.opacity(0.65))
                        .lineSpacing(2)
                        .padding(.top, 4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } badge: {
                SolHeroBadge("VERDICT", accent: heroAccent)
            }
        }
    }

    private var heroAccent: SolAccent {
        guard let v = verdict else { return .mint }
        switch v {
        case .yes:             return .mint
        case .yesWithCaution:  return .amber
        case .no:              return .rose
        }
    }

    private func headlineText(for v: SafeToSpendBudget.Verdict) -> String {
        switch v {
        case .yes:             return "Da, poți cumpăra."
        case .yesWithCaution:  return "Da, dar e strâns."
        case .no:              return "Nu acum."
        }
    }

    private func detailText(for v: SafeToSpendBudget.Verdict) -> String {
        let days = calculatedBudget?.daysUntilNextPayday ?? 0
        switch v {
        case .yes(let perDay):
            return "După această cheltuială rămân \(RomanianMoneyFormatter.format(perDay))/zi pentru \(days) zile până la salariu."
        case .yesWithCaution(_, let perDay):
            return "După plată rămân doar \(RomanianMoneyFormatter.format(perDay))/zi până la salariu. Atenție la celelalte cheltuieli."
        case .no(let reason):
            return reasonText(reason)
        }
    }

    // MARK: - Math (analysis list)

    private struct MathRow: Identifiable {
        let id = UUID()
        let icon: String
        let kind: SolChip.Kind   // mint / warn / rose
        let text: AttributedString
        let value: String
        let valueAccent: SolChip.Kind
    }

    private var mathRows: [MathRow] {
        guard let b = calculatedBudget else { return [] }
        let asked = Money(amountValue)
        let after = b.availableAfterObligations - asked
        let perDayAfter = b.daysUntilNextPayday > 0
            ? Money(after.amount / b.daysUntilNextPayday)
            : after

        let pctOfPrice: Int = {
            guard amountValue > 0 else { return 0 }
            return Int(Double(b.availableAfterObligations.amount) / Double(amountValue) * 100)
        }()

        var rows: [MathRow] = []

        // Row 1 — safe-to-spend coverage
        rows.append(
            MathRow(
                icon: "checkmark",
                kind: pctOfPrice >= 100 ? .mint : .warn,
                text: makeText(
                    "Disponibil acoperă ",
                    boldPart: "\(min(pctOfPrice, 999))%",
                    suffix: " din preț azi"
                ),
                value: RomanianMoneyFormatter.thousands(b.availableAfterObligations.amount),
                valueAccent: .mint
            )
        )

        // Row 2 — obligations remaining
        if b.obligationsRemaining.amount > 0 {
            rows.append(
                MathRow(
                    icon: "exclamationmark",
                    kind: .warn,
                    text: makeText(
                        "Obligații rămase de plătit până la salariu",
                        boldPart: nil,
                        suffix: ""
                    ),
                    value: "−\(RomanianMoneyFormatter.thousands(b.obligationsRemaining.amount))",
                    valueAccent: .warn
                )
            )
        }

        // Row 3 — per-day after purchase
        let perDayKind: SolChip.Kind = {
            switch verdict {
            case .yes:             return .mint
            case .yesWithCaution:  return .warn
            case .no, .none:       return .rose
            }
        }()
        rows.append(
            MathRow(
                icon: perDayKind == .rose ? "xmark" : (perDayKind == .warn ? "exclamationmark" : "checkmark"),
                kind: perDayKind,
                text: makeText(
                    "După cumpărare, rămân ",
                    boldPart: "\(RomanianMoneyFormatter.format(perDayAfter))",
                    suffix: " / \(b.daysUntilNextPayday) zile"
                ),
                value: "\(RomanianMoneyFormatter.thousands(perDayAfter.amount))/zi",
                valueAccent: perDayKind
            )
        )

        return rows
    }

    private func makeText(_ prefix: String, boldPart: String?, suffix: String) -> AttributedString {
        var a = AttributedString(prefix)
        a.foregroundColor = Color.white.opacity(0.85)
        a.font = .system(size: 13)
        if let bold = boldPart {
            var b = AttributedString(bold)
            b.foregroundColor = Color.white
            b.font = .system(size: 13, weight: .semibold)
            a.append(b)
        }
        if !suffix.isEmpty {
            var s = AttributedString(suffix)
            s.foregroundColor = Color.white.opacity(0.85)
            s.font = .system(size: 13)
            a.append(s)
        }
        return a
    }

    @ViewBuilder
    private var analysisList: some View {
        SolListCard {
            ForEach(Array(mathRows.enumerated()), id: \.element.id) { (idx, row) in
                if idx > 0 {
                    SolHairlineDivider()
                }
                HStack(alignment: .center, spacing: 10) {
                    // Verdict icon (28×28)
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(rowIconBg(row.kind))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(rowIconBorder(row.kind), lineWidth: 1)
                            )
                        Image(systemName: row.icon)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(rowIconColor(row.kind))
                    }
                    .frame(width: 28, height: 28)

                    Text(row.text)
                        .lineSpacing(2)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(row.value)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(rowIconColor(row.valueAccent))
                        .monospacedDigit()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
        }
    }

    private func rowIconBg(_ kind: SolChip.Kind) -> Color {
        switch kind {
        case .mint:   return Color.solMintExact.opacity(0.15)
        case .warn:   return Color.solAmberExact.opacity(0.15)
        case .rose:   return Color.solRoseExact.opacity(0.15)
        case .blue:   return Color.solBlueExact.opacity(0.15)
        case .violet: return Color.solVioletExact.opacity(0.15)
        case .muted:  return Color.white.opacity(0.05)
        }
    }
    private func rowIconBorder(_ kind: SolChip.Kind) -> Color {
        switch kind {
        case .mint:   return Color.solMintExact.opacity(0.25)
        case .warn:   return Color.solAmberExact.opacity(0.25)
        case .rose:   return Color.solRoseExact.opacity(0.30)
        case .blue:   return Color.solBlueExact.opacity(0.25)
        case .violet: return Color.solVioletExact.opacity(0.25)
        case .muted:  return Color.white.opacity(0.08)
        }
    }
    private func rowIconColor(_ kind: SolChip.Kind) -> Color {
        switch kind {
        case .mint:   return .solMintExact
        case .warn:   return .solAmberExact
        case .rose:   return .solRoseExact
        case .blue:   return .solBlueExact
        case .violet: return .solVioletExact
        case .muted:  return Color.white.opacity(0.5)
        }
    }

    // MARK: - Scam alert

    @ViewBuilder
    private var scamAlert: some View {
        SolInsightCard(
            icon: "exclamationmark.shield.fill",
            label: "ATENȚIE · POSIBIL SCAM",
            timestamp: nil,
            accent: .rose
        ) {
            Text("Solomon a detectat semnale de scam în descriere. Verifică sursa și nu plăti până ești sigur.")
                .font(.system(size: 14))
                .foregroundStyle(Color.white.opacity(0.85))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - LLM response

    @ViewBuilder
    private func llmResponseCard(_ text: String) -> some View {
        SolInsightCard(
            icon: "sparkles",
            label: "SOLOMON SPUNE",
            timestamp: "acum",
            accent: heroAccent
        ) {
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(Color.white.opacity(0.85))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Web snippet

    @ViewBuilder
    private func webSnippetCard(_ text: String) -> some View {
        SolInsightCard(
            icon: "globe",
            label: "CONTEXT WEB",
            timestamp: nil,
            accent: .blue
        ) {
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(Color.white.opacity(0.75))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Action buttons

    @ViewBuilder
    private var actionButtons: some View {
        HStack(spacing: 8) {
            SolSecondaryButton("Întreabă altceva", fullWidth: true) {
                reset()
            }
            SolPrimaryButton("Gata", accent: .mint, fullWidth: true) {
                dismiss()
            }
        }
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

    // MARK: - Logic (NEMODIFICAT)

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
        // FIX 4: foloseam 30 fix → eroare în ianuarie/martie/mai/iulie (31 zile)
        // și februarie (28/29). Acum: daysInMonth real + clamp paydayDay la lungime.
        let daysInMonth = cal.range(of: .day, in: .month, for: Date())?.count ?? 30
        let clampedPayday = min(paydayDay, daysInMonth)
        let daysUntilNext = clampedPayday > today
            ? (clampedPayday - today)
            : (daysInMonth - today + clampedPayday)

        let salaryMid = profile.financials.salaryRange.midpointRON
        let lastPayday: Date = {
            // FAZA A2: safeDate clamp-uiește la ultima zi a lunii pentru paydayDay > daysInMonth
            if today >= paydayDay {
                return cal.safeDate(dayOfMonth: paydayDay, in: Date())
            }
            let lastMonth = cal.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            return cal.safeDate(dayOfMonth: paydayDay, in: lastMonth)
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
