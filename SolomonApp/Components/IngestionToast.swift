import SwiftUI
import SolomonCore

// MARK: - IngestionToast
//
// Banner mint care apare jos pe ecran când o tranzacție nouă e parsată
// dintr-o notificare bancară (via iOS Shortcuts).
//
// Auto-dismiss după 3.5s. Tap → dismiss instant.
//
// Utilizare:
//   .overlay(alignment: .bottom) {
//       IngestionToast(transaction: lastIngested) { onDismiss }
//   }

struct IngestionToast: View {

    // MARK: - Input

    let transaction: SolomonCore.Transaction
    let onDismiss: () -> Void

    // MARK: - Body

    var body: some View {
        HStack(spacing: SolSpacing.md) {
            ZStack {
                Circle()
                    .fill(Color.solMint.opacity(0.2))
                    .frame(width: 36, height: 36)
                Image(systemName: directionIcon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.solMint)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(headline)
                    .font(.solBodyBold)
                    .foregroundStyle(Color.solTextPrimary)
                    .lineLimit(1)
                Text(detail)
                    .font(.solCaption)
                    .foregroundStyle(Color.solTextSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(amountString)
                .font(.solMonoMD)
                .foregroundStyle(transaction.isIncoming ? Color.solMint : Color.solTextPrimary)
        }
        .padding(.horizontal, SolSpacing.md)
        .padding(.vertical, SolSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: SolRadius.lg, style: .continuous)
                .fill(Color.solElevated)
                .shadow(color: Color.black.opacity(0.4), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: SolRadius.lg)
                .stroke(Color.solMint.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, SolSpacing.screenHorizontal)
        .onTapGesture { onDismiss() }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Computed

    private var directionIcon: String {
        transaction.isIncoming ? "arrow.down.left" : "arrow.up.right"
    }

    private var headline: String {
        if let merchant = transaction.merchant {
            return merchant
        }
        return transaction.isIncoming ? "Sumă primită" : "Plată"
    }

    private var detail: String {
        let category = transaction.category.displayNameRO
        return "\(category) · acum"
    }

    private var amountString: String {
        let sign = transaction.isOutgoing ? "-" : "+"
        return "\(sign)\(transaction.amount.amount) RON"
    }
}

// MARK: - Modifier helper

extension View {
    /// Afișează un IngestionToast la fundul ecranului când vine o tranzacție nouă.
    func ingestionToast(
        transaction: Binding<SolomonCore.Transaction?>,
        autoDismissAfter seconds: TimeInterval = 3.5
    ) -> some View {
        self.overlay(alignment: .bottom) {
            if let tx = transaction.wrappedValue {
                IngestionToast(transaction: tx) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        transaction.wrappedValue = nil
                    }
                }
                .padding(.bottom, SolSpacing.xl)
                .task(id: tx.id) {
                    try? await Task.sleep(for: .seconds(seconds))
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        transaction.wrappedValue = nil
                    }
                }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85),
                   value: transaction.wrappedValue?.id)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.solCanvas.ignoresSafeArea()
        IngestionToast(
            transaction: SolomonCore.Transaction(
                id: UUID(),
                date: Date(),
                amount: Money(65),
                direction: .outgoing,
                category: .foodDelivery,
                merchant: "Glovo",
                description: nil,
                source: .notificationParsed,
                categorizationConfidence: 0.85
            ),
            onDismiss: {}
        )
    }
    .preferredColorScheme(.dark)
}
