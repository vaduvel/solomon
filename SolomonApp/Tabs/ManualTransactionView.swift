import SwiftUI
import SolomonCore
import SolomonStorage

// MARK: - ManualTransactionView (Claude Design v3 — premium iOS 26)
//
// Redesign 1:1 cu Solomon DS:
//   - `screens/can-i-afford.html` (numpad + display sumă mare)
//   - `screens/sub-edit.html` (sheet handle + form fields glass + pills row)
//
// Layout:
//   - MeshBackground (mint/blue/violet)
//   - Sheet handle + appbar: SolBackButton + brand "SOLOMON · TRANZACȚIE" + "Adaugă manual"
//   - Amount display: număr mare gradient + "RON" + ctx (categorie auto-detected sau merchant)
//   - Direction pills (cheltuială / venit) cu SolPill
//   - Form fields glass: descriere, categorie (pills H), data, merchant
//   - Eroare în SolInsightCard.rose dacă există
//   - SolPrimaryButton "Salvează" + SolSecondaryButton "Renunță"
//
// Business logic păstrat integral:
//   - amountText / direction / merchant / category / date / description
//   - tapKey numpad + auto-categorizare via MerchantCategoryMatcher
//   - save() construiește Transaction + CoreDataTransactionRepository.upsert
//   - dismiss flow + saveError handling

struct ManualTransactionView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var moc

    // MARK: - Form state

    @State private var amountText: String = "0"
    @State private var direction: FlowDirection = .outgoing
    @State private var merchant: String = ""
    @State private var category: TransactionCategory = .unknown
    @State private var date: Date = Date()
    @State private var description: String = ""

    @State private var saveError: String?
    @State private var isSaving = false
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case description, merchant
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            MeshBackground()

            ScrollView {
                VStack(spacing: SolSpacing.md) {
                    sheetHandle
                    appBar
                    amountDisplay
                    numberPad
                    directionPills
                    descriptionField
                    categoryField
                    dateField
                    merchantField

                    if let saveError {
                        SolInsightCard(
                            icon: "exclamationmark.triangle.fill",
                            label: "EROARE",
                            timestamp: nil,
                            accent: .rose
                        ) {
                            Text(saveError)
                                .font(.system(size: 14))
                                .foregroundStyle(Color.white.opacity(0.85))
                                .lineSpacing(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    SolPrimaryButton(
                        saveButtonTitle,
                        accent: direction == .outgoing ? .mint : .mint,
                        fullWidth: true
                    ) {
                        save()
                    }
                    .opacity((amountValue == 0 || isSaving) ? 0.4 : 1)
                    .disabled(amountValue == 0 || isSaving)

                    SolSecondaryButton("Renunță", fullWidth: true) {
                        dismiss()
                    }
                }
                .padding(.horizontal, SolSpacing.screenHorizontal)
                .padding(.bottom, SolSpacing.hh)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Sub-views

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

    private var appBar: some View {
        HStack(alignment: .center, spacing: 12) {
            SolBackButton { dismiss() }

            VStack(spacing: 4) {
                Text("SOLOMON · TRANZACȚIE")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.45))
                    .tracking(1.4)
                    .textCase(.uppercase)
                Text("Adaugă manual")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .tracking(-0.4)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)

            Color.clear.frame(width: 38, height: 38)
        }
        .padding(.bottom, SolSpacing.md)
    }

    // MARK: Amount display (gradient — can-i-afford pattern)

    private var amountDisplay: some View {
        VStack(spacing: 4) {
            Text(direction == .outgoing ? "CHELTUIALĂ" : "VENIT")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.4))
                .tracking(0.5)
                .textCase(.uppercase)

            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(direction == .outgoing ? "−" : "+")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(amountAccent.color.opacity(0.7))
                    .tracking(-1.5)
                    .padding(.trailing, 4)

                Text(formattedAmount)
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .tracking(-2)
                    .monospacedDigit()
                    .shadow(color: amountAccent.color.opacity(0.18), radius: 30)

                Text("RON")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.4))
                    .padding(.leading, 6)
            }

            Text(amountContext)
                .font(.system(size: 13))
                .foregroundStyle(Color.white.opacity(0.55))
                .padding(.top, 4)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: Numpad

    private var numberPad: some View {
        let rows: [[String]] = [
            ["1", "2", "3"],
            ["4", "5", "6"],
            ["7", "8", "9"],
            ["", "0", "⌫"]
        ]
        return VStack(spacing: 8) {
            ForEach(0..<rows.count, id: \.self) { rowIndex in
                HStack(spacing: 8) {
                    ForEach(rows[rowIndex], id: \.self) { key in
                        padKey(key)
                    }
                }
            }
        }
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private func padKey(_ key: String) -> some View {
        Button {
            tapKey(key)
        } label: {
            ZStack {
                if !key.isEmpty {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                }
                Group {
                    if key == "⌫" {
                        Image(systemName: "delete.left")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.85))
                    } else if !key.isEmpty {
                        Text(key)
                            .font(.system(size: 26, weight: .medium))
                            .foregroundStyle(Color.white)
                            .monospacedDigit()
                    } else {
                        Color.clear
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 56)
        }
        .buttonStyle(.plain)
        .disabled(key.isEmpty)
    }

    // MARK: Direction pills

    private var directionPills: some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel("DIRECȚIE")
            HStack(spacing: 6) {
                SolPill("Cheltuială", isActive: direction == .outgoing) {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        direction = .outgoing
                    }
                }
                SolPill("Venit", isActive: direction == .incoming) {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        direction = .incoming
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .padding(.bottom, 4)
    }

    // MARK: Field — Descriere

    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel("DESCRIERE")
            glassInput(isFocused: focusedField == .description) {
                TextField("ex: cumpărături piață", text: $description)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.white)
                    .focused($focusedField, equals: .description)
            }
        }
        .padding(.bottom, 4)
    }

    // MARK: Field — Categorie (pills H scroll)

    private var categoryField: some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel("CATEGORIE")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(TransactionCategory.allCases, id: \.self) { cat in
                        SolPill(cat.displayNameRO, isActive: category == cat) {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                category = cat
                            }
                        }
                    }
                }
                .padding(.vertical, 2)
                .padding(.horizontal, 1)
            }
        }
        .padding(.bottom, 4)
    }

    // MARK: Field — Data

    private var dateField: some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel("DATĂ")
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                HStack {
                    DatePicker("", selection: $date, displayedComponents: .date)
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .tint(Color.solMintExact)
                        .colorScheme(.dark)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 12)
            }
            .frame(height: 50)
        }
        .padding(.bottom, 4)
    }

    // MARK: Field — Merchant (opțional)

    private var merchantField: some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel("MERCHANT (OPȚIONAL)")
            glassInput(isFocused: focusedField == .merchant) {
                TextField("ex: Glovo, Kaufland", text: $merchant)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.white)
                    .focused($focusedField, equals: .merchant)
                    .onChange(of: merchant) { _, newValue in
                        // Auto-categorizare în timp real (păstrat din versiunea originală)
                        let detected = MerchantCategoryMatcher.category(for: newValue)
                        if detected != .unknown {
                            category = detected
                        }
                    }
            }
        }
        .padding(.bottom, 4)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(Color.white.opacity(0.5))
            .tracking(0.5)
            .textCase(.uppercase)
    }

    @ViewBuilder
    private func glassInput<C: View>(isFocused: Bool, @ViewBuilder content: () -> C) -> some View {
        HStack {
            content()
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isFocused ? Color.solMintExact.opacity(0.04) : Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    isFocused ? Color.solMintExact.opacity(0.4) : Color.white.opacity(0.08),
                    lineWidth: 1
                )
        )
        .animation(.easeInOut(duration: 0.18), value: isFocused)
    }

    // MARK: - Computed

    private var amountValue: Int {
        Int(amountText) ?? 0
    }

    private var formattedAmount: String {
        // Formatare cu separator pentru mii (5499 -> 5.499)
        guard let n = Int(amountText), n > 0 else { return "0" }
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = "."
        f.locale = Locale(identifier: "ro_RO")
        return f.string(from: NSNumber(value: n)) ?? amountText
    }

    private var amountAccent: SolAccent {
        direction == .outgoing ? .rose : .mint
    }

    private var amountContext: String {
        let trimmedMerchant = merchant.trimmingCharacters(in: .whitespaces)
        if !trimmedMerchant.isEmpty {
            return "\(category.displayNameRO) · \(trimmedMerchant)"
        }
        if category != .unknown {
            return category.displayNameRO
        }
        return direction == .outgoing ? "cheltuială manuală" : "venit manual"
    }

    private var saveButtonTitle: String {
        if isSaving { return "Se salvează…" }
        return direction == .outgoing ? "Salvează cheltuiala" : "Salvează venitul"
    }

    // MARK: - Actions

    private func tapKey(_ key: String) {
        switch key {
        case "⌫":
            if amountText.count <= 1 {
                amountText = "0"
            } else {
                amountText.removeLast()
            }
        default:
            if amountText == "0" {
                amountText = key
            } else if amountText.count < 9 {  // limit 9 digits
                amountText.append(key)
            }
        }
    }

    private func save() {
        guard amountValue > 0 else { return }
        isSaving = true
        saveError = nil

        let trimmedMerchant = merchant.trimmingCharacters(in: .whitespaces)
        let trimmedDescription = description.trimmingCharacters(in: .whitespaces)

        let tx = Transaction(
            id: UUID(),
            date: date,
            amount: Money(amountValue),
            direction: direction,
            category: category,
            merchant: trimmedMerchant.isEmpty ? nil : trimmedMerchant,
            description: trimmedDescription.isEmpty ? nil : trimmedDescription,
            source: .manualEntry,
            categorizationConfidence: 1.0  // user-set, max confidence
        )

        do {
            let repo = CoreDataTransactionRepository(context: moc)
            try repo.upsert(tx)
            isSaving = false
            dismiss()
        } catch {
            saveError = "Nu am putut salva: \(error.localizedDescription)"
            isSaving = false
        }
    }
}

// MARK: - Preview

#Preview {
    ManualTransactionView()
        .preferredColorScheme(.dark)
}
