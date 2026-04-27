import SwiftUI
import SolomonCore
import SolomonStorage
import SolomonAnalytics

// MARK: - SuspiciousTransactionsView
//
// Vizualizează tranzacțiile flagate de SuspiciousTransactionDetector cu evidence
// + soft ping CTA ("Tu ești? / Nu, blochează cardul").

struct SuspiciousTransactionsView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var pairs: [(suspicion: SuspiciousTransactionDetector.Suspicion, transaction: SolomonCore.Transaction)] = []

    private let detector = SuspiciousTransactionDetector()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.solCanvas.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: SolSpacing.md) {
                        if pairs.isEmpty {
                            emptyState
                        } else {
                            heroSummary
                            ForEach(pairs, id: \.suspicion.id) { pair in
                                SuspiciousCard(
                                    suspicion: pair.suspicion,
                                    transaction: pair.transaction,
                                    onConfirm: { confirm(pair) },
                                    onReject: { reject(pair) }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, SolSpacing.screenHorizontal)
                    .padding(.top, SolSpacing.lg)
                    .padding(.bottom, SolSpacing.hh)
                }
            }
            .navigationTitle("Tranzacții suspecte")
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
    private var emptyState: some View {
        VStack(spacing: SolSpacing.md) {
            IconContainer(systemName: "checkmark.shield.fill", variant: .neon, size: 64, iconSize: 26)
            Text("Totul pare normal")
                .font(.solH3)
                .foregroundStyle(Color.solForeground)
            Text("Solomon nu a detectat nicio tranzacție suspectă în ultima perioadă.")
                .font(.solBody)
                .foregroundStyle(Color.solMuted)
                .multilineTextAlignment(.center)
        }
        .padding(SolSpacing.xl)
        .frame(maxWidth: .infinity, minHeight: 360)
        .solCard()
    }

    @ViewBuilder
    private var heroSummary: some View {
        HStack(spacing: SolSpacing.md) {
            IconContainer(systemName: "exclamationmark.triangle.fill", variant: .warn, size: 48, iconSize: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(pairs.count) tranzacții flagate")
                    .font(.solBodyBold)
                    .foregroundStyle(Color.solForeground)
                Text("Verifică-le rapid — confirmă tu sau alertează banca")
                    .font(.solCaption)
                    .foregroundStyle(Color.solMuted)
            }
            Spacer()
        }
        .padding(SolSpacing.cardStandard)
        .solCard()
    }

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
        // TODO: Salvăm pattern recunoscut în UserDefaults sau un nou domain model
        pairs.removeAll { $0.suspicion.id == pair.suspicion.id }
    }

    private func reject(_ pair: (suspicion: SuspiciousTransactionDetector.Suspicion, transaction: SolomonCore.Transaction)) {
        // TODO: Trigger workflow blocare card (deeplink la app bancă, sau call center)
        pairs.removeAll { $0.suspicion.id == pair.suspicion.id }
    }
}

// MARK: - SuspiciousCard

struct SuspiciousCard: View {
    let suspicion: SuspiciousTransactionDetector.Suspicion
    let transaction: SolomonCore.Transaction
    let onConfirm: () -> Void
    let onReject: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: SolSpacing.md) {
            HStack(spacing: SolSpacing.md) {
                IconContainer(
                    systemName: iconForTrigger,
                    variant: variantForSeverity,
                    size: 44,
                    iconSize: 18
                )
                VStack(alignment: .leading, spacing: 2) {
                    Text(transaction.merchant ?? "Tranzacție")
                        .font(.solBodyBold)
                        .foregroundStyle(Color.solForeground)
                    Text(suspicion.evidenceText)
                        .font(.solCaption)
                        .foregroundStyle(Color.solWarning)
                }
                Spacer()
                Text("−\(transaction.amount.amount) RON")
                    .font(.solMonoMD)
                    .foregroundStyle(Color.solDestructive)
            }

            HStack(spacing: SolSpacing.xs) {
                StatusBadge(title: severityLabel, kind: severityKind)
                LabelBadge(title: triggerLabel, color: variantForSeverity.color)
                Spacer()
                Text(formatDate(transaction.date))
                    .font(.solCaption)
                    .foregroundStyle(Color.solMuted)
            }

            Text("Tu ești cel care a făcut această plată?")
                .font(.solBody)
                .foregroundStyle(Color.solForeground)
                .padding(.top, SolSpacing.xs)

            HStack(spacing: SolSpacing.sm) {
                SolomonButton("Da, eu", icon: "checkmark", action: onConfirm)
                SolomonButton("Nu, alertă", style: .danger, icon: "exclamationmark.triangle", action: onReject)
            }
        }
        .padding(SolSpacing.cardStandard)
        .background(Color.solCard)
        .clipShape(RoundedRectangle(cornerRadius: SolRadius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: SolRadius.xl)
                .stroke(variantForSeverity.color.opacity(0.3), lineWidth: 1)
        )
    }

    private var iconForTrigger: String {
        switch suspicion.trigger {
        case .largeAmountVsAverage: return "arrow.up.right.square.fill"
        case .burstActivity:        return "bolt.fill"
        case .unusualNightMerchant: return "moon.fill"
        }
    }

    private var triggerLabel: String {
        switch suspicion.trigger {
        case .largeAmountVsAverage: return "Sumă mare"
        case .burstActivity:        return "Activitate burst"
        case .unusualNightMerchant: return "Noapte / merchant nou"
        }
    }

    private var severityLabel: String {
        switch suspicion.severity {
        case .soft:   return "Verifică"
        case .medium: return "Atenție"
        case .high:   return "URGENT"
        }
    }

    private var severityKind: StatusBadge.Kind {
        switch suspicion.severity {
        case .soft:   return .info
        case .medium: return .warning
        case .high:   return .danger
        }
    }

    private var variantForSeverity: IconContainer.Variant {
        switch suspicion.severity {
        case .soft:   return .cyan
        case .medium: return .warn
        case .high:   return .danger
        }
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "d MMM, HH:mm"
        f.locale = Locale(identifier: "ro_RO")
        return f.string(from: date)
    }
}

#Preview {
    SuspiciousTransactionsView()
        .preferredColorScheme(.dark)
}
