import SwiftUI

// MARK: - ShortcutSetupView
//
// Ghid pas-cu-pas pentru conectarea băncilor via iOS Shortcuts.
// Userul creează o automatizare care trimite notificările bancare
// la Solomon prin URL scheme `solomon://transaction?raw=...`
//
// Accesibil din: Settings → Conectează banca

struct ShortcutSetupView: View {

    // MARK: - Supported Banks

    struct SupportedBank: Identifiable {
        let id = UUID()
        let name: String
        let icon: String          // SF Symbol sau emoji fallback
        let appScheme: String?    // pentru „Deschide aplicația" check
        let notificationExample: String
    }

    static let banks: [SupportedBank] = [
        SupportedBank(
            name: "Banca Transilvania (BT)",
            icon: "🏦",
            appScheme: nil,
            notificationExample: "Plată 65,00 RON la Glovo App"
        ),
        SupportedBank(
            name: "ING România",
            icon: "🧡",
            appScheme: nil,
            notificationExample: "Ai plătit 65,00 RON la Glovo Food"
        ),
        SupportedBank(
            name: "Raiffeisen Bank",
            icon: "🦅",
            appScheme: nil,
            notificationExample: "Plată card: 65,00 RON la GLOVO"
        ),
        SupportedBank(
            name: "BCR",
            icon: "🏛",
            appScheme: nil,
            notificationExample: "Ai efectuat o plată de 65,00 RON la Glovo"
        ),
        SupportedBank(
            name: "Revolut",
            icon: "⚫️",
            appScheme: nil,
            notificationExample: "Ai plătit 65 RON lui Glovo Food"
        ),
        SupportedBank(
            name: "CEC Bank",
            icon: "🏦",
            appScheme: nil,
            notificationExample: "Tranzactie card: -65.00 RON Glovo"
        ),
    ]

    // MARK: - State

    @State private var selectedBank: SupportedBank? = nil
    @State private var currentStep: Int = 0
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: SolSpacing.lg) {

                    headerSection

                    bankListSection

                    if selectedBank != nil {
                        stepsSection
                    }

                    testSection
                }
                .padding(.horizontal, SolSpacing.screenHorizontal)
                .padding(.bottom, SolSpacing.hh)
            }
            .background(Color.solCanvas)
            .navigationTitle("Conectează banca")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Gata") { dismiss() }
                        .foregroundStyle(Color.solMint)
                }
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: SolSpacing.sm) {
            Text("Cum funcționează")
                .font(.solHeadline)
                .foregroundStyle(Color.solText)

            Text("Solomon citește notificările bancare prin iOS Shortcuts — o funcție nativă Apple. Datele nu părăsesc telefonul tău.")
                .font(.solBody)
                .foregroundStyle(Color.solTextSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: SolSpacing.md) {
                flowBubble(icon: "bell", text: "Notificare bancă")
                Image(systemName: "arrow.right")
                    .foregroundStyle(Color.solTextTertiary)
                flowBubble(icon: "app.shortcut", text: "Shortcuts")
                Image(systemName: "arrow.right")
                    .foregroundStyle(Color.solTextTertiary)
                flowBubble(icon: "chart.bar", text: "Solomon")
            }
            .padding(.top, SolSpacing.xs)
        }
        .padding(SolSpacing.md)
        .solCard()
    }

    private var bankListSection: some View {
        VStack(alignment: .leading, spacing: SolSpacing.sm) {
            Text("Selectează banca ta")
                .font(.solHeadline)
                .foregroundStyle(Color.solText)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())],
                      spacing: SolSpacing.sm) {
                ForEach(Self.banks) { bank in
                    bankChip(bank)
                }
            }
        }
    }

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: SolSpacing.sm) {
            Text("Pași de configurare")
                .font(.solHeadline)
                .foregroundStyle(Color.solText)

            VStack(spacing: 0) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    stepRow(number: index + 1, title: step.title, detail: step.detail)
                    if index < steps.count - 1 {
                        Divider()
                            .background(Color.solBorder)
                            .padding(.leading, 52)
                    }
                }
            }
            .solCard()
        }
    }

    private var testSection: some View {
        VStack(alignment: .leading, spacing: SolSpacing.sm) {
            Text("Testează conexiunea")
                .font(.solHeadline)
                .foregroundStyle(Color.solText)

            VStack(alignment: .leading, spacing: SolSpacing.sm) {
                Text("Trimite o notificare de test spre Solomon:")
                    .font(.solBody)
                    .foregroundStyle(Color.solTextSecondary)

                if let bank = selectedBank {
                    Text(bank.notificationExample)
                        .font(.solMono)
                        .foregroundStyle(Color.solMint)
                        .padding(SolSpacing.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.solElevated)
                        .clipShape(RoundedRectangle(cornerRadius: SolRadius.sm))
                }

                SolomonButton("Deschide Shortcuts", action: openShortcutsApp)
            }
            .padding(SolSpacing.md)
            .solCard()
        }
    }

    // MARK: - Subviews

    private func bankChip(_ bank: SupportedBank) -> some View {
        Button(action: { selectedBank = bank }) {
            HStack(spacing: SolSpacing.xs) {
                Text(bank.icon)
                    .font(.system(size: 20))
                Text(bank.name.components(separatedBy: " ").prefix(2).joined(separator: " "))
                    .font(.solCaption)
                    .foregroundStyle(
                        selectedBank?.id == bank.id ? Color.solCanvas : Color.solText
                    )
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, SolSpacing.sm)
            .padding(.horizontal, SolSpacing.xs)
            .background(
                selectedBank?.id == bank.id ? Color.solMint : Color.solSurface
            )
            .clipShape(RoundedRectangle(cornerRadius: SolRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: SolRadius.md)
                    .stroke(
                        selectedBank?.id == bank.id ? Color.clear : Color.solBorder,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func flowBubble(icon: String, text: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Color.solMint)
            Text(text)
                .font(.solCaption)
                .foregroundStyle(Color.solTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private func stepRow(number: Int, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: SolSpacing.md) {
            ZStack {
                Circle()
                    .fill(Color.solMint.opacity(0.15))
                    .frame(width: 32, height: 32)
                Text("\(number)")
                    .font(.solBodyBold)
                    .foregroundStyle(Color.solMint)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.solBodyBold)
                    .foregroundStyle(Color.solText)
                Text(detail)
                    .font(.solBody)
                    .foregroundStyle(Color.solTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(SolSpacing.md)
    }

    // MARK: - Steps Data

    var steps: [(title: String, detail: String)] {
        let bankName = selectedBank?.name ?? "banca ta"
        let example = selectedBank?.notificationExample ?? "Plată 65,00 RON la Magazin"

        return [
            (
                "Deschide Shortcuts",
                "Accesează aplicația Shortcuts (pre-instalată pe iPhone)"
            ),
            (
                "Automatizare nouă",
                "Apasă Automatizare → + (colț dreapta sus) → Automatizare personală"
            ),
            (
                "Trigger: Notificare",
                "Selectează «Notificare» → Aplicație: \(bankName) → Apasă OK"
            ),
            (
                "Acțiune: Deschide URL",
                "Adaugă acțiunea «Deschide URL» → URL: solomon://transaction?raw=[Conținut notificare]"
            ),
            (
                "Dezactivează confirmarea",
                "Dezactivează «Întreabă înainte de a rula» → Salvează"
            ),
            (
                "Testează",
                "Trimitți o plată de test (ex: \(example)) → Solomon o va procesa automat"
            ),
        ]
    }

    // MARK: - Actions

    private func openShortcutsApp() {
        if let url = URL(string: "shortcuts://") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Preview

#Preview {
    ShortcutSetupView()
        .preferredColorScheme(.dark)
}
