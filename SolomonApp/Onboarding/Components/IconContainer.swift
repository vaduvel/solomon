import SwiftUI

// MARK: - IconContainer (DS v1.0)
//
// Circle cu border colorat + icon stroke pentru categorii vizuale.
// 5 variante: neon (green), tinted (mint dim), cyan, warn (amber), danger (red).
// Folosit în:
//   - Categorii cheltuieli (Food, Transport, Bills...)
//   - Trust badges (ecran 3 onboarding)
//   - AI bubble icon
//   - Permission cards (ecran 7 onboarding)

struct IconContainer: View {

    enum Variant {
        case neon       // green border + green icon
        case tinted     // green dim
        case cyan       // cyan
        case warn       // amber
        case danger     // red

        var color: Color {
            switch self {
            case .neon:    return .solPrimary
            case .tinted:  return .solPrimary.opacity(0.6)
            case .cyan:    return .solCyan
            case .warn:    return .solWarning
            case .danger:  return .solDestructive
            }
        }

        var bgOpacity: Double { 0.10 }
        var borderOpacity: Double { 0.40 }
    }

    let systemName: String
    var variant: Variant = .neon
    var size: CGFloat = 48
    var iconSize: CGFloat = 20

    var body: some View {
        ZStack {
            Circle()
                .fill(variant.color.opacity(variant.bgOpacity))

            Circle()
                .stroke(variant.color.opacity(variant.borderOpacity), lineWidth: 1.5)

            Image(systemName: systemName)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundStyle(variant.color)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    ZStack {
        Color.solCanvas.ignoresSafeArea()
        HStack(spacing: 16) {
            IconContainer(systemName: "sparkles", variant: .neon)
            IconContainer(systemName: "bolt.fill", variant: .tinted)
            IconContainer(systemName: "bolt.fill", variant: .cyan)
            IconContainer(systemName: "exclamationmark.triangle.fill", variant: .warn)
            IconContainer(systemName: "xmark", variant: .danger)
        }
    }
    .preferredColorScheme(.dark)
}
