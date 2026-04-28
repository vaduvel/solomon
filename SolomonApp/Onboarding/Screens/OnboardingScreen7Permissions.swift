import SwiftUI
import UserNotifications

// MARK: - Ecran 7 — Permisiuni (Apple HIG aligned)
//
// Refactor: butoane stacked vertical (NU side-by-side care făcea wrap urât).
// Pattern HIG: explain → permission card → next.
// Spec §11 ecran 7.

struct OnboardingScreen7Permissions: View {
    @EnvironmentObject var state: OnboardingState

    var body: some View {
        ScrollView {
            VStack(spacing: SolSpacing.xl) {

                // Header
                VStack(alignment: .leading, spacing: SolSpacing.xs) {
                    Text("Permisiunile tale")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(Color.solForeground)
                    Text("Solomon are nevoie de câteva acces-uri. Tu controlezi tot.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, SolSpacing.lg)

                permissionRow(
                    icon: "envelope.fill",
                    iconColor: .solCyan,
                    title: "Email",
                    description: "Pentru a-ți arăta unde se duc banii. Doar emailuri financiare.",
                    isGranted: state.gmailConnected,
                    primaryTitle: "Conectează Gmail",
                    primaryAction: connectGmail
                )

                permissionRow(
                    icon: "bell.fill",
                    iconColor: .solPrimary,
                    title: "Notificări",
                    description: "Doar lucruri care contează: factura mare, IFN suspect, săptămâna ta.",
                    isGranted: state.pushAllowed,
                    primaryTitle: "Activează",
                    primaryAction: { Task { await requestPushPermission() } }
                )

                permissionRow(
                    icon: "brain.head.profile",
                    iconColor: .solWarning,
                    title: "Ajută Solomon",
                    description: "Conversațiile tale, anonimizate, antrenează un model românesc mai bun.",
                    isGranted: state.trainingOptIn,
                    primaryTitle: "Da, ajut",
                    primaryAction: { state.trainingOptIn = true }
                )
            }
            .padding(.horizontal, SolSpacing.lg)
            .padding(.bottom, SolSpacing.xxxl)
        }
        .safeAreaInset(edge: .bottom) {
            SolomonButton("Continuă", icon: "arrow.right") {
                Haptics.medium()
                state.next()
            }
            .padding(.horizontal, SolSpacing.lg)
            .padding(.vertical, SolSpacing.base)
            .background(.ultraThinMaterial)
        }
    }

    // MARK: - Permission row (vertical stack, NU side-by-side)

    @ViewBuilder
    private func permissionRow(
        icon: String,
        iconColor: Color,
        title: String,
        description: String,
        isGranted: Bool,
        primaryTitle: String,
        primaryAction: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: SolSpacing.md) {
            HStack(spacing: SolSpacing.md) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(iconColor)
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 32)

                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.solForeground)

                Spacer()

                if isGranted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.solPrimary)
                        .symbolRenderingMode(.hierarchical)
                }
            }

            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if !isGranted {
                Button(primaryTitle) {
                    Haptics.light()
                    primaryAction()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .tint(Color.solPrimary)
                .frame(maxWidth: .infinity, minHeight: 44)
            }
        }
        .padding(SolSpacing.cardStandard)
        .solCard()
    }

    // MARK: - Actions

    private func connectGmail() {
        // Faza 28+: Gmail OAuth flow real (GoogleSignIn SDK)
        state.gmailConnected = true
        Haptics.success()
    }

    private func requestPushPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            state.pushAllowed = granted
            await MainActor.run {
                granted ? Haptics.success() : Haptics.warning()
            }
        } catch {
            state.pushAllowed = false
            await MainActor.run { Haptics.error() }
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
