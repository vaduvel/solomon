import SwiftUI
import SolomonCore
import SolomonStorage
import SolomonAnalytics

// MARK: - SubscriptionAuditView
//
// Vizualizează ghost subscriptions (>30 zile nefolosite) cu sumar economii
// și CTA-uri pentru cancel. Folosit ca sheet din WalletView sau Settings.

struct SubscriptionAuditView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var ghosts: [Subscription] = []
    @State private var keptActive: [Subscription] = []

    var body: some View {
        NavigationStack {
            ZStack {
                Color.solCanvas.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: SolSpacing.lg) {

                        heroCard

                        if !ghosts.isEmpty {
                            ghostsSection
                        }

                        if !keptActive.isEmpty {
                            activeSection
                        }
                    }
                    .padding(.horizontal, SolSpacing.screenHorizontal)
                    .padding(.top, SolSpacing.lg)
                    .padding(.bottom, SolSpacing.hh)
                }
            }
            .navigationTitle("Audit abonamente")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Închide") { dismiss() }
                        .foregroundStyle(Color.solMuted)
                }
            }
            .onAppear { load() }
        }
    }

    @ViewBuilder
    private var heroCard: some View {
        VStack(spacing: SolSpacing.sm) {
            Text("Ai putea economisi")
                .font(.solCaption)
                .foregroundStyle(Color.solMuted)
                .textCase(.uppercase)
                .tracking(1.2)

            Text("\(potentialMonthlySavings) RON / lună")
                .font(.system(size: 40, weight: .bold, design: .monospaced))
                .foregroundStyle(LinearGradient.solHero)

            Text("≈ \(potentialAnnualSavings) RON / an dacă anulezi cele \(ghosts.count) abonamente nefolosite")
                .font(.solCaption)
                .foregroundStyle(Color.solMuted)
                .multilineTextAlignment(.center)
        }
        .padding(SolSpacing.cardHero)
        .frame(maxWidth: .infinity)
        .solGlassCard()
    }

    @ViewBuilder
    private var ghostsSection: some View {
        VStack(alignment: .leading, spacing: SolSpacing.sm) {
            sectionHeader("Abonamente fantomă")
            ForEach(ghosts) { sub in
                GhostSubscriptionCard(subscription: sub) {
                    cancel(subscription: sub)
                }
            }
        }
    }

    @ViewBuilder
    private var activeSection: some View {
        VStack(alignment: .leading, spacing: SolSpacing.sm) {
            sectionHeader("Abonamente folosite")
            ForEach(keptActive) { sub in
                SubscriptionRow(subscription: sub)
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.solMicro)
                .foregroundStyle(Color.solMuted)
                .textCase(.uppercase)
                .tracking(1.2)
            Spacer()
        }
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
}

// MARK: - GhostSubscriptionCard

struct GhostSubscriptionCard: View {
    let subscription: Subscription
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: SolSpacing.md) {
            HStack(spacing: SolSpacing.md) {
                IconContainer(systemName: "play.rectangle.fill", variant: .danger, size: 44, iconSize: 18)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: SolSpacing.xs) {
                        Text(subscription.name)
                            .font(.solH3)
                            .foregroundStyle(Color.solForeground)
                        LabelBadge(title: "GHOST", color: .solDestructive)
                    }
                    if let days = subscription.lastUsedDaysAgo {
                        Text("Nefolosit de \(days) zile")
                            .font(.solCaption)
                            .foregroundStyle(Color.solDestructive)
                    }
                }
                Spacer()
                Text("\(subscription.amountMonthly.amount) RON")
                    .font(.solMonoMD)
                    .foregroundStyle(Color.solForeground)
            }

            if let summary = subscription.cancellationStepsSummary {
                Text(summary)
                    .font(.solCaption)
                    .foregroundStyle(Color.solMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: SolSpacing.sm) {
                SolomonButton("Anulează abonamentul", style: .danger, icon: "xmark") {
                    onCancel()
                }
            }
        }
        .padding(SolSpacing.cardStandard)
        .background(Color.solCard)
        .clipShape(RoundedRectangle(cornerRadius: SolRadius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: SolRadius.xl)
                .stroke(Color.solDestructive.opacity(0.25), lineWidth: 1)
        )
    }
}

#Preview {
    SubscriptionAuditView()
        .preferredColorScheme(.dark)
}
