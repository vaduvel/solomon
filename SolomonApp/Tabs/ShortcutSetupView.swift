import SwiftUI

// MARK: - ShortcutSetupView
//
// Ghid pas-cu-pas pentru conectarea băncilor via iOS Shortcuts.
// Userul creează o automatizare care trimite notificările bancare
// la Solomon prin URL scheme `solomon://transaction?raw=...`
//
// Accesibil din: Settings → Conectează banca
//
// Redesenat 1:1 cu Solomon DS (Claude Design): MeshBackground, SolHeroCard,
// SolInsightCard, SolListCard cu pași numerotați, SolPrimaryButton.

struct ShortcutSetupView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Steps Data

    private struct SetupStep: Identifiable {
        let id = UUID()
        let title: String
        let detail: String
        let icon: String
    }

    private let steps: [SetupStep] = [
        SetupStep(
            title: "Deschide Shortcuts",
            detail: "Lansează aplicația Shortcuts (pre-instalată pe iPhone).",
            icon: "app.badge"
        ),
        SetupStep(
            title: "Apasă „+\" creează shortcut nou",
            detail: "În tab-ul Automation, apasă „+\" și alege Personal Automation.",
            icon: "plus.square.on.square"
        ),
        SetupStep(
            title: "Adaugă acțiunea „When notification\"",
            detail: "Selectează trigger-ul „Notification\" și alege aplicația băncii.",
            icon: "bell.badge"
        ),
        SetupStep(
            title: "Wire-uire la Solomon",
            detail: "Adaugă „Open URL\" cu solomon://transaction?raw=[Notification Content].",
            icon: "link"
        )
    ]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                MeshBackground(
                    topLeftAccent: .mint,
                    midRightAccent: .blue,
                    bottomLeftAccent: .violet
                )

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: SolSpacing.base) {

                        sheetHandle
                        headerBar
                        heroSection
                        whyInsight
                        stepsHeader
                        stepsList
                        ctaButtons
                    }
                    .padding(.horizontal, SolSpacing.screenHorizontal)
                    .padding(.bottom, SolSpacing.hh)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: - Sections

    private var sheetHandle: some View {
        HStack {
            Spacer()
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Color.white.opacity(0.18))
                .frame(width: 36, height: 5)
            Spacer()
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var headerBar: some View {
        HStack(alignment: .center, spacing: 12) {
            SolBackButton { dismiss() }

            VStack(alignment: .center, spacing: 4) {
                Text("SOLOMON · SHORTCUTS")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.solMintExact)
                    .tracking(1.4)
                    .textCase(.uppercase)
                Text("Conectează banca prin Shortcut")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .tracking(-0.4)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)

            // Spacer pentru a echilibra back-ul (lățime 38)
            Color.clear.frame(width: 38, height: 38)
        }
        .padding(.bottom, SolSpacing.sm)
    }

    private var heroSection: some View {
        SolHeroCard(accent: .blue) {
            VStack(alignment: .leading, spacing: 6) {
                SolHeroLabel("AUTOMATIZARE NATIVĂ · IOS")

                Text("Ascult automat")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .tracking(-0.6)
                    .padding(.top, 4)

                Text("Solomon ascultă notificările bancare automat — fără să mai introduci nimic manual.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.white.opacity(0.7))
                    .lineSpacing(2)
                    .padding(.top, 6)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } badge: {
            SolHeroBadge("AUTOMATIZARE", accent: .blue)
        }
    }

    private var whyInsight: some View {
        SolInsightCard(
            icon: "lock.shield",
            label: "DE CE?",
            timestamp: "100% local",
            accent: .blue
        ) {
            whyInsightAttributedText
                .font(.system(size: 14))
                .lineSpacing(2)
        }
    }

    private var stepsHeader: some View {
        SolSectionHeaderRow("PAȘII", meta: "\(steps.count) pași · 2 minute")
            .padding(.top, SolSpacing.sm)
    }

    private var whyInsightAttributedText: Text {
        var attr = AttributedString("Notificările tale nu părăsesc telefonul. iOS Shortcuts e o funcție nativă Apple — Solomon doar primește textul prin URL scheme și îl procesează ")
        attr.foregroundColor = .white.opacity(0.85)
        var local = AttributedString("local")
        local.foregroundColor = .solBlueExact
        local.font = .system(size: 14, weight: .medium)
        attr += local
        var rest = AttributedString(", on-device. Nimic în cloud.")
        rest.foregroundColor = .white.opacity(0.85)
        attr += rest
        return Text(attr)
    }

    private var stepsList: some View {
        SolListCard {
            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                stepRow(number: index + 1, step: step)
                if index < steps.count - 1 {
                    SolHairlineDivider()
                }
            }
        }
    }

    private var ctaButtons: some View {
        VStack(spacing: SolSpacing.sm) {
            SolPrimaryButton(
                "Deschide Shortcuts",
                accent: .mint,
                fullWidth: true,
                action: openShortcutsApp
            )
            .overlay(alignment: .trailing) {
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(red: 0x05/255, green: 0x2E/255, blue: 0x16/255))
                    .padding(.trailing, 18)
                    .allowsHitTesting(false)
            }

            SolSecondaryButton("Mai târziu", fullWidth: true) {
                dismiss()
            }
        }
        .padding(.top, SolSpacing.sm)
    }

    // MARK: - Subviews

    private func stepRow(number: Int, step: SetupStep) -> some View {
        HStack(alignment: .top, spacing: 14) {
            // Număr mare mint (recover-step pattern din spiral.html)
            Text("\(number)")
                .font(.system(size: 28, weight: .semibold, design: .default))
                .foregroundStyle(Color.solMintExact)
                .tracking(-0.8)
                .monospacedDigit()
                .frame(width: 32, alignment: .leading)
                .shadow(color: Color.solMintExact.opacity(0.3), radius: 8)

            VStack(alignment: .leading, spacing: 3) {
                Text(step.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.white)
                    .fixedSize(horizontal: false, vertical: true)

                Text(step.detail)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.5))
                    .lineSpacing(1.5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Icon ilustrativ pe dreapta
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(SolAccent.mint.iconGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.solMintExact.opacity(0.25), lineWidth: 1)
                    )
                Image(systemName: step.icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.solMintExact)
            }
            .frame(width: 32, height: 32)
            .shadow(color: Color.solMintExact.opacity(0.15), radius: 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Actions (business logic preserved)

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
