import SwiftUI
import SolomonCore
import SolomonStorage

// MARK: - ProfileEditView
//
// Edit UserProfile după onboarding (din Settings → Profil financiar).
// Permite update la: nume, addressing, salary range, payday, bank, secondary income.

struct ProfileEditView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var addressing: Addressing = .tu
    @State private var ageRange: AgeRange = .range25to35
    @State private var salaryRange: SalaryRange = .range5to8
    @State private var paydayDay: Int = 28
    @State private var primaryBank: Bank = .bancaTransilvania
    @State private var hasSecondaryIncome: Bool = false
    @State private var saveError: String?
    @State private var didSave: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.solCanvas.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: SolSpacing.lg) {
                        VStack(alignment: .leading, spacing: SolSpacing.sm) {
                            Text("Editează profilul tău")
                                .font(.solH2)
                                .foregroundStyle(Color.solForeground)
                            Text("Solomon folosește astea ca să calculeze Safe to Spend.")
                                .font(.solBody)
                                .foregroundStyle(Color.solMuted)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, SolSpacing.lg)

                        // Nume
                        VStack(alignment: .leading, spacing: SolSpacing.xs) {
                            sectionLabel("NUME")
                            SolomonTextInput(placeholder: "ex: Andrei", text: $name, icon: "person.fill")
                        }

                        // Addressing
                        VStack(alignment: .leading, spacing: SolSpacing.sm) {
                            sectionLabel("CUM ÎȚI ZICEM")
                            HStack(spacing: SolSpacing.sm) {
                                SelectableChip(title: "Pe nume (tu)", isSelected: addressing == .tu) {
                                    addressing = .tu
                                }
                                SelectableChip(title: "Formal (dvs.)", isSelected: addressing == .dumneavoastra) {
                                    addressing = .dumneavoastra
                                }
                                Spacer()
                            }
                        }

                        // Salary range
                        VStack(alignment: .leading, spacing: SolSpacing.sm) {
                            sectionLabel("VENIT LUNAR (NET)")
                            VStack(spacing: SolSpacing.sm) {
                                ForEach([SalaryRange.under3k, .range3to5, .range5to8, .range8to15, .over15k], id: \.self) { r in
                                    SelectableChip(title: salaryLabel(r), isSelected: salaryRange == r) {
                                        salaryRange = r
                                    }
                                }
                            }
                        }

                        // Payday
                        VStack(alignment: .leading, spacing: SolSpacing.sm) {
                            sectionLabel("DATA SALARIULUI")
                            DayOfMonthPicker(selectedDay: $paydayDay)
                                .padding(SolSpacing.base)
                                .solCard()
                        }

                        // Bank
                        VStack(alignment: .leading, spacing: SolSpacing.sm) {
                            sectionLabel("BANCA PRINCIPALĂ")
                            BankPicker(selectedBank: Binding(
                                get: { primaryBank },
                                set: { primaryBank = $0 ?? .other }
                            ))
                        }

                        // Secondary income
                        SolomonToggle(
                            title: "Ai venituri extra?",
                            subtitle: "Freelance, chirii, etc.",
                            isOn: $hasSecondaryIncome
                        )

                        if let saveError {
                            Text(saveError)
                                .font(.solCaption)
                                .foregroundStyle(Color.solDestructive)
                        }

                        SolomonButton("Salvează modificările", icon: "checkmark") {
                            save()
                        }
                        .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.4 : 1)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(.horizontal, SolSpacing.screenHorizontal)
                    .padding(.bottom, SolSpacing.hh)
                }
            }
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Anulează") { dismiss() }
                        .foregroundStyle(Color.solMuted)
                }
            }
            .onAppear { loadProfile() }
            .alert("✅ Salvat", isPresented: $didSave) {
                Button("OK") { dismiss() }
            } message: {
                Text("Profilul tău a fost actualizat.")
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.solMicro)
            .foregroundStyle(Color.solMuted)
            .tracking(1.2)
    }

    private func salaryLabel(_ range: SalaryRange) -> String {
        switch range {
        case .under3k:    return "Sub 3.000 RON"
        case .range3to5:  return "3.000 - 5.000 RON"
        case .range5to8:  return "5.000 - 8.000 RON"
        case .range8to15: return "8.000 - 15.000 RON"
        case .over15k:    return "Peste 15.000 RON"
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
    }

    private func save() {
        let ctx = SolomonPersistenceController.shared.container.viewContext
        let repo = CoreDataUserProfileRepository(context: ctx)

        let demo = DemographicProfile(
            name: name.trimmingCharacters(in: .whitespaces),
            addressing: addressing,
            ageRange: ageRange
        )
        let fin = FinancialProfile(
            salaryRange: salaryRange,
            salaryFrequency: .monthly(dayOfMonth: paydayDay),
            hasSecondaryIncome: hasSecondaryIncome,
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
