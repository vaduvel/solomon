import SwiftUI
import UserNotifications

// MARK: - Ecran 7 — Permisiuni (30 sec)
//
// Conform spec §11 ecran 7:
//   - 3 permission cards: Email (Gmail OAuth), Notificări push, Dataset training opt-in
//   - Default training: OFF (consimțământ explicit)

struct OnboardingScreen7Permissions: View {
    @EnvironmentObject var state: OnboardingState

    var body: some View {
        ScrollView {
            VStack(spacing: SolSpacing.lg) {
                VStack(alignment: .leading, spacing: SolSpacing.sm) {
                    Text("Permisiunile tale")
                        .font(.solH1)
                        .foregroundStyle(Color.solForeground)
                    Text("Solomon are nevoie de câteva acces-uri pentru a funcționa. Tu controlezi tot.")
                        .font(.solBody)
                        .foregroundStyle(Color.solMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, SolSpacing.lg)

                // Email
                PermissionCard(
                    icon: "envelope.fill",
                    iconVariant: .cyan,
                    title: "Email",
                    description: "Pentru a-ți arăta unde se duc banii, am nevoie să citesc emailurile cu facturi și abonamente.",
                    privacyNote: "Doar emailuri financiare. Conținutul rămâne pe telefonul tău.",
                    primaryTitle: "Conectează Gmail",
                    primaryAction: { connectGmail() },
                    secondaryTitle: "Mai târziu",
                    secondaryAction: { },
                    isGranted: state.gmailConnected
                )

                // Notificări push
                PermissionCard(
                    icon: "bell.fill",
                    iconVariant: .neon,
                    title: "Notificări",
                    description: "Doar lucruri care contează: factura mare, IFN suspect, săptămâna ta.",
                    privacyNote: nil,
                    primaryTitle: "Da, alertează-mă",
                    primaryAction: { Task { await requestPushPermission() } },
                    secondaryTitle: "Mai târziu",
                    secondaryAction: { },
                    isGranted: state.pushAllowed
                )

                // Dataset training opt-in
                PermissionCard(
                    icon: "brain.head.profile",
                    iconVariant: .tinted,
                    title: "Ajută Solomon",
                    description: "Conversațiile tale, anonimizate, ne ajută să antrenăm un model românesc mai bun pentru toți.",
                    privacyNote: "Default OFF. Tu decizi.",
                    primaryTitle: "Da, ajut",
                    primaryAction: { state.trainingOptIn = true },
                    secondaryTitle: "Nu, mulțumesc",
                    secondaryAction: { state.trainingOptIn = false },
                    isGranted: state.trainingOptIn
                )

                Spacer().frame(height: SolSpacing.base)

                SolomonButton("Continuă", icon: "arrow.right") {
                    state.next()
                }
            }
            .padding(.horizontal, SolSpacing.screenHorizontal)
            .padding(.bottom, SolSpacing.xl)
        }
    }

    // MARK: - Actions

    private func connectGmail() {
        // TODO Faza 14+: Gmail OAuth flow real (GoogleSignIn SDK)
        // Pentru moment: marcăm ca pending, userul va folosi Shortcuts pentru ingestie
        state.gmailConnected = true
    }

    private func requestPushPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            state.pushAllowed = granted
        } catch {
            state.pushAllowed = false
        }
    }
}

#Preview {
    ZStack {
        Color.solCanvas.ignoresSafeArea()
        OnboardingScreen7Permissions()
            .environmentObject(OnboardingState())
    }
    .preferredColorScheme(.dark)
}
