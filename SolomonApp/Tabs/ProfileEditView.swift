import SwiftUI
import SolomonCore
import SolomonStorage

// MARK: - ProfileEditView (Claude Design v3)
//
// Pixel-fidel cu `Solomon DS / screens/settings.html` + `goal-edit.html`:
//   - MeshBackground (mint/blue/violet)
//   - Sheet handle + back button + brand "SOLOMON · PROFIL FINANCIAR" + titlu "Editează profilul tău"
//   - Avatar header (54×54 mint gradient + inițiale) + nume + chip-uri "Pro" / "→ Plan"
//   - Secțiuni cu SolSectionHeaderRow:
//       * "DATE PERSONALE" — SolListCard cu nume (TextField glass), age range (SolPill), addressing (SolPill)
//       * "FINANCE" — SolListCard cu salary range (SolPill), bank (BankPicker), payday (DayOfMonthPicker)
//       * "VENIT EXTRA" — SolListCard cu Toggle "Ai venit extra?" + sumă RON (TextField glass)
//   - SolPrimaryButton "Salvează modificările" fullWidth
//   - SolInsightCard(.rose) pentru eroare
//
// Business logic păstrat 100%: loadProfile, save, demographics, financials,
// secondary income, payday day picker, Addressing, AgeRange, SalaryRange, Bank,
// BankPicker, DayOfMonthPicker, SolomonTextInput.

struct ProfileEditView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var addressing: Addressing = .tu
    @State private var ageRange: AgeRange = .range25to35
    @State private var salaryRange: SalaryRange = .range5to8
    @State private var paydayDay: Int = 28
    @State private var primaryBank: Bank = .bancaTransilvania
    @State private var hasSecondaryIncome: Bool = false
    @State private var secondaryIncomeRON: Int = 0
    @State private var saveError: String?
    @State private var didSave: Bool = false

    @FocusState private var nameFocused: Bool
    @FocusState private var secondaryFocused: Bool

    var body: some View {
        ZStack {
            MeshBackground()

            ScrollView {
                VStack(spacing: SolSpacing.md) {
                    sheetHandle
                    appBar
                    profileHeader

                    // DATE PERSONALE
                    SolSectionHeaderRow("DATE PERSONALE")
                    personalSection

                    // FINANCE
                    SolSectionHeaderRow("FINANCE")
                    financeSection

                    // VENIT EXTRA
                    SolSectionHeaderRow("VENIT EXTRA")
                    secondaryIncomeSection

                    // Eroare
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
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    // Salvează
                    SolPrimaryButton(
                        "Salvează modificările",
                        accent: .mint,
                        fullWidth: true
                    ) {
                        save()
                    }
                    .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.4 : 1)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .padding(.top, SolSpacing.sm)
                }
                .padding(.horizontal, SolSpacing.screenHorizontal)
                .padding(.bottom, SolSpacing.hh)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { loadProfile() }
        .alert("Salvat", isPresented: $didSave) {
            Button("OK") { dismiss() }
        } message: {
            Text("Profilul tău a fost actualizat.")
        }
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
                Text("SOLOMON · PROFIL FINANCIAR")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.45))
                    .tracking(1.4)
                    .textCase(.uppercase)
                Text("Editează profilul tău")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .tracking(-0.4)
                    .lineLimit(1)
                Text("Solomon folosește astea ca să calculeze Safe to Spend.")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.white.opacity(0.45))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)

            // Mirror back button width to keep title centered
            Color.clear.frame(width: 38, height: 38)
        }
        .padding(.bottom, SolSpacing.md)
    }

    // MARK: - Profile header (avatar + name + chips)

    private var profileHeader: some View {
        HStack(spacing: 14) {
            // Avatar 54×54 rounded square cu inițiale
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.solMintExact, Color.solMintDeep],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.20), lineWidth: 1)
                    )
                    .shadow(color: Color.solMintExact.opacity(0.4), radius: 12, x: 0, y: 8)

                Text(initials)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color(red: 0x05/255, green: 0x2E/255, blue: 0x16/255))
                    .tracking(-0.5)
            }
            .frame(width: 54, height: 54)

            VStack(alignment: .leading, spacing: 6) {
                Text(name.isEmpty ? "Profilul tău" : name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .lineLimit(1)
                Text(subtitleText)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.5))
                    .lineLimit(1)
                HStack(spacing: 6) {
                    SolChip("Pro", kind: .mint)
                    SolChip("→ Plan", kind: .muted)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.04), Color.white.opacity(0.015)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .background(.ultraThinMaterial.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
        .padding(.bottom, SolSpacing.sm)
    }

    private var initials: String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return "S" }
        let parts = trimmed.split(separator: " ")
        if parts.count >= 2,
           let f = parts.first?.first,
           let l = parts.last?.first {
            return "\(f)\(l)".uppercased()
        }
        return String(trimmed.prefix(2)).uppercased()
    }

    private var subtitleText: String {
        primaryBank.displayNameRO + " · " + ageRange.displayNameRO
    }

    // MARK: - DATE PERSONALE

    private var personalSection: some View {
        SolListCard {
            // NUME
            VStack(alignment: .leading, spacing: 6) {
                fieldLabel("NUME")
                glassInput(isFocused: nameFocused) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.4))
                            .frame(width: 18)
                        TextField("ex: Andrei", text: $name)
                            .textFieldStyle(.plain)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.white)
                            .focused($nameFocused)
                            .submitLabel(.done)
                            .autocorrectionDisabled()
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 14)

            SolHairlineDivider()

            // VÂRSTĂ — SolPill row
            VStack(alignment: .leading, spacing: 8) {
                fieldLabel("VÂRSTĂ")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(AgeRange.allCases, id: \.self) { r in
                            SolPill(r.displayNameRO, isActive: ageRange == r) {
                                ageRange = r
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 14)

            SolHairlineDivider()

            // CUM ÎȚI ZICEM — SolPill row
            VStack(alignment: .leading, spacing: 8) {
                fieldLabel("CUM ÎȚI ZICEM")
                HStack(spacing: 6) {
                    SolPill("Pe nume (tu)", isActive: addressing == .tu) {
                        addressing = .tu
                    }
                    SolPill("Formal (dvs.)", isActive: addressing == .dumneavoastra) {
                        addressing = .dumneavoastra
                    }
                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 14)
        }
    }

    // MARK: - FINANCE

    private var financeSection: some View {
        SolListCard {
            // SALARIU — SolPill row
            VStack(alignment: .leading, spacing: 8) {
                fieldLabel("SALARIU LUNAR (NET)")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(SalaryRange.allCases, id: \.self) { r in
                            SolPill(salaryLabel(r), isActive: salaryRange == r) {
                                salaryRange = r
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 14)

            SolHairlineDivider()

            // BANCĂ — păstrăm BankPicker existent
            VStack(alignment: .leading, spacing: 8) {
                fieldLabel("BANCA PRINCIPALĂ")
                BankPicker(selectedBank: Binding(
                    get: { primaryBank },
                    set: { primaryBank = $0 ?? .other }
                ))
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 14)

            SolHairlineDivider()

            // ZIUA SALARIULUI — DayOfMonthPicker existent în glass container
            VStack(alignment: .leading, spacing: 8) {
                fieldLabel("ZIUA SALARIULUI")
                DayOfMonthPicker(selectedDay: $paydayDay)
                    .padding(SolSpacing.base)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white.opacity(0.04))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 14)
        }
    }

    // MARK: - VENIT EXTRA

    private var secondaryIncomeSection: some View {
        SolListCard {
            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: $hasSecondaryIncome) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ai venit extra?")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.white)
                        Text("Freelance, chirii, dividende etc.")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.white.opacity(0.4))
                    }
                }
                .tint(Color.solMintExact)

                if hasSecondaryIncome {
                    VStack(alignment: .leading, spacing: 6) {
                        fieldLabel("APROXIMATIV CÂT (RON / LUNĂ)")
                        glassInput(isFocused: secondaryFocused) {
                            HStack(spacing: 4) {
                                Image(systemName: "banknote")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Color.white.opacity(0.4))
                                    .frame(width: 18)
                                TextField(
                                    "ex: 1500",
                                    text: Binding(
                                        get: { secondaryIncomeRON > 0 ? "\(secondaryIncomeRON)" : "" },
                                        set: { secondaryIncomeRON = Int($0) ?? 0 }
                                    )
                                )
                                .textFieldStyle(.plain)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color.white)
                                .keyboardType(.numberPad)
                                .monospacedDigit()
                                .focused($secondaryFocused)
                                Text("RON")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Color.white.opacity(0.4))
                            }
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(16)
            .animation(.spring(response: 0.3, dampingFraction: 0.85), value: hasSecondaryIncome)
        }
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
    private func glassInput<Content: View>(
        isFocused: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 8) {
            content()
        }
        .padding(.horizontal, 16)
        .frame(height: 50)
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
        .animation(.smooth(duration: 0.2), value: isFocused)
    }

    private func salaryLabel(_ range: SalaryRange) -> String {
        switch range {
        case .under3k:    return "Sub 3.000"
        case .range3to5:  return "3.000 - 5.000"
        case .range5to8:  return "5.000 - 8.000"
        case .range8to15: return "8.000 - 15.000"
        case .over15k:    return "Peste 15.000"
        }
    }

    private func loadProfile() {
        let ctx = SolomonPersistenceController.shared.container.viewContext
        let repo = CoreDataUserProfileRepository(context: ctx)
        guard let profile = try? repo.fetchProfile() else { return }
        name = profile.demographics.name
        addressing = profile.demographics.addressing
        ageRange = profile.demographics.ageRange
        salaryRange = profile.financials.salaryRange
        if case .monthly(let day) = profile.financials.salaryFrequency {
            paydayDay = day
        }
        primaryBank = profile.financials.primaryBank
        hasSecondaryIncome = profile.financials.hasSecondaryIncome
        // FIX 5: încarc și secondaryIncomeAvg ca să nu se piardă la save
        secondaryIncomeRON = profile.financials.secondaryIncomeAvg?.amount ?? 0
    }

    private func save() {
        let ctx = SolomonPersistenceController.shared.container.viewContext
        let repo = CoreDataUserProfileRepository(context: ctx)

        let demo = DemographicProfile(
            name: name.trimmingCharacters(in: .whitespaces),
            addressing: addressing,
            ageRange: ageRange
        )
        // FIX 5: păstrăm secondaryIncomeAvg când toggle-ul e ON
        let fin = FinancialProfile(
            salaryRange: salaryRange,
            salaryFrequency: .monthly(dayOfMonth: paydayDay),
            hasSecondaryIncome: hasSecondaryIncome,
            secondaryIncomeAvg: hasSecondaryIncome && secondaryIncomeRON > 0 ? Money(secondaryIncomeRON) : nil,
            primaryBank: primaryBank
        )
        let profile = UserProfile(demographics: demo, financials: fin)

        do {
            try repo.saveProfile(profile)
            didSave = true
        } catch {
            saveError = error.localizedDescription
        }
    }
}

#Preview {
    ProfileEditView()
        .preferredColorScheme(.dark)
}
