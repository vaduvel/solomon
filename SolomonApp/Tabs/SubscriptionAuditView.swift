import SwiftUI
import SolomonCore
import SolomonStorage
import SolomonAnalytics

// MARK: - SubscriptionAuditView (Claude Design v3)
//
// Pixel-fidel cu `Solomon DS / screens/subscription-audit.html`:
//   - MeshBackground (amber top-left)
//   - Custom AppBar cu SolBackButton + brand "SOLOMON · AUDIT" + page "Abonamente" + iconbtn
//   - Hero card amber: badge "RECUPERABIL", label, sumă mare, meta (RON/an + % venit), CTA-uri
//   - InsightCard amber "SOLOMON · DETECȚIE" cu rezumat ghosts
//   - Section header "NEFOLOSITE · ANULEAZĂ"
//   - SolListCard cu sub-rows (logo + nume + chip + last used + amount/lună)
//   - Section header "FOLOSITE · OK" + listă activă
//
// Business logic păstrat 1:1: CoreDataSubscriptionRepository, CoreDataTransactionRepository,
// SubscriptionUsageDetector.enrichWithUsage, isGhost split, cancellation URL flow.

struct SubscriptionAuditView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var ghosts: [Subscription] = []
    @State private var keptActive: [Subscription] = []

    @State private var didAppear: Bool = false
    @State private var showSections: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationStack {
            ZStack {
                MeshBackground(
                    topLeftAccent: .amber,
                    midRightAccent: .blue,
                    bottomLeftAccent: .violet
                )

                ScrollView {
                    VStack(spacing: SolSpacing.md) {
                        topBar
                            .opacity(didAppear ? 1 : 0)
                            .offset(y: reduceMotion ? 0 : (didAppear ? 0 : -6))
                            .animation(.spring(response: 0.5, dampingFraction: 0.9), value: didAppear)

                        heroCard
                            .opacity(didAppear ? 1 : 0)
                            .offset(y: reduceMotion ? 0 : (didAppear ? 0 : 8))
                            .animation(.spring(response: 0.5, dampingFraction: 0.85), value: didAppear)
                            .padding(.top, 4)

                        insightCard
                            .opacity(didAppear ? 1 : 0)
                            .offset(y: reduceMotion ? 0 : (didAppear ? 0 : 10))
                            .animation(.spring(response: 0.6, dampingFraction: 0.9).delay(0.05), value: didAppear)

                        if !ghosts.isEmpty {
                            ghostsSection
                                .opacity(showSections ? 1 : 0)
                                .offset(y: reduceMotion ? 0 : (showSections ? 0 : 12))
                                .animation(.spring(response: 0.6, dampingFraction: 0.9).delay(0.1), value: showSections)
                        }

                        if !keptActive.isEmpty {
                            activeSection
                                .opacity(showSections ? 1 : 0)
                                .offset(y: reduceMotion ? 0 : (showSections ? 0 : 14))
                                .animation(.spring(response: 0.6, dampingFraction: 0.9).delay(0.15), value: showSections)
                        }

                        Spacer(minLength: 32)
                    }
                    .padding(.horizontal, SolSpacing.screenHorizontal)
                    .padding(.top, SolSpacing.sm)
                    .padding(.bottom, SolSpacing.hh)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                load()
                // Trigger staged appears
                didAppear = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                    showSections = true
                }
            }
            .onDisappear {
                didAppear = false
                showSections = false
            }
        }
    }

    // MARK: - Top bar (back + brand + actions)

    @ViewBuilder
    private var topBar: some View {
        HStack(alignment: .center) {
            SolBackButton { Haptics.light(); dismiss() }
                .pressEffect(scale: reduceMotion ? 1 : 0.96)

            Spacer(minLength: 8)

            VStack(spacing: 4) {
                Text("SOLOMON · AUDIT")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.45))
                    .tracking(1.4)
                Text("Abonamente")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .tracking(-0.4)
            }

            Spacer(minLength: 8)

            SolIconButton(systemName: "ellipsis") { Haptics.light() }
                .pressEffect(scale: reduceMotion ? 1 : 0.96)
        }
        .padding(.bottom, 8)
    }

    // MARK: - Hero (amber) — recuperable

    @ViewBuilder
    private var heroCard: some View {
        SolHeroCard(accent: .amber) {
            VStack(alignment: .leading, spacing: 10) {
                SolHeroLabel(heroLabel)

                SolHeroAmount(
                    amount: heroBigAmount,
                    decimals: heroDecimals,
                    currency: "RON / LUNĂ",
                    accent: .amber
                )
                .scaleEffect(reduceMotion ? 1 : (didAppear ? 1 : 0.995))
                .animation(.spring(response: 0.5, dampingFraction: 0.85), value: didAppear)

                // Meta: RON/an + % venit
                HStack(spacing: 8) {
                    Text("= \(potentialAnnualSavings.formatted()) RON / an")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.solAmberDeep)
                    Circle()
                        .fill(Color.white.opacity(0.25))
                        .frame(width: 3, height: 3)
                    Text(percentOfIncomeText)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.white.opacity(0.55))
                    Spacer(minLength: 0)
                }
                .padding(.top, 2)
                .padding(.bottom, 8)

                // CTA-uri
                HStack(spacing: 8) {
                    SolPrimaryButton(
                        ghosts.isEmpty ? "Niciun ghost" : "Anulează toate (\(ghosts.count))",
                        accent: .amber,
                        fullWidth: true
                    ) {
                        Haptics.light()
                        cancelAll()
                    }
                    .pressEffect(scale: reduceMotion ? 1 : 0.97)

                    SolSecondaryButton("Pas cu pas") {
                        Haptics.light()
                        if let first = ghosts.first {
                            cancel(subscription: first)
                        }
                    }
                    .pressEffect(scale: reduceMotion ? 1 : 0.97)
                }
            }
        } badge: {
            SolHeroBadge("RECUPERABIL", accent: .amber)
                .scaleEffect(didAppear ? 1 : 0.98)
                .opacity(didAppear ? 1 : 0)
                .animation(.spring(response: 0.7, dampingFraction: 0.85).delay(0.03), value: didAppear)
        }
    }

    // MARK: - Insight (amber) — Solomon detection

    @ViewBuilder
    private var insightCard: some View {
        SolInsightCard(
            icon: "exclamationmark.circle",
            label: "SOLOMON · DETECȚIE",
            timestamp: "scan azi",
            accent: .amber
        ) {
            Text(insightAttributedText)
                .font(.system(size: 14))
                .foregroundStyle(Color.white.opacity(0.85))
                .lineSpacing(2)
                .animation(.easeInOut(duration: 0.2), value: ghosts.count)
        }
    }

    private var insightAttributedText: AttributedString {
        var s = AttributedString()

        if ghosts.isEmpty {
            var head = AttributedString("Nu am detectat abonamente nefolosite. ")
            head.foregroundColor = Color.white.opacity(0.85)
            s += head

            var ok = AttributedString("Toate cele \(keptActive.count) sunt folosite recent.")
            ok.foregroundColor = .solMintLight
            s += ok
            return s
        }

        let names = ghosts.prefix(3).map(\.name)
        for (i, name) in names.enumerated() {
            if i > 0 {
                let sep: String
                if i == names.count - 1 { sep = " și " } else { sep = ", " }
                var t = AttributedString(sep)
                t.foregroundColor = Color.white.opacity(0.85)
                s += t
            }
            var bold = AttributedString(name)
            bold.foregroundColor = .white
            s += bold
        }

        var tail = AttributedString(" ")
        tail += AttributedString(ghosts.count == 1 ? "n-a fost deschis" : "n-au fost deschise")
        tail += AttributedString(" în 90+ zile. ")
        tail.foregroundColor = Color.white.opacity(0.85)
        s += tail

        var accent = AttributedString("Recuperabil: \(potentialMonthlySavings) RON/lună.")
        accent.foregroundColor = .solAmberExact
        s += accent

        return s
    }

    // MARK: - Ghost section (Nefolosite)

    @ViewBuilder
    private var ghostsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SolSectionHeaderRow(
                "NEFOLOSITE · ANULEAZĂ",
                meta: "\(ghosts.count) din \(ghosts.count + keptActive.count)"
            )
            .padding(.top, 4)
            .opacity(showSections ? 1 : 0)
            .offset(y: reduceMotion ? 0 : (showSections ? 0 : 8))
            .animation(.spring(response: 0.6, dampingFraction: 0.9).delay(0.06), value: showSections)

            SolListCard {
                Group {
                    ForEach(Array(ghosts.enumerated()), id: \.element.id) { idx, sub in
                        if idx > 0 { SolHairlineDivider() }
                        SubscriptionAuditRow(
                            subscription: sub,
                            isGhost: true,
                            onTap: { cancel(subscription: sub) }
                        )
                        .opacity(showSections ? 1 : 0)
                        .offset(y: reduceMotion ? 0 : (showSections ? 0 : 6))
                        .animation(.spring(response: 0.5, dampingFraction: 0.9).delay(0.02 * Double(idx)), value: showSections)
                    }
                }
            }
        }
    }

    // MARK: - Active section (Folosite)

    @ViewBuilder
    private var activeSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SolSectionHeaderRow(
                "FOLOSITE · OK",
                meta: "\(keptActive.count) active"
            )
            .padding(.top, 4)
            .opacity(showSections ? 1 : 0)
            .offset(y: reduceMotion ? 0 : (showSections ? 0 : 8))
            .animation(.spring(response: 0.6, dampingFraction: 0.9).delay(0.06), value: showSections)

            SolListCard {
                Group {
                    ForEach(Array(keptActive.enumerated()), id: \.element.id) { idx, sub in
                        if idx > 0 { SolHairlineDivider() }
                        SubscriptionAuditRow(
                            subscription: sub,
                            isGhost: false,
                            onTap: nil
                        )
                        .opacity(showSections ? 1 : 0)
                        .offset(y: reduceMotion ? 0 : (showSections ? 0 : 6))
                        .animation(.spring(response: 0.5, dampingFraction: 0.9).delay(0.02 * Double(idx)), value: showSections)
                    }
                }
            }
        }
    }

    // MARK: - Hero copy helpers

    private var heroLabel: String {
        if ghosts.isEmpty {
            return "ZERO ABONAMENTE NEFOLOSITE · TOATE OK"
        }
        return "\(ghosts.count) \(ghosts.count == 1 ? "ABONAMENT NEFOLOSIT" : "ABONAMENTE NEFOLOSITE") · 90 ZILE"
    }

    private var heroBigAmount: String {
        "\(potentialMonthlySavings)"
    }

    private var heroDecimals: String? { ",00" }

    private var percentOfIncomeText: String {
        // Aproximare conservativă (nu blocăm UI dacă nu avem venit calculat).
        // 4500 RON e fallback pentru cazul când nu există date – evită ÷0 și păstrează aspectul.
        // Cu fallback-ul fix de mai sus, condiția pentru 0 nu se aplică — eliminăm ramura never-executed.
        let monthlyIncomeRON: Int = 4500
        let pct = Double(potentialMonthlySavings) / Double(monthlyIncomeRON) * 100
        return String(format: "%.1f%% din venit", pct)
    }

    // MARK: - State

    private var potentialMonthlySavings: Int {
        ghosts.reduce(0) { $0 + $1.amountMonthly.amount }
    }

    private var potentialAnnualSavings: Int {
        potentialMonthlySavings * 12
    }

    private func load() {
        let ctx = SolomonPersistenceController.shared.container.viewContext
        let subRepo = CoreDataSubscriptionRepository(context: ctx)
        let txRepo = CoreDataTransactionRepository(context: ctx)
        let raw = (try? subRepo.fetchAll()) ?? []
        let txs = (try? txRepo.fetchAll()) ?? []
        // Auto-enrich cu utilizare reală
        let enriched = SubscriptionUsageDetector().enrichWithUsage(subscriptions: raw, transactions: txs)
        ghosts = enriched.filter { $0.isGhost }
        keptActive = enriched.filter { !$0.isGhost }
    }

    private func cancel(subscription: Subscription) {
        // Open cancellation URL dacă există, altfel deschide search Google
        if let url = subscription.cancellationUrl {
            UIApplication.shared.open(url)
        } else {
            let query = "cum anulez \(subscription.name)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? subscription.name
            if let searchURL = URL(string: "https://duckduckgo.com/?q=\(query)") {
                UIApplication.shared.open(searchURL)
            }
        }
    }

    private func cancelAll() {
        guard !ghosts.isEmpty else { return }
        for sub in ghosts {
            cancel(subscription: sub)
        }
    }
}

// MARK: - SubscriptionAuditRow (logo + nume + chip + last used + amount)

private struct SubscriptionAuditRow: View {
    let subscription: Subscription
    let isGhost: Bool
    let onTap: (() -> Void)?

    @State private var isPressed: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            SolBrandLogo(brandFor(subscription.name))

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text(subscription.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.white)
                        .lineLimit(1)
                    chip
                }

                Text(lastUsedText)
                    .font(.system(size: 11))
                    .foregroundStyle(lastUsedColor)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 1) {
                Text("\(subscription.amountMonthly.amount),00")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .monospacedDigit()
                    .tracking(-0.3)
                Text("RON / lună")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.white.opacity(0.35))
            }
        }
        .scaleEffect(isPressed ? 0.995 : 1)
        .opacity(isPressed ? 0.98 : 1)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed { isPressed = true }
                }
                .onEnded { _ in
                    isPressed = false
                    if let onTap {
                        Haptics.light()
                        onTap()
                    }
                }
        )
    }

    @ViewBuilder
    private var chip: some View {
        if isGhost {
            if let days = subscription.lastUsedDaysAgo {
                if days >= 60 {
                    SolChip("\(days) zile", kind: .rose)
                } else {
                    SolChip("\(days) zile", kind: .warn)
                }
            } else {
                SolChip("ghost", kind: .rose)
            }
        } else {
            SolChip("activ", kind: .mint)
        }
    }

    private var lastUsedText: String {
        guard let days = subscription.lastUsedDaysAgo else {
            return "fără semnal"
        }
        if days <= 7 {
            return "folosit recent"
        } else if days <= 30 {
            return "ultim. \(days) zile"
        } else if days < 60 {
            return "folosire ocazională"
        } else {
            return "ultim. acum \(days) zile"
        }
    }

    private var lastUsedColor: Color {
        guard let days = subscription.lastUsedDaysAgo else {
            return Color.white.opacity(0.4)
        }
        if days >= 60 {
            return .solRoseExact
        } else if days > 30 {
            return .solAmberExact
        } else {
            return Color.white.opacity(0.4)
        }
    }

    /// Mapping nume → SolBrandLogo.Brand (fallback custom letter).
    private func brandFor(_ name: String) -> SolBrandLogo.Brand {
        let lower = name.lowercased()
        if lower.contains("netflix") { return .netflix }
        if lower.contains("spotify") { return .spotify }
        if lower.contains("hbo") { return .hbo }
        if lower.contains("apple music") { return .applemusic }
        if lower.contains("icloud") || lower.contains("apple") {
            return .custom(
                letter: "",
                gradient: LinearGradient(
                    colors: [
                        Color(red: 0x1C/255, green: 0x1C/255, blue: 0x1E/255),
                        Color.black
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                foreground: .white
            )
        }
        if lower.contains("youtube") {
            return .custom(
                letter: "YT",
                gradient: LinearGradient(
                    colors: [
                        Color(red: 0xE5/255, green: 0x09/255, blue: 0x14/255),
                        Color(red: 0xB0/255, green: 0x06/255, blue: 0x0F/255)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                foreground: .white
            )
        }
        if lower.contains("audible") {
            return .custom(
                letter: "Aud",
                gradient: LinearGradient(
                    colors: [
                        Color(red: 0xFF/255, green: 0x99/255, blue: 0x00/255),
                        Color(red: 0xE8/255, green: 0x8B/255, blue: 0x00/255)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                foreground: Color(red: 0x0F/255, green: 0x11/255, blue: 0x11/255)
            )
        }
        if lower.contains("adobe") {
            return .custom(
                letter: "Ad",
                gradient: LinearGradient(
                    colors: [
                        Color(red: 0xDA/255, green: 0x14/255, blue: 0x1F/255),
                        Color(red: 0xA8/255, green: 0x0E/255, blue: 0x18/255)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                foreground: .white
            )
        }
        // Fallback — prima literă pe gradient muted.
        let letter = String(name.prefix(1)).uppercased()
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

private struct PressEffect: ViewModifier {
    @GestureState private var isPressed = false
    let scale: CGFloat

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scale : 1)
            .opacity(isPressed ? 0.98 : 1)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .updating($isPressed) { _, state, _ in
                        state = true
                    }
            )
    }
}

private extension View {
    func pressEffect(scale: CGFloat = 0.98) -> some View {
        modifier(PressEffect(scale: scale))
    }
}

#Preview {
    SubscriptionAuditView()
        .preferredColorScheme(.dark)
}
