import SwiftUI
import SolomonCore
import SolomonStorage
import SolomonEmail

// MARK: - EmailParserSheet
//
// Sheet care permite userului să paste un email financiar (Glovo/Netflix/Enel/etc.)
// și să-l transforme automat într-o tranzacție folosind EmailTransactionParser.
//
// Folosit ca alternativă la Shortcuts dacă userul nu are setup-ul.
//
// VISUAL: Solomon DS (Claude Design v3 editorial premium) — MeshBackground,
// glass fields, hero card pentru preview/success, primary/secondary buttons din kit.

struct EmailParserSheet: View {

    @Environment(\.dismiss) private var dismiss

    @State private var fromEmail: String = ""
    @State private var subject: String = ""
    @State private var bodyText: String = ""
    @State private var parsed: ParsedEmailTransaction?
    @State private var saveError: String?
    @State private var saved: Bool = false

    @FocusState private var bodyFocused: Bool

    private let parser = EmailTransactionParser()

    var body: some View {
        NavigationStack {
            ZStack {
                MeshBackground()

                ScrollView {
                    VStack(spacing: SolSpacing.lg) {
                        sheetHandle
                        headerBar
                        titleBlock

                        if saved {
                            successBlock
                        } else if let parsed {
                            previewBlock(parsed)
                        } else {
                            inputForm
                        }

                        Spacer(minLength: SolSpacing.xxl)
                    }
                    .padding(.horizontal, SolSpacing.xl)
                    .padding(.top, SolSpacing.sm)
                    .padding(.bottom, SolSpacing.hh)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var sheetHandle: some View {
        Capsule()
            .fill(Color.white.opacity(0.18))
            .frame(width: 36, height: 5)
            .padding(.top, SolSpacing.sm)
            .padding(.bottom, SolSpacing.xs)
    }

    @ViewBuilder
    private var headerBar: some View {
        HStack(alignment: .center) {
            SolBackButton { dismiss() }

            Spacer()

            Text("SOLOMON · IMPORT")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.45))
                .tracking(1.4)
                .textCase(.uppercase)

            Spacer()

            Color.clear.frame(width: 38, height: 38)
        }
        .padding(.bottom, SolSpacing.sm)
    }

    @ViewBuilder
    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: SolSpacing.xs) {
            Text("Importă din email")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Color.white)
                .tracking(-0.5)
            Text("Lipește un email financiar — Solomon extrage automat tranzacția.")
                .font(.system(size: 13))
                .foregroundStyle(Color.white.opacity(0.55))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, SolSpacing.xs)
    }

    // MARK: - Input form

    @ViewBuilder
    private var inputForm: some View {
        VStack(spacing: SolSpacing.base) {
            fieldGroup(label: "DE LA (FROM)") {
                SolomonTextInput(
                    placeholder: "ex: no-reply@glovoapp.com",
                    text: $fromEmail,
                    icon: "envelope"
                )
            }

            fieldGroup(label: "SUBIECT") {
                SolomonTextInput(
                    placeholder: "ex: Comanda confirmată",
                    text: $subject,
                    icon: "text.bubble"
                )
            }

            fieldGroup(label: "CONȚINUT EMAIL") {
                ZStack(alignment: .topLeading) {
                    if bodyText.isEmpty {
                        Text("Lipește textul complet al emailului…")
                            .font(.system(size: 15))
                            .foregroundStyle(Color.white.opacity(0.35))
                            .padding(.horizontal, SolSpacing.base)
                            .padding(.vertical, 14)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $bodyText)
                        .focused($bodyFocused)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.white)
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, SolSpacing.md)
                        .padding(.vertical, SolSpacing.sm)
                        .frame(minHeight: 160)
                }
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(bodyFocused
                              ? Color.solMintExact.opacity(0.04)
                              : Color.white.opacity(0.04))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(bodyFocused
                                ? Color.solMintExact.opacity(0.4)
                                : Color.white.opacity(0.08),
                                lineWidth: 1)
                )
                .animation(.smooth(duration: 0.2), value: bodyFocused)
            }

            SolPrimaryButton("Parsează email", fullWidth: true) {
                runParse()
            }
            .opacity(canParse ? 1 : 0.4)
            .disabled(!canParse)
            .padding(.top, SolSpacing.sm)
        }
    }

    @ViewBuilder
    private func fieldGroup<Content: View>(
        label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.5))
                .tracking(0.5)
                .textCase(.uppercase)
            content()
        }
    }

    // MARK: - Preview

    @ViewBuilder
    private func previewBlock(_ p: ParsedEmailTransaction) -> some View {
        VStack(spacing: SolSpacing.lg) {
            SolHeroCard(
                accent: .mint,
                content: {
                    VStack(alignment: .leading, spacing: 6) {
                        SolHeroLabel(p.merchant ?? "TRANZACȚIE")
                        if let amount = p.amount {
                            let split = splitAmount(amount.value)
                            SolHeroAmount(
                                amount: split.whole,
                                decimals: split.decimals,
                                currency: amount.currency.rawValue.uppercased(),
                                accent: .mint
                            )
                        } else {
                            Text("Sumă indisponibilă")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(Color.white.opacity(0.7))
                        }
                        Text(p.suggestedCategory.displayNameRO)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.white.opacity(0.55))
                            .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                },
                badge: { SolHeroBadge("PARSED", accent: .mint) }
            )

            HStack(spacing: SolSpacing.xs) {
                SolChip(
                    "Confidență \(Int(p.confidence * 100))%",
                    kind: confidenceChipKind(p.confidence)
                )
                Spacer()
            }

            if let err = saveError {
                SolInsightCard(
                    icon: "exclamationmark.triangle.fill",
                    label: "EROARE",
                    accent: .rose,
                    content: {
                        Text(err)
                            .font(.system(size: 14))
                            .foregroundStyle(Color.white.opacity(0.85))
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                )
            }

            HStack(spacing: SolSpacing.sm) {
                SolSecondaryButton("Înapoi", fullWidth: true) {
                    parsed = nil
                    saveError = nil
                }
                SolPrimaryButton("Salvează", fullWidth: true) {
                    saveTransaction(p)
                }
                .opacity(p.amount == nil ? 0.4 : 1)
                .disabled(p.amount == nil)
            }
        }
    }

    // MARK: - Success

    @ViewBuilder
    private var successBlock: some View {
        VStack(spacing: SolSpacing.lg) {
            SolHeroCard(
                accent: .mint,
                content: {
                    VStack(alignment: .leading, spacing: SolSpacing.sm) {
                        SolHeroLabel("CONFIRMARE")
                        Text("Tranzacția a fost adăugată.")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Color.white)
                            .tracking(-0.4)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("O găsești în portofel sau în Recent Activity.")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.white.opacity(0.55))
                            .padding(.top, 2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                },
                badge: { SolHeroBadge("SALVAT ✓", accent: .mint) }
            )

            HStack(spacing: SolSpacing.sm) {
                SolSecondaryButton("Mai parsez unul", fullWidth: true) {
                    reset()
                }
                SolPrimaryButton("Gata", fullWidth: true) {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Logic (UNCHANGED)

    private var canParse: Bool {
        !fromEmail.trimmingCharacters(in: .whitespaces).isEmpty &&
        !subject.trimmingCharacters(in: .whitespaces).isEmpty &&
        !bodyText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func runParse() {
        let email = EmailMessage(
            from: fromEmail,
            subject: subject,
            bodyText: bodyText,
            date: Date()
        )
        parsed = parser.parse(email)
    }

    private func saveTransaction(_ p: ParsedEmailTransaction) {
        guard let amount = p.amount else {
            saveError = "Nu s-a putut extrage o sumă din email."
            return
        }
        // FIX 2: refuză sumele non-RON (înainte: fallback "ron-treat" care saluta 50 EUR
        // ca 50 RON în Safe-to-Spend). v2 va aduce conversie FX cu rate live.
        guard let moneyAmount = amount.moneyRON else {
            saveError = "Tranzacțiile în \(amount.currency.rawValue.uppercased()) nu sunt încă suportate. Solomon procesează doar RON momentan."
            return
        }
        // FIX 2: folosim direction-ul parsat de SolomonEmail (corect: Credius email
        // = .incoming pentru aprobare credit), NU forțăm .outgoing.
        let tx = Transaction(
            id: deterministicEmailTxId(parsed: p),
            date: p.date,
            amount: moneyAmount,
            direction: p.direction,
            category: p.suggestedCategory,
            merchant: p.merchant,
            description: "[\(amount.currency.rawValue.uppercased())] \(p.subject)",
            source: .emailParsed,
            categorizationConfidence: p.confidence
        )
        do {
            let ctx = SolomonPersistenceController.shared.container.viewContext
            let repo = CoreDataTransactionRepository(context: ctx)
            try repo.upsert(tx)
            saved = true
        } catch {
            saveError = error.localizedDescription
        }
    }

    /// FIX 2 (bonus dedup): ID deterministic dintr-un email — same email parsat de 2 ori
    /// produce același UUID → upsert detectează duplicatul. Cheie: from + subject + date.
    private func deterministicEmailTxId(parsed p: ParsedEmailTransaction) -> UUID {
        let bucket = Int(p.date.timeIntervalSince1970 / 60.0)
        let key = "email|\(p.from)|\(p.subject)|\(bucket)"
        return UUID.deterministic(from: key)
    }

    private func reset() {
        fromEmail = ""
        subject = ""
        bodyText = ""
        parsed = nil
        saved = false
        saveError = nil
    }

    private func confidenceChipKind(_ c: Double) -> SolChip.Kind {
        if c >= 0.8 { return .mint }
        if c >= 0.5 { return .warn }
        return .rose
    }

    /// Format Int sumă → ("1 234", nil). Spaces ca grouping separator.
    private func splitAmount(_ value: Int) -> (whole: String, decimals: String?) {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.maximumFractionDigits = 0
        let s = formatter.string(from: NSNumber(value: value)) ?? String(value)
        return (s, nil)
    }
}
