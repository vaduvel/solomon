import SwiftUI

// MARK: - ChatBubble (DS v1.0)
//
// Bubble pentru conversație cu Solomon AI.
// AI bubble: bg #1C2230, rounded-20 + tl-4 (pointer la stânga sus)
// User bubble: gradient mint→cyan, rounded-20 + tr-4
// Avatar dim: h-8 w-8

struct ChatBubble: View {

    enum Role {
        case ai
        case user
    }

    let role: Role
    let text: String
    var timestamp: String = "Now"
    var avatarLetter: String? = nil  // pentru user: prima literă din nume

    var body: some View {
        HStack(alignment: .top, spacing: SolSpacing.sm) {
            if role == .ai {
                aiAvatar
            } else {
                Spacer(minLength: 50)
            }

            VStack(alignment: role == .ai ? .leading : .trailing, spacing: 4) {
                if role == .ai {
                    Text("Solomon AI")
                        .font(.solMicro)
                        .foregroundStyle(Color.solPrimary)
                        .padding(.leading, SolSpacing.xs)
                }

                Text(text)
                    .font(.solBody)
                    .foregroundStyle(role == .user ? Color.solCanvas : Color.solForeground)
                    .padding(.horizontal, SolSpacing.base)
                    .padding(.vertical, SolSpacing.md)
                    .background(bubbleBackground)
                    .clipShape(BubbleShape(role: role))

                Text(timestamp)
                    .font(.solMicro)
                    .foregroundStyle(Color.solMuted)
                    .padding(.horizontal, SolSpacing.xs)
            }

            if role == .user {
                userAvatar
            } else {
                Spacer(minLength: 50)
            }
        }
    }

    @ViewBuilder
    private var aiAvatar: some View {
        ZStack {
            Circle()
                .fill(Color.solPrimary.opacity(0.15))
                .frame(width: 32, height: 32)
            Circle()
                .stroke(Color.solPrimary.opacity(0.4), lineWidth: 1)
                .frame(width: 32, height: 32)
            Image(systemName: "sparkles")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.solPrimary)
        }
    }

    @ViewBuilder
    private var userAvatar: some View {
        ZStack {
            Circle()
                .fill(LinearGradient.solHero)
                .frame(width: 32, height: 32)
            Text(avatarLetter ?? "U")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.solCanvas)
        }
    }

    @ViewBuilder
    private var bubbleBackground: some View {
        switch role {
        case .ai:
            Color.solCard
        case .user:
            LinearGradient.solPrimaryCTA
        }
    }
}

// MARK: - Asymmetric bubble shape

struct BubbleShape: Shape {
    let role: ChatBubble.Role

    func path(in rect: CGRect) -> Path {
        let radii: RectangleCornerRadii
        switch role {
        case .ai:
            radii = RectangleCornerRadii(topLeading: 4, bottomLeading: 20, bottomTrailing: 20, topTrailing: 20)
        case .user:
            radii = RectangleCornerRadii(topLeading: 20, bottomLeading: 20, bottomTrailing: 20, topTrailing: 4)
        }
        let shape = UnevenRoundedRectangle(cornerRadii: radii, style: .continuous)
        return shape.path(in: rect)
    }
}

#Preview {
    ZStack {
        Color.solCanvas.ignoresSafeArea()
        VStack(spacing: SolSpacing.md) {
            ChatBubble(
                role: .ai,
                text: "Hey Marian! Want help distributing your salary this month? 💸",
                timestamp: "Now"
            )
            ChatBubble(
                role: .user,
                text: "Yes! What do you suggest?",
                timestamp: "Now",
                avatarLetter: "M"
            )
        }
        .padding(SolSpacing.lg)
    }
    .preferredColorScheme(.dark)
}
