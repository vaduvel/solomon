import SwiftUI
import SolomonCore

// MARK: - IngestionToast (Claude Design v3 — premium glass capsule)
//
// Toast care apare jos pe ecran când o tranzacție nouă e parsată dintr-o
// notificare bancară (via iOS Shortcuts).
//
// Design: capsule glass .ultraThinMaterial cu border mint .25, padding 12-16,
// icon checkmark.circle.fill mint stânga + text "Tranzacție X RON salvată" +
// mic dismiss "x" dreapta. Slide-in-from-bottom cu spring + auto-dismiss 3s.
//
// API public PĂSTRAT — `IngestionToast(transaction:onDismiss:)` și modifier
// `.ingestionToast(transaction:autoDismissAfter:)` rămân la fel.

struct IngestionToast: View {

    // MARK: - Input

    let transaction: SolomonCore.Transaction
    let onDismiss: () -> Void

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            // Icon checkmark mint cu glow
            ZStack {
                Circle()
                    .fill(Color.solMintExact.opacity(0.12))
                    .overlay(
                        Circle().stroke(Color.solMintExact.opacity(0.4), lineWidth: 1)
                    )
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.solMintExact)
                    .shadow(color: Color.solMintExact.opacity(0.5), radius: 4)
            }
            .frame(width: 32, height: 32)

            // Text body
            VStack(alignment: .leading, spacing: 1) {
                Text(headline)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .lineLimit(1)
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            // Dismiss small "x"
            Button {
                onDismiss()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            Circle().stroke(Color.white.opacity(0.10), lineWidth: 1)
                        )
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.7))
                }
                .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .background(
            LinearGradient(
                colors: [Color.solMintExact.opacity(0.06), Color.white.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(Capsule(style: .continuous))
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.solMintExact.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.4), radius: 16, x: 0, y: 6)
        .shadow(color: Color.solMintExact.opacity(0.18), radius: 20, x: 0, y: 4)
        .padding(.horizontal, 16)
        .onTapGesture { onDismiss() }
        .transition(
            .move(edge: .bottom)
                .combined(with: .opacity)
                .combined(with: .scale(scale: 0.92, anchor: .bottom))
        )
    }

    // MARK: - Computed

    private var headline: String {
        "Tranzacție \(transaction.amount.amount) RON salvată"
    }

    private var detail: String {
        if let merchant = transaction.merchant {
            return "\(merchant) · \(transaction.category.displayNameRO)"
        }
        return transaction.category.displayNameRO
    }
}

// MARK: - Modifier helper

extension View {
    /// Afișează un IngestionToast la fundul ecranului când vine o tranzacție nouă.
    /// Auto-dismiss după 3s cu animație spring slide-in-from-bottom.
    func ingestionToast(
        transaction: Binding<SolomonCore.Transaction?>,
        autoDismissAfter seconds: TimeInterval = 3.0
    ) -> some View {
        self.overlay(alignment: .bottom) {
            if let tx = transaction.wrappedValue {
                IngestionToast(transaction: tx) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                        transaction.wrappedValue = nil
                    }
                }
                .padding(.bottom, 64)
                .task(id: tx.id) {
                    try? await Task.sleep(for: .seconds(seconds))
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                        transaction.wrappedValue = nil
                    }
                }
            }
        }
        .animation(
            .spring(response: 0.4, dampingFraction: 0.82),
            value: transaction.wrappedValue?.id
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.solCanvasDark.ignoresSafeArea()
        VStack {
            Spacer()
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
            .padding(.bottom, 40)
        }
    }
    .preferredColorScheme(.dark)
}
