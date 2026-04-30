import SwiftUI
import UserNotifications

// MARK: - Ecran 7 — Permisiuni (Solomon DS)
//
// Pattern: spiral.html (eyebrow + titlu) + settings.html (toggle rows în SolListCard).

struct OnboardingScreen7Permissions: View {
    @Environment(OnboardingState.self) var state

    var body: some View {
        ZStack {
            MeshBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Header — eyebrow + titlu
                    VStack(alignment: .leading, spacing: 6) {
                        Text("PASUL 7")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.solMintLight)
                            .tracking(1.4)

                        Text("Permisiuni")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(Color.white)
                            .tracking(-0.7)

                        Text("Solomon are nevoie de permisiuni ca să te ajute")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.white.opacity(0.55))
                            .padding(.top, 2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 4)

                    // Permission rows
                    SolListCard {
                        permissionRow(
                            icon: "bell.fill",
                            iconAccent: .mint,
                            title: "Notificări",
                            subtitle: "Pentru alerte critice (spirală, plăți restante)",
                            isGranted: state.pushAllowed
                        )
                        SolHairlineDivider()
                        permissionRow(
                            icon: "lock.shield.fill",
                            iconAccent: .blue,
                            title: "Date private",
                            subtitle: "Tot pe device, nicio cloud",
                            isGranted: true
                        )
                    }

                    // Insight — DE CE?
                    SolInsightCard(
                        icon: "questionmark.circle.fill",
                        label: "DE CE?",
                        accent: .blue
                    ) {
                        Text("Notificările te previn la timp, nu post-factum. Datele rămân pe device — Solomon rulează local, fără cloud, fără tracking.")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.white.opacity(0.75))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Buttons
                    VStack(spacing: 10) {
                        SolPrimaryButton("Permite și continuă", fullWidth: true) {
                            Task { await requestAndContinue() }
                        }
                        SolSecondaryButton("Mai târziu", fullWidth: true) {
                            state.next()
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 32)
            }
        }
    }

    // MARK: - Row

    @ViewBuilder
    private func permissionRow(
        icon: String,
        iconAccent: SolAccent,
        title: String,
        subtitle: String,
        isGranted: Bool
    ) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(iconAccent.iconGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(iconAccent.color.opacity(0.20), lineWidth: 1)
                    )
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(iconAccent.color)
            }
            .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.white)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.4))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            SolChip(isGranted ? "ACTIV" : "ÎN AȘTEPTARE", kind: isGranted ? .mint : .muted)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Actions

    private func requestAndContinue() async {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge, .criticalAlert]
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: options)
            await MainActor.run {
                state.pushAllowed = granted
                state.next()
            }
        } catch {
            do {
                let granted = try await UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.alert, .sound, .badge])
                await MainActor.run {
                    state.pushAllowed = granted
                    state.next()
                }
            } catch {
                await MainActor.run {
                    state.pushAllowed = false
                    state.next()
                }
            }
        }
    }
}

#Preview {
    OnboardingScreen7Permissions()
        .environment(OnboardingState())
        .preferredColorScheme(.dark)
}
