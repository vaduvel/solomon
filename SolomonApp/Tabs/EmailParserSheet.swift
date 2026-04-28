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

struct EmailParserSheet: View {

    @Environment(\.dismiss) private var dismiss

    @State private var fromEmail: String = ""
    @State private var subject: String = ""
    @State private var bodyText: String = ""
    @State private var parsed: ParsedEmailTransaction?
    @State private var saveError: String?
    @State private var saved: Bool = false

    private let parser = EmailTransactionParser()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.solCanvas.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: SolSpacing.lg) {

                        if saved {
                            successCard
                        } else if let parsed {
                            previewCard(parsed)
                        } else {
                            inputForm
                        }

                        Spacer()
                    }
                    .padding(.horizontal, SolSpacing.screenHorizontal)
                    .padding(.top, SolSpacing.lg)
                    .padding(.bottom, SolSpacing.hh)
                }
            }
            .navigationTitle("Importă din email")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Închide") { dismiss() }
                        .foregroundStyle(Color.solMuted)
                }
            }
        }
    }

    // MARK: - Input form

    @ViewBuilder
    private var inputForm: some View {
        VStack(spacing: SolSpacing.md) {
            VStack(alignment: .leading, spacing: SolSpacing.xs) {
                Text("DE LA (FROM)")
                    .font(.solMicro)
                    .foregroundStyle(Color.solMuted)
                    .tracking(1.2)
                SolomonTextInput(
                    placeholder: "ex: no-reply@glovoapp.com",
                    text: $fromEmail,
                    icon: "envelope"
                )
            }

            VStack(alignment: .leading, spacing: SolSpacing.xs) {
                Text("SUBIECT")
                    .font(.solMicro)
                    .foregroundStyle(Color.solMuted)
                    .tracking(1.2)
                SolomonTextInput(
                    placeholder: "ex: Comanda confirmată",
                    text: $subject,
                    icon: "text.bubble"
                )
            }

            VStack(alignment: .leading, spacing: SolSpacing.xs) {
                Text("CONȚINUT EMAIL")
                    .font(.solMicro)
                    .foregroundStyle(Color.solMuted)
                    .tracking(1.2)
                TextEditor(text: $bodyText)
                    .font(.solBody)
                    .foregroundStyle(Color.solForeground)
                    .scrollContentBackground(.hidden)
                    .padding(SolSpacing.md)
                    .frame(minHeight: 160)
                    .background(Color.solCard)
                    .clipShape(RoundedRectangle(cornerRadius: SolRadius.xl))
                    .overlay(
                        RoundedRectangle(cornerRadius: SolRadius.xl)
                            .stroke(Color.solBorder, lineWidth: 1)
                    )
            }

            SolomonButton("Parseaza email", icon: "arrow.right") {
                runParse()
            }
            .opacity(canParse ? 1 : 0.4)
            .disabled(!canParse)
        }
    }

    @ViewBuilder
    private func previewCard(_ p: ParsedEmailTransaction) -> some View {
        VStack(alignment: .leading, spacing: SolSpacing.md) {
            Text("PREVIEW TRANZACȚIE")
                .font(.solMicro)
                .foregroundStyle(Color.solMuted)
                .tracking(1.2)

            HStack(spacing: SolSpacing.md) {
                IconContainer(systemName: "checkmark.circle.fill", variant: .neon, size: 44, iconSize: 18)
                VStack(alignment: .leading, spacing: 2) {
                    Text(p.merchant ?? "Tranzacție")
                        .font(.solH3)
                        .foregroundStyle(Color.solForeground)
                    Text(p.suggestedCategory.displayNameRO)
                        .font(.solCaption)
                        .foregroundStyle(Color.solMuted)
                }
                Spacer()
                if let amount = p.amount {
                    Text("\(amount.value) \(amount.currency.rawValue.uppercased())")
                        .font(.solMonoMD)
                        .foregroundStyle(Color.solDestructive)
                }
            }
            .padding(SolSpacing.base)
            .solCard()

            HStack(spacing: SolSpacing.xs) {
                StatusBadge(title: "Confidență \(Int(p.confidence * 100))%", kind: confidenceKind(p.confidence))
                Spacer()
            }

            if let err = saveError {
                Text(err)
                    .font(.solCaption)
                    .foregroundStyle(Color.solDestructive)
            }

            HStack(spacing: SolSpacing.sm) {
                SolomonButton("Înapoi", style: .secondary) {
                    parsed = nil
                }
                SolomonButton("Salvează", icon: "checkmark") {
                    saveTransaction(p)
                }
                .disabled(p.amount == nil)
                .opacity(p.amount == nil ? 0.4 : 1)
            }
        }
        .padding(SolSpacing.cardStandard)
        .solCard()
    }

    @ViewBuilder
    private var successCard: some View {
        VStack(spacing: SolSpacing.lg) {
            IconContainer(systemName: "checkmark.circle.fill", variant: .neon, size: 80, iconSize: 36)
            Text("Salvat ✓")
                .font(.solH1)
                .foregroundStyle(Color.solPrimary)
            Text("Tranzacția a fost adăugată în portofel.")
                .font(.solBody)
                .foregroundStyle(Color.solMuted)
            HStack(spacing: SolSpacing.sm) {
                SolomonButton("Mai parsez unul", style: .secondary) {
                    reset()
                }
                SolomonButton("Gata") { dismiss() }
            }
        }
        .padding(SolSpacing.cardHero)
        .solCard()
    }

    // MARK: - Logic

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
        let moneyAmount = amount.moneyRON ?? Money(amount.value)  // fallback ron-treat
        let tx = Transaction(
            id: UUID(),
            date: p.date,
            amount: moneyAmount,
            direction: .outgoing,
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

    private func reset() {
        fromEmail = ""
        subject = ""
        bodyText = ""
        parsed = nil
        saved = false
        saveError = nil
    }

    private func confidenceKind(_ c: Double) -> StatusBadge.Kind {
        if c >= 0.8 { return .success }
        if c >= 0.5 { return .warning }
        return .danger
    }
}
