import SwiftUI
import SolomonCore
import SolomonStorage
import SolomonAnalytics

// MARK: - SuspiciousTransactionsView (Claude Design v3 — warning theme)
//
// Redesign editorial premium aliniat la Solomon DS:
//   - MeshBackground (amber + rose) pentru tema warning
//   - Sheet handle + custom AppBar: SolBackButton + brand "SOLOMON · DETECȚIE" + page "Tranzacții suspecte"
//   - Hero amber: badge "ATENȚIE", label "X DETECTATE · ULTIMELE 30 ZILE",
//     SolHeroAmount (sumă totală suspectă), copy
//   - SolInsightCard amber "DE CE LE-AM MARCAT" cu copy explicativ + CTA-uri
//   - SolSectionHeaderRow + SolListCard cu rows per tx (logo + title/sub + sumă rose + chip motiv)
//   - SolPrimaryButton "Confirm tot ca normal" (amber, fullWidth)
//
// Business logic preservat 1:1: SuspiciousDetector + transactionRepo + dismiss/confirm/ignore.

struct SuspiciousTransactionsView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var pairs: [(suspicion: SuspiciousTransactionDetector.Suspicion, transaction: SolomonCore.Transaction)] = []
    @State private var selectedPair: (suspicion: SuspiciousTransactionDetector.Suspicion, transaction: SolomonCore.Transaction)?

    private let detector = SuspiciousTransactionDetector()

    var body: some View {
        ZStack {
            MeshBackground(
                topLeftAccent: .amber,
                midRightAccent: .rose,
                bottomLeftAccent: .amber
            )

            ScrollView {
                VStack(spacing: SolSpacing.base) {
                    sheetHandle
                    topBar

                    if pairs.isEmpty {
                        emptyState
                            .padding(.top, SolSpacing.lg)
                    } else {
                        heroCard

                        whyInsightCard

                        suspiciousListSection

                        SolPrimaryButton(
                            "Confirm tot ca normal",
                            accent: .amber,
                            fullWidth: true
                        ) {
                            confirmAll()
                        }
                        .padding(.top, SolSpacing.xs)
                    }

                    Spacer(minLength: SolSpacing.xxl)
                }
                .padding(.horizontal, SolSpacing.screenHorizontal)
                .padding(.top, SolSpacing.xs)
                .padding(.bottom, SolSpacing.hh)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { load() }
        .confirmationDialog(
            "Acțiune pentru tranzacție",
            isPresented: Binding(
                get: { selectedPair != nil },
                set: { if !$0 { selectedPair = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let pair = selectedPair {
                Button("Da, eu am făcut-o") {
                    confirm(pair)
                    selectedPair = nil
                }
                Button("Nu, alertează banca", role: .destructive) {
                    reject(pair)
                    selectedPair = nil
                }
                Button("Anulează", role: .cancel) {
                    selectedPair = nil
                }
            }
        } message: {
            if let pair = selectedPair {
                Text("\(pair.transaction.merchant ?? "Tranzacție") · \(pair.transaction.amount.amount) RON")
            }
        }
    }

    // MARK: - Sheet handle (top grip)

    @ViewBuilder
    private var sheetHandle: some View {
        Capsule()
            .fill(Color.white.opacity(0.18))
            .frame(width: 36, height: 5)
            .padding(.top, 8)
            .padding(.bottom, 4)
    }

    // MARK: - Top bar (back + brand + page title + spacer)

    @ViewBuilder
    private var topBar: some View {
        HStack(alignment: .center, spacing: 12) {
            SolBackButton { dismiss() }

            VStack(alignment: .center, spacing: 2) {
                Text("SOLOMON · DETECȚIE")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.solAmberExact)
                    .tracking(1.4)
                    .textCase(.uppercase)
                Text("Tranzacții suspecte")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .tracking(-0.4)
            }
            .frame(maxWidth: .infinity)

            // Right spacer to balance back button
            Color.clear.frame(width: 38, height: 38)
        }
        .padding(.bottom, SolSpacing.sm)
    }

    // MARK: - Hero (amber) — total suspect

    @ViewBuilder
    private var heroCard: some View {
        SolHeroCard(accent: .amber) {
            VStack(alignment: .leading, spacing: 10) {
                SolHeroLabel(heroLabel)

                SolHeroAmount(
                    amount: heroBigAmount,
                    decimals: ",00",
                    currency: "RON SUSPECȚI",
                    accent: .amber
                )

                HStack(spacing: 8) {
                    Text(severitySummaryText)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.solAmberDeep)
                    if pairs.count > 1 {
                        Circle()
                            .fill(Color.white.opacity(0.25))
                            .frame(width: 3, height: 3)
                        Text("\(pairs.count) verificări")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.white.opacity(0.55))
                    }
                    Spacer(minLength: 0)
                }
                .padding(.top, 2)
                .padding(.bottom, 4)

                Text("Verifică-le rapid — confirmă tu sau alertează banca dacă nu recunoști vreuna.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.65))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } badge: {
            SolHeroBadge("ATENȚIE", accent: .amber)
        }
    }

    // MARK: - Insight (amber) — de ce le-am marcat

    @ViewBuilder
    private var whyInsightCard: some View {
        SolInsightCard(
            icon: "exclamationmark.circle",
            label: "DE CE LE-AM MARCAT",
            timestamp: "scan azi",
            accent: .amber
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text(whyInsightText)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.white.opacity(0.85))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    SolPrimaryButton("Verifică toate", accent: .amber) {
                        // Open primul pair pentru review rapid
                        if let first = pairs.first {
                            selectedPair = first
                        }
                    }
                    SolSecondaryButton("Ignoră") {
                        confirmAll()
                    }
                }
            }
        }
    }

    private var whyInsightText: AttributedString {
        var s = AttributedString()

        let triggers = Set(pairs.map { $0.suspicion.trigger })
        var fragments: [String] = []

        if triggers.contains(.largeAmountVsAverage) {
            fragments.append("sumă peste tipar")
        }
        if triggers.contains(.unusualNightMerchant) {
            fragments.append("merchant nou la noapte")
        }
        if triggers.contains(.burstActivity) {
            fragments.append("burst de tranzacții")
        }

        let fragmentText = fragments.isEmpty ? "tipar neobișnuit" : fragments.joined(separator: ", ")

        var head = AttributedString("Solomon a detectat \(fragmentText) în ultimele 30 zile. ")
        head.foregroundColor = Color.white.opacity(0.85)
        s += head

        var accent = AttributedString("Tu ești cel care le-ai făcut?")
        accent.foregroundColor = .solAmberExact
        s += accent

        return s
    }

    // MARK: - Suspicious list section

    @ViewBuilder
    private var suspiciousListSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SolSectionHeaderRow(
                "DETALIATE",
                meta: "\(pairs.count) \(pairs.count == 1 ? "tranzacție" : "tranzacții")"
            )
            .padding(.top, 4)

            SolListCard {
                ForEach(Array(pairs.enumerated()), id: \.element.suspicion.id) { idx, pair in
                    if idx > 0 { SolHairlineDivider() }
                    SuspiciousTxRow(
                        suspicion: pair.suspicion,
                        transaction: pair.transaction,
                        onTap: { selectedPair = pair }
                    )
                }
            }
        }
    }

    // MARK: - Empty state

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: SolSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(SolAccent.mint.iconGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.solMintExact.opacity(0.25), lineWidth: 1)
                    )
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(Color.solMintExact)
            }
            .frame(width: 64, height: 64)
            .shadow(color: Color.solMintExact.opacity(0.25), radius: 16)

            Text("Totul pare normal")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color.white)
                .tracking(-0.4)

            Text("Solomon nu a detectat nicio tranzacție suspectă în ultimele 30 zile.")
                .font(.system(size: 14))
                .foregroundStyle(Color.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .padding(.horizontal, SolSpacing.lg)

            SolSecondaryButton("Închide", fullWidth: false) { dismiss() }
                .padding(.top, SolSpacing.sm)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, SolSpacing.xxl)
    }

    // MARK: - Hero copy helpers

    private var heroLabel: String {
        "\(pairs.count) DETECTATE · ULTIMELE 30 ZILE"
    }

    private var heroBigAmount: String {
        "\(totalSuspectAmount)"
    }

    private var totalSuspectAmount: Int {
        pairs.reduce(0) { $0 + $1.transaction.amount.amount }
    }

    private var severitySummaryText: String {
        let highCount = pairs.filter { $0.suspicion.severity == .high }.count
        let mediumCount = pairs.filter { $0.suspicion.severity == .medium }.count
        if highCount > 0 {
            return "\(highCount) urgente · revizuiește acum"
        }
        if mediumCount > 0 {
            return "\(mediumCount) cu atenție crescută"
        }
        return "soft ping — verificare ușoară"
    }

    // MARK: - Logic (preservat 1:1)

    private func load() {
        let ctx = SolomonPersistenceController.shared.container.viewContext
        let repo = CoreDataTransactionRepository(context: ctx)
        let cal = Calendar.current
        let from30 = cal.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recent = (try? repo.fetch(from: from30, to: Date())) ?? []
        let suspicions = detector.detect(in: recent, referenceDate: Date())

        pairs = suspicions.compactMap { s in
            guard let tx = recent.first(where: { $0.id == s.transactionId }) else { return nil }
            return (s, tx)
        }
    }

    private func confirm(_ pair: (suspicion: SuspiciousTransactionDetector.Suspicion, transaction: SolomonCore.Transaction)) {
        // Salvăm transaction.id în UserDefaults ca "confirmed pattern" → ignorat de detector în viitor
        var confirmed = UserDefaults.standard.stringArray(forKey: Self.confirmedKey) ?? []
        confirmed.append(pair.transaction.id.uuidString)
        UserDefaults.standard.set(confirmed, forKey: Self.confirmedKey)
        Haptics.success()
        pairs.removeAll { $0.suspicion.id == pair.suspicion.id }
    }

    private func confirmAll() {
        guard !pairs.isEmpty else { return }
        var confirmed = UserDefaults.standard.stringArray(forKey: Self.confirmedKey) ?? []
        for pair in pairs {
            confirmed.append(pair.transaction.id.uuidString)
        }
        UserDefaults.standard.set(confirmed, forKey: Self.confirmedKey)
        Haptics.success()
        pairs.removeAll()
    }

    private func reject(_ pair: (suspicion: SuspiciousTransactionDetector.Suspicion, transaction: SolomonCore.Transaction)) {
        // Deschide app-ul băncii primare pentru a bloca cardul. Fallback: ANPC sesizare.
        let ctx = SolomonPersistenceController.shared.container.viewContext
        let userRepo = CoreDataUserProfileRepository(context: ctx)
        let bank = (try? userRepo.fetchProfile())?.financials.primaryBank
        if let bank, let url = bankAppDeeplink(bank: bank) {
            UIApplication.shared.open(url)
        } else if let anpc = URL(string: "https://anpc.ro/sesizari-online/") {
            UIApplication.shared.open(anpc)
        }
        Haptics.warning()
        pairs.removeAll { $0.suspicion.id == pair.suspicion.id }
    }

    private static let confirmedKey = "solomon.suspicious.confirmed"

    private func bankAppDeeplink(bank: Bank) -> URL? {
        switch bank {
        case .bancaTransilvania: return URL(string: "https://apps.apple.com/ro/app/bt-pay/id1116242878")
        case .bcr:               return URL(string: "https://apps.apple.com/ro/app/george-bcr/id1110144611")
        case .ing:               return URL(string: "https://apps.apple.com/ro/app/ing-home-bank/id1099660716")
        case .raiffeisen:        return URL(string: "https://apps.apple.com/ro/app/smart-mobile/id1071893824")
        case .revolut:           return URL(string: "https://apps.apple.com/ro/app/revolut/id932493382")
        default:                 return nil
        }
    }
}

// MARK: - SuspiciousTxRow (logo + nume + chip + sumă rose + chevron)

private struct SuspiciousTxRow: View {
    let suspicion: SuspiciousTransactionDetector.Suspicion
    let transaction: SolomonCore.Transaction
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            Haptics.light()
            onTap()
        }) {
            HStack(spacing: 12) {
                logoView

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(transaction.merchant ?? transaction.category.displayNameRO)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.white)
                            .lineLimit(1)
                        chipForTrigger
                    }
                    Text(subtitleText)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.4))
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 1) {
                    Text("−\(transaction.amount.amount)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.solRoseExact)
                        .monospacedDigit()
                        .tracking(-0.3)
                    Text("RON")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.white.opacity(0.35))
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.3))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var chipForTrigger: some View {
        switch suspicion.trigger {
        case .largeAmountVsAverage:
            SolChip("Sumă mare", kind: .warn)
        case .unusualNightMerchant:
            SolChip("Merchant nou", kind: .rose)
        case .burstActivity:
            SolChip("Burst", kind: .rose)
        }
    }

    @ViewBuilder
    private var logoView: some View {
        SolBrandLogo(brandFor(category: transaction.category, merchant: transaction.merchant))
    }

    private var subtitleText: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMM, HH:mm"
        dateFormatter.locale = Locale(identifier: "ro_RO")
        let dateStr = dateFormatter.string(from: transaction.date)

        if let merchant = transaction.merchant, !merchant.isEmpty,
           merchant.lowercased() != transaction.category.displayNameRO.lowercased() {
            return "\(transaction.category.displayNameRO) · \(dateStr)"
        }
        return dateStr
    }

    /// Pick logo based on category or merchant. Fallback `dotted` for unknown.
    private func brandFor(category: TransactionCategory, merchant: String?) -> SolBrandLogo.Brand {
        let m = merchant?.lowercased() ?? ""
        if m.contains("glovo") { return .glovo }
        if m.contains("bolt") { return .bolt }
        if m.contains("uber") { return .uber }
        if m.contains("netflix") { return .netflix }
        if m.contains("spotify") { return .spotify }
        if m.contains("hbo") { return .hbo }
        if m.contains("apple") { return .applemusic }
        if m.contains("ing") { return .ing }
        if m.contains("brd") { return .brd }
        if m.contains("bcr") { return .bcr }
        if m.contains("raiffeisen") { return .raiffeisen }
        if m.contains("mega") || m.contains("kaufland") || m.contains("lidl") || m.contains("carrefour") {
            return .mega
        }

        // Fallback by category
        switch category {
        case .foodDelivery, .foodDining:
            return .glovo
        case .transport:
            return .bolt
        case .shoppingOnline, .shoppingOffline:
            return .custom(
                letter: "S",
                gradient: LinearGradient(
                    colors: [
                        Color(red: 0x3B/255, green: 0x82/255, blue: 0xF6/255),
                        Color(red: 0x25/255, green: 0x63/255, blue: 0xEB/255)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                foreground: .white
            )
        case .entertainment:
            return .netflix
        case .subscriptions:
            return .spotify
        default:
            // Use first letter on muted gradient
            let letter = String((merchant ?? "?").prefix(1)).uppercased()
            if letter == "?" || letter.isEmpty {
                return .dotted
            }
            return .custom(
                letter: letter,
                gradient: LinearGradient(
                    colors: [Color.white.opacity(0.10), Color.white.opacity(0.04)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                foreground: .white
            )
        }
    }
}

#Preview {
    SuspiciousTransactionsView()
        .preferredColorScheme(.dark)
}
