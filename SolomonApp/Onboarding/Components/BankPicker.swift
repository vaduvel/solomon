import SwiftUI
import SolomonCore

// MARK: - BankPicker
//
// Grid 2-column de bank chips cu logo emoji + nume.
// Folosit în Ecran 4 onboarding.

struct BankPicker: View {

    @Binding var selectedBank: Bank?

    private let primaryBanks: [Bank] = [
        .bancaTransilvania, .bcr, .ing, .raiffeisen, .revolut, .other
    ]

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: SolSpacing.md
        ) {
            ForEach(primaryBanks, id: \.self) { bank in
                BankCard(
                    bank: bank,
                    isSelected: selectedBank == bank
                ) {
                    selectedBank = bank
                }
            }
        }
    }
}

private struct BankCard: View {
    let bank: Bank
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: SolSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(bankColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Text(bankInitial)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(bankColor)
                }
                Text(bank.displayNameRO)
                    .font(.solCaption)
                    .foregroundStyle(isSelected ? Color.solPrimary : Color.solForeground)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, SolSpacing.base)
            .background(
                RoundedRectangle(cornerRadius: SolRadius.xl, style: .continuous)
                    .fill(isSelected ? Color.solPrimary.opacity(0.10) : Color.solCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: SolRadius.xl, style: .continuous)
                    .stroke(
                        isSelected ? Color.solPrimary : Color.solBorder,
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: isSelected)
    }

    /// Brand color simulation per bancă (folosim accent ușor pentru recognoscibilitate)
    private var bankColor: Color {
        switch bank {
        case .bancaTransilvania: return Color(hex: "#FFB800")  // BT galben
        case .bcr:               return Color(hex: "#FF3B6D")  // BCR roșu
        case .ing:               return Color(hex: "#FF6B35")  // ING portocaliu
        case .raiffeisen:        return Color(hex: "#FFD700")  // Raiff galben
        case .revolut:           return Color.solCyan          // Revolut albastru
        case .other:             return Color.solMuted
        default:                 return Color.solPrimary
        }
    }

    private var bankInitial: String {
        switch bank {
        case .bancaTransilvania: return "BT"
        case .bcr:               return "BCR"
        case .ing:               return "ING"
        case .raiffeisen:        return "R"
        case .revolut:           return "R"
        case .other:             return "•"
        default:                 return String(bank.displayNameRO.prefix(2))
        }
    }
}

#Preview {
    @Previewable @State var bank: Bank? = .bancaTransilvania

    ZStack {
        Color.solCanvas.ignoresSafeArea()
        BankPicker(selectedBank: $bank)
            .padding(SolSpacing.lg)
    }
    .preferredColorScheme(.dark)
}
