import SwiftUI
import SolomonCore
import SolomonStorage

// MARK: - SubscriptionEditView (Claude Design v3 — sub-edit.html 1:1)
//
// Editare/creare abonament: sheet handle + back + brand logo selector +
// glass form fields + insight utilizare + save / cancel.
// Validări: name nu e gol, amount > 0.

struct SubscriptionEditView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var moc

    // MARK: - Init

    let editingSubscription: Subscription?

    init(editingSubscription: Subscription? = nil) {
        self.editingSubscription = editingSubscription
    }

    // MARK: - Form state

    @State private var name: String = ""
    @State private var amountText: String = "0"
    @State private var paymentDay: String = "1"
    @State private var frequency: Frequency = .monthly
    @State private var cancellationDifficulty: CancellationDifficulty = .medium
    @State private var selectedBrand: BrandChoice = .netflix

    @State private var saveError: String?
    @State private var showDeleteConfirmation = false

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            MeshBackground(
                topLeftAccent: .rose,
                midRightAccent: .blue,
                bottomLeftAccent: .violet
            )

            ScrollView {
                VStack(spacing: 0) {

                    // Sheet handle
                    sheetHandle
                        .padding(.top, SolSpacing.sm)
                        .padding(.bottom, SolSpacing.xs)

                    // Back + title row
                    headerBar
                        .padding(.bottom, 18)

                    // Hero — utilizare / decision banner (placeholder)
                    SolHeroCard(
                        accent: .rose,
                        content: { heroContent },
                        badge: { SolHeroBadge("SOLOMON SUGEREAZĂ", accent: .rose) }
                    )
                    .padding(.bottom, 14)

                    // Brand logo selector (horizontal pills cu logos)
                    brandSelector
                        .padding(.bottom, SolSpacing.base)

                    // Form fields
                    nameField.padding(.bottom, 14)

                    HStack(spacing: 10) {
                        amountField
                        frequencyField
                    }
                    .padding(.bottom, 14)

                    paymentDayField.padding(.bottom, 14)

                    categoryField.padding(.bottom, SolSpacing.base)

                    // Insight (mint) — usage placeholder
                    usageInsight
                        .padding(.bottom, SolSpacing.base)

                    // Save error
                    if let saveError {
                        Text(saveError)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.solRoseExact)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, SolSpacing.sm)
                    }

                    // Save button (rose în edit mode = "Anulează abonamentul"
                    // mint în create mode = "Adaugă abonament")
                    SolPrimaryButton(
                        editingSubscription == nil ? "Adaugă abonament" : "Salvează modificările",
                        accent: .mint,
                        fullWidth: true
                    ) {
                        save()
                    }
                    .opacity(isFormValid ? 1 : 0.4)
                    .disabled(!isFormValid)
                    .padding(.bottom, 10)

                    // Secondary: Renunță / Șterge
                    if editingSubscription != nil {
                        SolSecondaryButton("Șterge abonamentul", fullWidth: true) {
                            Haptics.warning()
                            showDeleteConfirmation = true
                        }
                        .padding(.bottom, 10)
                    }

                    SolSecondaryButton("Renunță", fullWidth: true) {
                        dismiss()
                    }
                    .padding(.bottom, SolSpacing.xxl)
                }
                .padding(.horizontal, SolSpacing.xl)
            }
        }
        .preferredColorScheme(.dark)
        .confirmationDialog(
            "Șterge abonamentul?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Șterge abonamentul", role: .destructive) {
                deleteSubscription()
            }
            Button("Anulează", role: .cancel) {}
        } message: {
            Text("Nu se poate recupera.")
        }
        .onAppear { loadIfEditing() }
    }

    // MARK: - Sheet handle

    private var sheetHandle: some View {
        Capsule()
            .fill(Color.white.opacity(0.18))
            .frame(width: 36, height: 5)
            .frame(maxWidth: .infinity)
    }

    // MARK: - Header bar

    private var headerBar: some View {
        HStack(spacing: 12) {
            SolBackButton { dismiss() }

            Spacer(minLength: 0)

            HStack(spacing: 10) {
                SolBrandLogo(selectedBrand.logoBrand, size: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(editingSubscription == nil ? "ADAUGĂ" : "EDITARE")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.45))
                        .tracking(1.4)
                    Text(name.isEmpty ? selectedBrand.displayName : name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .tracking(-0.4)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            // Spacer same width as back button to balance layout
            Color.clear.frame(width: 38, height: 38)
        }
    }

    // MARK: - Hero

    private var heroContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            SolHeroLabel("UTILIZARE · ULTIMELE 3 LUNI")
                .padding(.bottom, 6)

            Text(heroHeadline)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color.white)
                .tracking(-0.4)
                .padding(.bottom, 4)

            Text(heroSubtitle)
                .font(.system(size: 12))
                .foregroundStyle(Color.white.opacity(0.6))
                .lineSpacing(2)
                .padding(.bottom, 10)

            // Usage bar
            HStack(spacing: 8) {
                Text("\(usageDaysLabel)z")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.white.opacity(0.5))
                    .frame(width: 28, alignment: .leading)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.05))
                            .frame(height: 5)
                        Capsule()
                            .fill(LinearGradient(
                                colors: [Color.solRoseExact, Color.solRoseDeep],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(width: max(0, geo.size.width * usagePercent), height: 5)
                    }
                }
                .frame(height: 5)

                Text("\(Int(usagePercent * 100))%")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.solRoseExact)
            }
            .frame(height: 18)
        }
    }

    // MARK: - Brand selector

    private var brandSelector: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("BRAND")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.5))
                .tracking(0.5)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(BrandChoice.allCases, id: \.self) { brand in
                        Button {
                            Haptics.light()
                            selectedBrand = brand
                            if editingSubscription == nil && name.isEmpty {
                                name = brand.displayName
                            }
                        } label: {
                            VStack(spacing: 6) {
                                SolBrandLogo(brand.logoBrand, size: 44)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                                            .stroke(
                                                selectedBrand == brand
                                                    ? Color.solMintExact.opacity(0.7)
                                                    : Color.clear,
                                                lineWidth: 2
                                            )
                                    )
                                Text(brand.displayName)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(
                                        selectedBrand == brand
                                            ? Color.solMintLight
                                            : Color.white.opacity(0.5)
                                    )
                                    .lineLimit(1)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    // MARK: - Form fields

    private var nameField: some View {
        formField(label: "NUME") {
            TextField("ex: Netflix, Spotify", text: $name)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.white)
                .textFieldStyle(.plain)
        }
    }

    private var amountField: some View {
        formField(label: "COST") {
            HStack(spacing: 4) {
                TextField("0", text: $amountText)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.plain)
                    .monospacedDigit()
                    .onChange(of: amountText) { _, newValue in
                        let filtered = newValue.filter(\.isNumber)
                        if filtered != newValue { amountText = filtered }
                        if filtered.hasPrefix("0") && filtered.count > 1 {
                            amountText = String(filtered.drop(while: { $0 == "0" }))
                        }
                    }
                Text("RON")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.4))
            }
        }
    }

    private var frequencyField: some View {
        formField(label: "FRECVENȚĂ") {
            Menu {
                ForEach(Frequency.allCases, id: \.self) { freq in
                    Button {
                        Haptics.light()
                        frequency = freq
                    } label: {
                        if frequency == freq {
                            Label(freq.displayName, systemImage: "checkmark")
                        } else {
                            Text(freq.displayName)
                        }
                    }
                }
            } label: {
                HStack {
                    Text(frequency.displayName)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.white)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.45))
                }
                .contentShape(Rectangle())
            }
        }
    }

    private var paymentDayField: some View {
        formField(label: "ZIUA PLĂȚII") {
            HStack(spacing: 4) {
                TextField("1", text: $paymentDay)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.white)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.plain)
                    .monospacedDigit()
                    .onChange(of: paymentDay) { _, newValue in
                        let filtered = newValue.filter(\.isNumber)
                        if filtered != newValue { paymentDay = filtered }
                        if let v = Int(filtered), v > 31 { paymentDay = "31" }
                    }
                Text("· a fiecărei luni")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.45))
                Spacer()
            }
        }
    }

    private var categoryField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("DIFICULTATE ANULARE")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.5))
                .tracking(0.5)

            HStack(spacing: 6) {
                ForEach(CancellationDifficulty.allCases, id: \.self) { difficulty in
                    SolPill(
                        difficulty.displayNameRO.capitalized,
                        isActive: cancellationDifficulty == difficulty
                    ) {
                        cancellationDifficulty = difficulty
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }

    @ViewBuilder
    private func formField<Content: View>(
        label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.5))
                .tracking(0.5)

            content()
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        }
    }

    // MARK: - Insight

    private var usageInsight: some View {
        SolInsightCard(
            icon: "chart.bar.fill",
            label: "DETALII UTILIZARE",
            timestamp: nil,
            accent: .mint
        ) {
            VStack(alignment: .leading, spacing: 4) {
                Text(usageInsightHeadline)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.white.opacity(0.85))
                    .lineSpacing(2)

                Text("Cost anual estimat: \(amountValue * frequency.monthsPerYear) RON.")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.5))
            }
        }
    }

    // MARK: - Computed

    private var amountValue: Int {
        Int(amountText) ?? 0
    }

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && amountValue > 0
    }

    private var heroHeadline: String {
        guard let s = editingSubscription, s.isGhost else {
            return editingSubscription == nil
                ? "Configurează abonamentul"
                : "Folosit recent"
        }
        return "Anulează — recuperabil \(amountValue * 12) RON/an"
    }

    private var heroSubtitle: String {
        guard let s = editingSubscription else {
            return "Adaugă datele și Solomon va monitoriza utilizarea automat."
        }
        if let days = s.lastUsedDaysAgo {
            return "Ultim semnal acum \(days) zile. Plătești dar nu folosești."
        }
        return "Nu avem semnal de utilizare încă."
    }

    private var usageDaysLabel: String {
        guard let s = editingSubscription, let days = s.lastUsedDaysAgo else {
            return "0"
        }
        return "\(days)"
    }

    private var usagePercent: CGFloat {
        guard let s = editingSubscription, let days = s.lastUsedDaysAgo else {
            return 0
        }
        // Higher days_ago means LESS usage. Invert for usage bar (capped at 120 days).
        let inv = max(0, min(1, 1.0 - CGFloat(days) / 120.0))
        return inv
    }

    private var usageInsightHeadline: String {
        guard let s = editingSubscription else {
            return "Vom monitoriza folosirea automat din tranzacții și activitate app."
        }
        if let days = s.lastUsedDaysAgo {
            return "Ai folosit acest abonament acum \(days) zile."
        }
        return "Nu avem semnal de utilizare în ultimele 30 zile."
    }

    // MARK: - Helpers

    private func loadIfEditing() {
        guard let s = editingSubscription else { return }
        name = s.name
        amountText = String(s.amountMonthly.amount)
        cancellationDifficulty = s.cancellationDifficulty
        selectedBrand = BrandChoice.fromName(s.name)
    }

    // MARK: - Actions

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            saveError = "Numele abonamentului nu poate fi gol."
            return
        }
        guard amountValue > 0 else {
            saveError = "Suma trebuie să fie mai mare decât 0."
            return
        }

        let repo = CoreDataSubscriptionRepository(context: moc)
        do {
            let subscription = Subscription(
                id: editingSubscription?.id ?? UUID(),
                name: trimmedName,
                amountMonthly: Money(amountValue),
                lastUsedDaysAgo: editingSubscription?.lastUsedDaysAgo,
                cancellationDifficulty: cancellationDifficulty
            )
            try repo.upsert(subscription)
            Haptics.success()
            dismiss()
        } catch {
            saveError = "Nu am putut salva: \(error.localizedDescription)"
        }
    }

    private func deleteSubscription() {
        guard let id = editingSubscription?.id else { return }
        let repo = CoreDataSubscriptionRepository(context: moc)
        do {
            try repo.delete(id: id)
            Haptics.success()
            dismiss()
        } catch {
            saveError = "Nu am putut șterge: \(error.localizedDescription)"
        }
    }
}

// MARK: - Frequency

private enum Frequency: String, CaseIterable {
    case monthly, quarterly, annual

    var displayName: String {
        switch self {
        case .monthly:   return "Lunar"
        case .quarterly: return "Trimestrial"
        case .annual:    return "Anual"
        }
    }

    var monthsPerYear: Int {
        switch self {
        case .monthly:   return 12
        case .quarterly: return 4
        case .annual:    return 1
        }
    }
}

// MARK: - BrandChoice

private enum BrandChoice: String, CaseIterable {
    case netflix, spotify, hbo, applemusic, glovo, bolt, uber, mega, other

    var displayName: String {
        switch self {
        case .netflix:    return "Netflix"
        case .spotify:    return "Spotify"
        case .hbo:        return "HBO Max"
        case .applemusic: return "Apple Music"
        case .glovo:      return "Glovo"
        case .bolt:       return "Bolt"
        case .uber:       return "Uber"
        case .mega:       return "Mega"
        case .other:      return "Altul"
        }
    }

    var logoBrand: SolBrandLogo.Brand {
        switch self {
        case .netflix:    return .netflix
        case .spotify:    return .spotify
        case .hbo:        return .hbo
        case .applemusic: return .applemusic
        case .glovo:      return .glovo
        case .bolt:       return .bolt
        case .uber:       return .uber
        case .mega:       return .mega
        case .other:      return .dotted
        }
    }

    static func fromName(_ name: String) -> BrandChoice {
        let lower = name.lowercased()
        if lower.contains("netflix") { return .netflix }
        if lower.contains("spotify") { return .spotify }
        if lower.contains("hbo")     { return .hbo }
        if lower.contains("apple")   { return .applemusic }
        if lower.contains("glovo")   { return .glovo }
        if lower.contains("bolt")    { return .bolt }
        if lower.contains("uber")    { return .uber }
        if lower.contains("mega")    { return .mega }
        return .other
    }
}

// MARK: - Preview

#Preview("Abonament nou") {
    SubscriptionEditView()
        .preferredColorScheme(.dark)
}

#Preview("Editează abonament") {
    SubscriptionEditView(editingSubscription: Subscription(
        id: UUID(),
        name: "Netflix",
        amountMonthly: Money(42),
        lastUsedDaysAgo: 112,
        cancellationDifficulty: .medium
    ))
    .preferredColorScheme(.dark)
}
