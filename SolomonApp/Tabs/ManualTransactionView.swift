import SwiftUI
import SolomonCore
import SolomonStorage

// MARK: - ManualTransactionView
//
// Formular de intrare manuală a unei tranzacții.
// Folosit când userul vrea să adauge o cheltuială cash sau una pe care
// nu o prinde Shortcuts (ex: cumpărări la piață cu numerar).
//
// Layout:
//  • Sumă mare (pad numeric custom)
//  • Switch direction (cheltuiala / venit)
//  • Câmp merchant
//  • Picker categorie
//  • Date picker
//  • Buton „Adaugă" → TransactionRepository.upsert

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

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.solCanvas.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: SolSpacing.xl) {

                        amountDisplay

                        directionToggle

                        formFields

                        if let saveError {
                            Text(saveError)
                                .font(.solCaption)
                                .foregroundStyle(Color.solDanger)
                                .padding(.horizontal, SolSpacing.screenHorizontal)
                        }

                        SolomonButton(
                            saveButtonTitle,
                            isLoading: isSaving,
                            action: save
                        )
                        .padding(.horizontal, SolSpacing.screenHorizontal)
                        .disabled(amountValue == 0 || isSaving)
                        .opacity((amountValue == 0 || isSaving) ? 0.5 : 1)
                    }
                    .padding(.top, SolSpacing.lg)
                    .padding(.bottom, SolSpacing.hh)
                }
            }
            .navigationTitle("Tranzacție nouă")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Anulează") { dismiss() }
                        .foregroundStyle(Color.solTextSecondary)
                }
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var amountDisplay: some View {
        VStack(spacing: SolSpacing.xs) {
            HStack(alignment: .firstTextBaseline, spacing: SolSpacing.xs) {
                Text(direction == .outgoing ? "−" : "+")
                    .font(.solDisplayLG)
                    .foregroundStyle(direction == .outgoing ? Color.solDanger : Color.solMint)
                Text(amountText)
                    .font(.solDisplayLG)
                    .foregroundStyle(direction == .outgoing ? Color.solDanger : Color.solMint)
                    .monospacedDigit()
                Text("RON")
                    .font(.solHeadingMD)
                    .foregroundStyle(Color.solTextMuted)
            }

            // Custom number pad
            numberPad
                .padding(.top, SolSpacing.md)
        }
        .padding(.horizontal, SolSpacing.screenHorizontal)
    }

    @ViewBuilder
    private var numberPad: some View {
        let rows: [[String]] = [
            ["1", "2", "3"],
            ["4", "5", "6"],
            ["7", "8", "9"],
            ["", "0", "⌫"]
        ]
        VStack(spacing: SolSpacing.sm) {
            ForEach(0..<rows.count, id: \.self) { rowIndex in
                HStack(spacing: SolSpacing.sm) {
                    ForEach(rows[rowIndex], id: \.self) { key in
                        padKey(key)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func padKey(_ key: String) -> some View {
        Button {
            tapKey(key)
        } label: {
            Group {
                if key == "⌫" {
                    Image(systemName: "delete.left")
                        .font(.system(size: 22, weight: .medium))
                } else if !key.isEmpty {
                    Text(key)
                        .font(.system(size: 28, weight: .medium))
                } else {
                    Color.clear
                }
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            .foregroundStyle(Color.solTextPrimary)
            .background(key.isEmpty ? Color.clear : Color.solSurface)
            .clipShape(RoundedRectangle(cornerRadius: SolRadius.md, style: .continuous))
        }
        .disabled(key.isEmpty)
    }

    @ViewBuilder
    private var directionToggle: some View {
        HStack(spacing: 0) {
            directionTab(.outgoing, label: "Cheltuială", icon: "arrow.up.right")
            directionTab(.incoming, label: "Venit", icon: "arrow.down.left")
        }
        .padding(SolSpacing.xs)
        .background(Color.solSurface)
        .clipShape(RoundedRectangle(cornerRadius: SolRadius.md, style: .continuous))
        .padding(.horizontal, SolSpacing.screenHorizontal)
    }

    @ViewBuilder
    private func directionTab(_ value: FlowDirection, label: String, icon: String) -> some View {
        let isSelected = direction == value
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                direction = value
            }
        } label: {
            HStack(spacing: SolSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                Text(label)
                    .font(.solBodyBold)
            }
            .foregroundStyle(
                isSelected
                    ? (value == .outgoing ? Color.solCanvas : Color.solCanvas)
                    : Color.solTextSecondary
            )
            .frame(maxWidth: .infinity, minHeight: 40)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: SolRadius.sm)
                            .fill(value == .outgoing ? Color.solDanger : Color.solMint)
                    }
                }
            )
        }
    }

    @ViewBuilder
    private var formFields: some View {
        VStack(spacing: SolSpacing.sm) {
            // Merchant
            HStack {
                Image(systemName: "storefront")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.solTextSecondary)
                    .frame(width: 24)
                TextField("Unde? (ex: Glovo, Kaufland)", text: $merchant)
                    .font(.solBodyLG)
                    .foregroundStyle(Color.solTextPrimary)
                    .onChange(of: merchant) { _, newValue in
                        // Auto-categorizare în timp real
                        let detected = MerchantCategoryMatcher.category(for: newValue)
                        if detected != .unknown {
                            category = detected
                        }
                    }
            }
            .padding(SolSpacing.md)
            .solCard()

            // Categorie
            HStack {
                Image(systemName: "tag")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.solTextSecondary)
                    .frame(width: 24)
                Picker("Categorie", selection: $category) {
                    ForEach(TransactionCategory.allCases, id: \.self) { cat in
                        Text(cat.displayNameRO)
                            .tag(cat)
                    }
                }
                .pickerStyle(.menu)
                .tint(Color.solMint)
                Spacer()
            }
            .padding(SolSpacing.md)
            .solCard()

            // Date
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.solTextSecondary)
                    .frame(width: 24)
                DatePicker("Data", selection: $date, displayedComponents: [.date])
                    .datePickerStyle(.compact)
                    .tint(Color.solMint)
            }
            .padding(SolSpacing.md)
            .solCard()
        }
        .padding(.horizontal, SolSpacing.screenHorizontal)
    }

    // MARK: - Computed

    private var amountValue: Int {
        Int(amountText) ?? 0
    }

    private var saveButtonTitle: String {
        direction == .outgoing ? "Adaugă cheltuială" : "Adaugă venit"
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

        let tx = Transaction(
            id: UUID(),
            date: date,
            amount: Money(amountValue),
            direction: direction,
            category: category,
            merchant: merchant.trimmingCharacters(in: .whitespaces).isEmpty ? nil : merchant,
            description: nil,
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
