import SwiftUI

// MARK: - AIFloatingBubble (DS v1.0)
//
// Buton flotant Solomon AI cu glow pulsant, ancorat bottom-right.
// Folosit ca "Ask Solomon AI" la oricare ecran.

struct AIFloatingBubble: View {

    let action: () -> Void
    var hasNotification: Bool = false

    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        Button(action: action) {
            ZStack {
                // Pulsing glow
                Circle()
                    .fill(LinearGradient.solHero)
                    .frame(width: 56, height: 56)
                    .blur(radius: 10)
                    .opacity(0.6)
                    .scaleEffect(pulseScale)

                // Main bubble
                ZStack {
                    Circle()
                        .fill(Color.solCard)
                        .frame(width: 56, height: 56)
                    Circle()
                        .stroke(Color.solPrimary, lineWidth: 1.5)
                        .frame(width: 56, height: 56)
                    Image(systemName: "sparkles")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(LinearGradient.solHero)
                }

                if hasNotification {
                    Circle()
                        .fill(Color.solDestructive)
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(Color.solCanvas, lineWidth: 2))
                        .offset(x: 18, y: -18)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulseScale = 1.4
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        Color.solCanvas.ignoresSafeArea()
        AIFloatingBubble(action: {}, hasNotification: true)
    }
    .preferredColorScheme(.dark)
}
