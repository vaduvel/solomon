import SwiftUI
import os
import Observation
import SolomonCore
import SolomonStorage
import SolomonAnalytics

// MARK: - WalletView (Tab 3 — Portofel) · redesign Solomon DS · wallet.html
//
// Layout 1:1 cu Solomon DS / wallet.html (editorial premium glass):
//   - MeshBackground full screen
//   - SolAppBar (brand + greeting) cu SolIconButton "+" context-aware (per segment)
//   - SolHeroCard (mint accent) cu badge SAFE TO SPEND, label, big amount, meta
//     și SolAllocationBar (Obligații / Subs / Buffer) + legend
//   - SolInsightCard mint cu copy ghost / generic
//   - Stats grid 2×2 (URM. PLATĂ + PATTERN)
//   - Picker custom 3 SolPill (Obligații / Abonamente / Tranzacții) — wirat la
//     `selectedSegment` (Int)
//   - SolSectionHeaderRow + SolListCard cu rows pentru segmentul activ
//   - Empty state per segment via SolInsightCard cu CTA „Adaugă"
//
// Business logic 100% intactă: vm e WalletViewModel, sheet bindings rămân
// (showSubscriptionAudit, showSuspiciousTransactions, showManualEntry,
// showAddObligation, showAddSubscription, editingObligation, editingSubscription).

struct WalletView: View {

    @State private var vm = WalletViewModel()
    @State private var selectedSegment = 0
    @State private var showSubscriptionAudit = false
    @State private var showSuspiciousTransactions = false
    @State private var showManualEntry = false
    // Edit sheets — context-aware per tab
    @State private var showAddObligation = false
    @State private var showAddSubscription = false
    @State private var editingObligation: Obligation?
    @State private var editingSubscription: Subscription?

    var body: some View {
        NavigationStack {
            ZStack {
                MeshBackground()

                ScrollView {
                    VStack(spacing: SolSpacing.base) {
                        SolAppBar(brand: "SOLOMON · PORTOFEL", greeting: "Conturile tale") {
                            SolIconButton(systemName: addIconName) {
                                openAddSheetForCurrentSegment()
                            }
                        }

                        heroCard

                        insightCard

                        statsGrid

                        segmentPicker
                            .padding(.top, SolSpacing.xs)

                        SolSectionHeaderRow(currentSectionTitle, meta: currentSectionMeta)

                        currentSegmentList

                        Spacer(minLength: SolSpacing.xxxl)
                    }
                    .padding(.horizontal, SolSpacing.xl)
                    .padding(.top, SolSpacing.sm)
                    .padding(.bottom, SolSpacing.hh)
                }
                .scrollContentBackground(.hidden)
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showSubscriptionAudit, onDismiss: { Task { await vm.load() } }) {
                SubscriptionAuditView().solStandardSheet()
            }
            .sheet(isPresented: $showSuspiciousTransactions, onDismiss: { Task { await vm.load() } }) {
                SuspiciousTransactionsView().solStandardSheet()
            }
            .sheet(isPresented: $showManualEntry, onDismiss: { Task { await vm.load() } }) {
                ManualTransactionView().solStandardSheet()
            }
            // Obligation sheets
            .sheet(isPresented: $showAddObligation, onDismiss: { Task { await vm.load() } }) {
                ObligationEditView().solStandardSheet()
            }
            .sheet(item: $editingObligation, onDismiss: { Task { await vm.load() } }) { obl in
                ObligationEditView(editingObligation: obl).solStandardSheet()
            }
            // Subscription sheets
            .sheet(isPresented: $showAddSubscription, onDismiss: { Task { await vm.load() } }) {
                SubscriptionEditView().solStandardSheet()
            }
            .sheet(item: $editingSubscription, onDismiss: { Task { await vm.load() } }) { sub in
                SubscriptionEditView(editingSubscription: sub).solStandardSheet()
            }
        }
        .task {
            vm.configure(persistence: SolomonPersistenceController.shared)
            await vm.load()
        }
    }

    // MARK: - "+" context-aware

    private var addIconName: String { "plus" }

    private func openAddSheetForCurrentSegment() {
        switch selectedSegment {
        case 0: showAddObligation = true
        case 1: showAddSubscription = true
        default: showManualEntry = true
        }
    }

    // MARK: - Hero card

    @ViewBuilder
    private var heroCard: some View {
        let model = WalletHeroModel(vm: vm)

        SolHeroCard(accent: .mint) {
            VStack(alignment: .leading, spacing: 0) {
                SolHeroLabel("DISPONIBIL LIBER · \(model.daysUntilPayday) ZILE")

                SolHeroAmount(
                    amount: model.amountWhole,
                    decimals: model.amountDecimals,
                    currency: "RON",
                    accent: .mint
                )
                .padding(.top, 6)

                HStack(spacing: 8) {
                    Text("≈ \(model.perDayRON) RON/zi")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.white.opacity(0.55))
                    Circle()
                        .fill(Color.white.opacity(0.25))
                        .frame(width: 3, height: 3)
                    Text("până \(model.paydayDateText)")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.white.opacity(0.55))
                }
                .padding(.top, 6)
                .padding(.bottom, 18)

                SolAllocationBar(segments: model.allocationSegments)

                HStack {
                    legendDot(color: .solMintExact, label: "Obligații \(formatNum(model.obligationsRON))")
                    Spacer()
                    legendDot(color: .solBlueExact, label: "Subs \(formatNum(model.subscriptionsRON))")
                    Spacer()
                    legendDot(color: .solAmberExact, label: "Buffer \(formatNum(model.bufferRON))")
                }
                .padding(.top, 10)
            }
        } badge: {
            SolHeroBadge("SAFE TO SPEND", accent: .mint)
        }
    }

    @ViewBuilder
    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 5, height: 5)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Color.white.opacity(0.5))
                .monospacedDigit()
                .lineLimit(1)
        }
    }

    // MARK: - Insight card

    @ViewBuilder
    private var insightCard: some View {
        let ghost = vm.ghostSavingsPotential
        let monthly = vm.subscriptionsTotalRON

        if ghost > 0 {
            SolInsightCard(
                icon: "sparkles",
                label: "SOLOMON · INSIGHT",
                timestamp: "acum 2 ore",
                accent: .mint
            ) {
                insightBody(text: "Abonamente nefolosite costă ", boldText: "\(ghost) RON/lună",
                            tail: ". Recuperabili: ", accent: "\(ghost * 12) RON/an", tailEnd: ".")
                insightActions(primaryTitle: "Vezi audit", primaryAction: { showSubscriptionAudit = true })
            }
        } else if !vm.subscriptions.isEmpty {
            SolInsightCard(
                icon: "sparkles",
                label: "SOLOMON · INSIGHT",
                timestamp: "azi",
                accent: .mint
            ) {
                insightBody(text: "Plătești ", boldText: "\(monthly) RON/lună",
                            tail: " pe abonamente. Verifică dacă le folosești pe toate.",
                            accent: nil, tailEnd: nil)
                insightActions(primaryTitle: "Vezi tot", primaryAction: { selectedSegment = 1 })
            }
        } else {
            SolInsightCard(
                icon: "sparkles",
                label: "SOLOMON · INSIGHT",
                timestamp: "acum",
                accent: .mint
            ) {
                insightBody(text: "Adaugă obligațiile și abonamentele tale ca să-ți pot calcula corect ",
                            boldText: "Safe-to-Spend",
                            tail: ".", accent: nil, tailEnd: nil)
                insightActions(primaryTitle: "Adaugă obligație", primaryAction: { showAddObligation = true })
            }
        }
    }

    @ViewBuilder
    private func insightBody(text: String, boldText: String, tail: String, accent: String?, tailEnd: String?) -> some View {
        let attr: AttributedString = {
            var a = AttributedString(text)
            var b = AttributedString(boldText)
            b.foregroundColor = .white
            b.font = .system(size: 14, weight: .medium)
            a += b
            a += AttributedString(tail)
            if let accent {
                var c = AttributedString(accent)
                c.foregroundColor = .solMintExact
                c.font = .system(size: 14, weight: .medium)
                a += c
            }
            if let tailEnd {
                a += AttributedString(tailEnd)
            }
            return a
        }()
        Text(attr)
            .font(.system(size: 14))
            .foregroundStyle(Color.white.opacity(0.85))
            .lineSpacing(2)
            .padding(.bottom, 12)
    }

    @ViewBuilder
    private func insightActions(primaryTitle: String, primaryAction: @escaping () -> Void) -> some View {
        HStack(spacing: 8) {
            SolPrimaryButton(primaryTitle, accent: .mint, action: primaryAction)
            SolSecondaryButton("Mai târziu") { }
        }
    }

    // MARK: - Stats grid 2×2

    @ViewBuilder
    private var statsGrid: some View {
        let nextObligation = vm.obligations
            .map { (obl: Obligation) -> (Obligation, Int) in (obl, daysUntil(dayOfMonth: obl.dayOfMonth)) }
            .sorted { $0.1 < $1.1 }
            .first

        let topCategory = WalletPattern.topOutgoingCategory(transactions: vm.transactions)

        HStack(spacing: 10) {
            if let (obl, days) = nextObligation {
                SolStatCard(
                    label: "URM. PLATĂ",
                    name: obl.name,
                    value: "\(formatNum(obl.amount.amount)) RON",
                    meta: "în \(days) " + (days == 1 ? "zi" : "zile"),
                    metaAccent: .amber,
                    icon: "calendar",
                    iconAccent: .blue
                )
            } else {
                SolStatCard(
                    label: "URM. PLATĂ",
                    name: "—",
                    value: "0 RON",
                    meta: "fără obligații",
                    metaAccent: nil,
                    icon: "calendar",
                    iconAccent: .blue
                )
            }

            if let pattern = topCategory {
                SolStatCard(
                    label: "PATTERN",
                    name: pattern.label,
                    value: "+\(formatNum(pattern.amount)) RON",
                    meta: "săptămâna asta",
                    metaAccent: nil,
                    icon: "clock",
                    iconAccent: .amber
                )
            } else {
                SolStatCard(
                    label: "PATTERN",
                    name: "Fără date",
                    value: "—",
                    meta: "adaugă tranzacții",
                    metaAccent: nil,
                    icon: "clock",
                    iconAccent: .amber
                )
            }
        }
    }

    // MARK: - Custom 3-segment picker (SolPill)

    @ViewBuilder
    private var segmentPicker: some View {
        HStack(spacing: 6) {
            SolPill("Obligații", isActive: selectedSegment == 0) {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) { selectedSegment = 0 }
            }
            SolPill("Abonamente", isActive: selectedSegment == 1) {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) { selectedSegment = 1 }
            }
            SolPill("Tranzacții", isActive: selectedSegment == 2) {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) { selectedSegment = 2 }
            }
            Spacer(minLength: 0)
        }
    }

    private var currentSectionTitle: String {
        switch selectedSegment {
        case 0: return "OBLIGAȚII"
        case 1: return "ABONAMENTE"
        default: return "TRANZACȚII"
        }
    }

    private var currentSectionMeta: String? {
        switch selectedSegment {
        case 0: return vm.obligations.isEmpty ? nil : "\(vm.obligations.count) active"
        case 1: return vm.subscriptions.isEmpty ? nil : "\(vm.subscriptions.count) active"
        default: return vm.transactions.isEmpty ? nil : "\(vm.transactions.count) recente"
        }
    }

    // MARK: - Current segment list

    @ViewBuilder
    private var currentSegmentList: some View {
        switch selectedSegment {
        case 0: obligationsList
        case 1: subscriptionsList
        default: transactionsList
        }
    }

    // MARK: - Obligations list

    @ViewBuilder
    private var obligationsList: some View {
        if vm.obligations.isEmpty {
            emptyStateInsight(
                text: "Nu ai obligații încă. Adaugă chiria, ratele sau abonamentele tale.",
                ctaTitle: "Adaugă obligație"
            ) { showAddObligation = true }
        } else {
            SolListCard {
                ForEach(Array(vm.obligations.enumerated()), id: \.element.id) { idx, obl in
                    if idx > 0 { SolHairlineDivider() }
                    obligationRow(obl)
                }
            }
        }
    }

    @ViewBuilder
    private func obligationRow(_ obl: Obligation) -> some View {
        let days = daysUntil(dayOfMonth: obl.dayOfMonth)
        let urgent = days <= 3

        SolListRow(
            title: obl.name,
            subtitle: "\(obl.kind.displayNameRO) · ziua \(obl.dayOfMonth)",
            onTap: { editingObligation = obl }
        ) {
            obligationLogo(kind: obl.kind)
        } trailing: {
            HStack(spacing: 8) {
                VStack(alignment: .trailing, spacing: 1) {
                    Text("\(formatNum(obl.amount.amount)) RON")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .monospacedDigit()
                        .tracking(-0.3)
                    Text(urgent ? "în \(days) " + (days == 1 ? "zi" : "zile") : "ziua \(obl.dayOfMonth)")
                        .font(.system(size: 11))
                        .foregroundStyle(urgent ? Color.solAmberExact : Color.white.opacity(0.35))
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.3))
            }
        }
    }

    @ViewBuilder
    private func obligationLogo(kind: ObligationKind) -> some View {
        let (icon, accent) = obligationIconForKind(kind)
        ZStack {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(accent.iconGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .stroke(accent.color.opacity(0.25), lineWidth: 1)
                )
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(accent.color)
        }
        .frame(width: 36, height: 36)
    }

    private func obligationIconForKind(_ kind: ObligationKind) -> (String, SolAccent) {
        switch kind {
        case .rentMortgage: return ("house.fill", .blue)
        case .utility:      return ("bolt.fill", .amber)
        case .subscription: return ("play.rectangle.fill", .violet)
        case .loanBank:     return ("building.columns.fill", .blue)
        case .loanIFN:      return ("exclamationmark.octagon.fill", .rose)
        case .bnpl:         return ("creditcard.fill", .rose)
        case .insurance:    return ("shield.fill", .mint)
        case .other:        return ("doc.text.fill", .blue)
        }
    }

    // MARK: - Subscriptions list

    @ViewBuilder
    private var subscriptionsList: some View {
        if vm.subscriptions.isEmpty {
            emptyStateInsight(
                text: "Niciun abonament încă. Solomon le va detecta din emails sau le poți adăuga manual.",
                ctaTitle: "Adaugă abonament"
            ) { showAddSubscription = true }
        } else {
            SolListCard {
                ForEach(Array(vm.subscriptions.enumerated()), id: \.element.id) { idx, sub in
                    if idx > 0 { SolHairlineDivider() }
                    subscriptionRow(sub)
                }
            }
        }
    }

    @ViewBuilder
    private func subscriptionRow(_ sub: Subscription) -> some View {
        SolListRow(
            title: sub.name,
            subtitle: subscriptionSubtitle(sub),
            onTap: { editingSubscription = sub }
        ) {
            SolBrandLogo(brandFor(name: sub.name), size: 36)
        } trailing: {
            HStack(spacing: 8) {
                VStack(alignment: .trailing, spacing: 1) {
                    Text("\(formatNum(sub.amountMonthly.amount)) RON")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(sub.isGhost ? Color.solRoseExact : Color.white)
                        .monospacedDigit()
                        .tracking(-0.3)
                    Text("lunar")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.35))
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.3))
            }
        }
    }

    private func subscriptionSubtitle(_ sub: Subscription) -> String {
        if sub.isGhost, let days = sub.lastUsedDaysAgo {
            return "Ghost · nefolosit de \(days) zile"
        }
        if let days = sub.lastUsedDaysAgo {
            if days == 0 { return "Folosit azi · lunar" }
            if days < 7 { return "Folosit acum \(days) zile · lunar" }
            return "Folosit acum \(days / 7) săpt · lunar"
        }
        return "Activ · lunar"
    }

    private func brandFor(name: String) -> SolBrandLogo.Brand {
        let n = name.lowercased()
        if n.contains("netflix") { return .netflix }
        if n.contains("spotify") { return .spotify }
        if n.contains("hbo")     { return .hbo }
        if n.contains("apple")   { return .applemusic }
        if n.contains("glovo")   { return .glovo }
        if n.contains("bolt")    { return .bolt }
        if n.contains("uber")    { return .uber }
        if n.contains("ing")     { return .ing }
        if n.contains("bt")      { return .bt }
        // Letter fallback
        let first = String(name.prefix(1)).uppercased()
        return .custom(
            letter: first.isEmpty ? "?" : first,
            gradient: LinearGradient(
                colors: [Color.solVioletExact, Color.solVioletDeep],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            foreground: .white
        )
    }

    // MARK: - Transactions list

    @ViewBuilder
    private var transactionsList: some View {
        if vm.transactions.isEmpty {
            emptyStateInsight(
                text: "Nu ai tranzacții recente. Adaugă manual prima ta tranzacție sau conectează banca via Shortcuts.",
                ctaTitle: "Adaugă tranzacție"
            ) { showManualEntry = true }
        } else {
            SolListCard {
                ForEach(Array(vm.transactions.enumerated()), id: \.element.id) { idx, tx in
                    if idx > 0 { SolHairlineDivider() }
                    transactionRow(tx)
                }
            }
        }
    }

    @ViewBuilder
    private func transactionRow(_ tx: SolomonCore.Transaction) -> some View {
        SolListRow(
            title: tx.merchant ?? tx.description ?? "Tranzacție",
            subtitle: "\(formatDate(tx.date)) · \(tx.category.displayNameRO)"
        ) {
            transactionLogo(category: tx.category)
        } trailing: {
            VStack(alignment: .trailing, spacing: 1) {
                Text(transactionAmountText(tx))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tx.isOutgoing ? Color.solRoseExact : Color.solMintExact)
                    .monospacedDigit()
                    .tracking(-0.3)
                Text(tx.isOutgoing ? "ieșire" : "intrare")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.white.opacity(0.35))
            }
        }
    }

    private func transactionAmountText(_ tx: SolomonCore.Transaction) -> String {
        let prefix = tx.isOutgoing ? "−" : "+"
        return "\(prefix)\(formatNum(tx.amount.amount)) RON"
    }

    @ViewBuilder
    private func transactionLogo(category: TransactionCategory) -> some View {
        let (icon, accent) = transactionIconForCategory(category)
        ZStack {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(accent.iconGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .stroke(accent.color.opacity(0.25), lineWidth: 1)
                )
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(accent.color)
        }
        .frame(width: 36, height: 36)
    }

    private func transactionIconForCategory(_ cat: TransactionCategory) -> (String, SolAccent) {
        switch cat {
        case .foodDelivery:    return ("bicycle", .amber)
        case .foodDining:      return ("fork.knife", .amber)
        case .foodGrocery:     return ("cart.fill", .mint)
        case .transport:       return ("car.fill", .blue)
        case .utilities:       return ("bolt.fill", .amber)
        case .rentMortgage:    return ("house.fill", .blue)
        case .subscriptions:   return ("play.rectangle.fill", .violet)
        case .shoppingOnline:  return ("shippingbox.fill", .violet)
        case .shoppingOffline: return ("bag.fill", .violet)
        case .entertainment:   return ("ticket.fill", .rose)
        case .health:          return ("cross.case.fill", .mint)
        case .loansIFN, .loansBank, .bnpl:
            return ("creditcard.fill", .rose)
        case .travel:          return ("airplane", .blue)
        case .savings:         return ("banknote.fill", .mint)
        case .unknown:         return ("questionmark", .blue)
        }
    }

    // MARK: - Empty state via SolInsightCard

    @ViewBuilder
    private func emptyStateInsight(text: String, ctaTitle: String, action: @escaping () -> Void) -> some View {
        SolInsightCard(
            icon: "sparkles",
            label: "SOLOMON",
            timestamp: nil,
            accent: .mint
        ) {
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(Color.white.opacity(0.85))
                .lineSpacing(2)
                .padding(.bottom, 12)
            HStack {
                SolPrimaryButton(ctaTitle, accent: .mint, action: action)
                Spacer()
            }
        }
    }

    // MARK: - Helpers

    private func daysUntil(dayOfMonth target: Int) -> Int {
        let cal = Calendar.current
        let now = Date()
        let today = cal.component(.day, from: now)
        let daysInMonth = cal.range(of: .day, in: .month, for: now)?.count ?? 30
        if target >= today {
            return target - today
        }
        return (daysInMonth - today) + target
    }

    private func formatNum(_ amount: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = "."
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: abs(amount))) ?? "\(abs(amount))"
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ro_RO")
        f.dateFormat = "d MMM"
        return f.string(from: date)
    }
}

// MARK: - Hero math model (computed extern)

@MainActor
private struct WalletHeroModel {
    let amountWhole: String
    let amountDecimals: String
    let perDayRON: Int
    let daysUntilPayday: Int
    let paydayDateText: String
    let allocationSegments: [SolAllocationBar.Segment]
    let obligationsRON: Int
    let subscriptionsRON: Int
    let bufferRON: Int

    init(vm: WalletViewModel) {
        let cal = Calendar.current
        let now = Date()

        // Estimăm payday la ziua 8 a lunii viitoare (default rezonabil)
        let payday = WalletHeroModel.nextPayday(after: now, calendar: cal)
        let daysToPayday = max(1, cal.dateComponents([.day], from: now, to: payday).day ?? 9)

        // Computăm safe-to-spend dintr-o estimare:
        //   incoming luna asta − outgoing luna asta − obligations (rămase) − ghost subs
        let monthIncoming = WalletHeroModel.thisMonthSum(vm.transactions, direction: .incoming)
        let monthOutgoing = WalletHeroModel.thisMonthSum(vm.transactions, direction: .outgoing)
        let obligations = vm.obligationsTotalRON
        let subs = vm.subscriptionsTotalRON
        // Buffer ~10% din obligații, minim 100
        let buffer = max(100, obligations / 10)

        let net = max(0, monthIncoming - monthOutgoing - obligations - subs - buffer)
        // Dacă nu avem income (no data), fallback pe afișare neutră
        let safe = net > 0 ? net : max(0, 4_000 - obligations - subs - buffer)

        self.amountWhole = WalletHeroModel.formatGrouped(safe)
        self.amountDecimals = ",00"
        self.perDayRON = max(0, safe / max(1, daysToPayday))
        self.daysUntilPayday = daysToPayday
        self.paydayDateText = WalletHeroModel.formatPayday(payday)
        self.obligationsRON = obligations
        self.subscriptionsRON = subs
        self.bufferRON = buffer

        let total = max(1, obligations + subs + buffer + safe)
        let obFrac = CGFloat(obligations) / CGFloat(total)
        let svFrac = CGFloat(subs) / CGFloat(total)
        let bfFrac = CGFloat(buffer) / CGFloat(total)
        let rtFrac = max(0, 1 - obFrac - svFrac - bfFrac)

        self.allocationSegments = [
            .init(
                fraction: obFrac,
                gradient: LinearGradient(colors: [.solMintExact, .solMintDeep],
                                         startPoint: .leading, endPoint: .trailing),
                glowColor: Color.solMintExact.opacity(0.4)
            ),
            .init(
                fraction: svFrac,
                gradient: LinearGradient(colors: [.solBlueExact, .solBlueDeep],
                                         startPoint: .leading, endPoint: .trailing),
                glowColor: nil
            ),
            .init(
                fraction: bfFrac,
                gradient: LinearGradient(colors: [.solAmberExact, .solAmberDeep],
                                         startPoint: .leading, endPoint: .trailing),
                glowColor: nil
            ),
            .init(
                fraction: rtFrac,
                gradient: LinearGradient(colors: [Color.white.opacity(0.10), Color.white.opacity(0.10)],
                                         startPoint: .leading, endPoint: .trailing),
                glowColor: nil
            ),
        ]
    }

    private static func nextPayday(after date: Date, calendar: Calendar) -> Date {
        // Default payday: ziua 8 a lunii. Dacă a trecut, a lunii viitoare.
        let day = calendar.component(.day, from: date)
        var comps = calendar.dateComponents([.year, .month], from: date)
        comps.day = 8
        if day >= 8 {
            comps.month = (comps.month ?? 1) + 1
        }
        return calendar.date(from: comps) ?? date
    }

    private static func thisMonthSum(_ txs: [SolomonCore.Transaction], direction: FlowDirection) -> Int {
        let cal = Calendar.current
        let now = Date()
        let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: now)) ?? now
        return txs
            .filter { $0.direction == direction && $0.date >= monthStart && $0.date <= now }
            .reduce(0) { $0 + $1.amount.amount }
    }

    private static func formatGrouped(_ amount: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = "."
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }

    private static func formatPayday(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ro_RO")
        f.dateFormat = "d MMM"
        return f.string(from: date)
    }
}

// MARK: - Pattern detection (top outgoing category)

private enum WalletPattern {
    struct Result {
        let label: String
        let amount: Int
    }

    static func topOutgoingCategory(transactions: [SolomonCore.Transaction]) -> Result? {
        let cal = Calendar.current
        let now = Date()
        let weekAgo = cal.date(byAdding: .day, value: -7, to: now) ?? now

        let weekTx = transactions.filter {
            $0.isOutgoing && $0.date >= weekAgo && $0.date <= now
        }
        guard !weekTx.isEmpty else { return nil }

        var totals: [TransactionCategory: Int] = [:]
        for tx in weekTx {
            totals[tx.category, default: 0] += tx.amount.amount
        }

        guard let top = totals.max(by: { $0.value < $1.value }), top.value > 0 else { return nil }
        return Result(label: top.key.displayNameRO, amount: top.value)
    }
}

// MARK: - WalletViewModel (CoreData wired)

@Observable @MainActor
final class WalletViewModel {

    var obligations: [Obligation] = []
    var subscriptions: [Subscription] = []
    var transactions: [SolomonCore.Transaction] = []
    /// Salariul real al userului — încărcat din UserProfile pentru calcule corecte.
    /// Fallback la SolomonDefaults dacă profilul lipsește încă (race onboarding ↔ wallet).
    private var salaryMidRON: Int = SolomonDefaults.salaryMidpointFallbackRON

    private var transactionRepo: (any TransactionRepository)?
    private var obligationRepo: (any ObligationRepository)?
    private var subscriptionRepo: (any SubscriptionRepository)?
    private var userProfileRepo: (any UserProfileRepository)?
    private let usageDetector = SubscriptionUsageDetector()

    func configure(persistence: SolomonPersistenceController) {
        let ctx = persistence.container.viewContext
        self.transactionRepo  = CoreDataTransactionRepository(context: ctx)
        self.obligationRepo   = CoreDataObligationRepository(context: ctx)
        self.subscriptionRepo = CoreDataSubscriptionRepository(context: ctx)
        self.userProfileRepo  = CoreDataUserProfileRepository(context: ctx)
    }

    func load() async {
        obligations  = (try? obligationRepo?.fetchAll()) ?? []
        let allTx = (try? transactionRepo?.fetchAll()) ?? []
        let rawSubs = (try? subscriptionRepo?.fetchAll()) ?? []
        subscriptions = usageDetector.enrichWithUsage(subscriptions: rawSubs, transactions: allTx)
        transactions = (try? transactionRepo?.fetchRecent(limit: 50)) ?? []
        // Actualizăm salariul real din profilul userului
        if let profile = try? userProfileRepo?.fetchProfile() {
            salaryMidRON = profile.financials.salaryRange.midpointRON
        }
    }

    // MARK: - Computed totals

    var obligationsTotalRON: Int {
        obligations.reduce(0) { $0 + $1.amount.amount }
    }

    var obligationsTotalFormatted: String {
        RomanianMoneyFormatter.format(Money(obligationsTotalRON))
    }

    var obligationsPercentText: String {
        guard obligationsTotalRON > 0, salaryMidRON > 0 else { return "" }
        let pct = Int(Double(obligationsTotalRON) / Double(salaryMidRON) * 100)
        return "\(pct)% din venit"
    }

    var subscriptionsTotalRON: Int {
        subscriptions.reduce(0) { $0 + $1.amountMonthly.amount }
    }

    var subscriptionsTotalFormatted: String {
        RomanianMoneyFormatter.format(Money(subscriptionsTotalRON))
    }

    var ghostSavingsPotential: Int {
        subscriptions.filter { $0.isGhost }.reduce(0) { $0 + $1.amountMonthly.amount }
    }

    // MARK: - Delete helpers (apelate din swipeActions)

    func deleteObligation(id: UUID) {
        // FAZA C4: try? înghițea erori → user vedea UI-ul actualizat dar la relaunch
        // item-ul reapărea. Acum: pe error rollback la in-memory state și warning haptic.
        do {
            try obligationRepo?.delete(id: id)
            obligations.removeAll { $0.id == id }
            Haptics.success()
        } catch {
            Logger.persistence.error("deleteObligation failed \(id, privacy: .public): \(error.localizedDescription, privacy: .public)")
            Haptics.error()
        }
    }

    func deleteSubscription(id: UUID) {
        do {
            try subscriptionRepo?.delete(id: id)
            subscriptions.removeAll { $0.id == id }
            Haptics.success()
        } catch {
            Logger.persistence.error("deleteSubscription failed \(id, privacy: .public): \(error.localizedDescription, privacy: .public)")
            Haptics.error()
        }
    }

    func deleteTransaction(id: UUID) {
        do {
            try transactionRepo?.delete(id: id)
            transactions.removeAll { $0.id == id }
            Haptics.success()
        } catch {
            Logger.persistence.error("deleteTransaction failed \(id, privacy: .public): \(error.localizedDescription, privacy: .public)")
            Haptics.error()
        }
    }
}

// MARK: - Preview

#Preview {
    WalletView()
        .preferredColorScheme(.dark)
}
