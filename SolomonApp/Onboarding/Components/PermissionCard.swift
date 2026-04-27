import SwiftUI

// MARK: - PermissionCard
//
// Card pentru request de permisiune (Ecran 7 onboarding).
// Layout:
//   [Icon] [Title]
//   [Description]
//   [Detail caption — privacy assurance]
//   [Primary CTA] [Secondary "Mai târziu"]

struct PermissionCard: View {

    let icon: String
    let iconVariant: IconContainer.Variant
    let title: String
    let description: String
    let privacyNote: String?
    let primaryTitle: String
    let primaryAction: () -> Void
    let secondaryTitle: String
    let secondaryAction: () -> Void
    var isGranted: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: SolSpacing.base) {
            HStack(spacing: SolSpacing.md) {
                IconContainer(systemName: icon, variant: iconVariant, size: 44, iconSize: 18)
                Text(title)
                    .font(.solH3)
                    .foregroundStyle(Color.solForeground)
                Spacer()
                if isGranted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.solPrimary)
                }
            }

            Text(description)
                .font(.solBody)
                .foregroundStyle(Color.solMuted)
                .fixedSize(horizontal: false, vertical: true)

            if let privacyNote {
                HStack(spacing: SolSpacing.xs) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.solPrimary)
                    Text(privacyNote)
                        .font(.solCaption)
                        .foregroundStyle(Color.solMuted)
                }
                .padding(.vertical, SolSpacing.xs)
            }

            if !isGranted {
                HStack(spacing: SolSpacing.sm) {
                    SolomonButton(primaryTitle, action: primaryAction)
                    SolomonButton(secondaryTitle, style: .ghost, action: secondaryAction)
                        .frame(width: 100)
                }
            }
        }
        .padding(SolSpacing.cardStandard)
        .solCard()
    }
}

#Preview {
    ZStack {
        Color.solCanvas.ignoresSafeArea()
        VStack(spacing: SolSpacing.md) {
            PermissionCard(
                icon: "envelope.fill",
                iconVariant: .cyan,
                title: "Email",
                description: "Pentru a-ți arăta unde se duc banii, am nevoie să citesc emailurile cu facturi și abonamente.",
                privacyNote: "Datele rămân pe telefonul tău",
                primaryTitle: "Conectează Gmail",
                primaryAction: {},
                secondaryTitle: "Mai târziu",
                secondaryAction: {}
            )
            PermissionCard(
                icon: "bell.fill",
                iconVariant: .neon,
                title: "Notificări",
                description: "Doar lucruri care contează: factura mare, IFN suspect, săptămâna ta.",
                privacyNote: nil,
                primaryTitle: "Da, alertează-mă",
                primaryAction: {},
                secondaryTitle: "Mai târziu",
                secondaryAction: {},
                isGranted: true
            )
        }
        .padding(SolSpacing.lg)
    }
    .preferredColorScheme(.dark)
}
