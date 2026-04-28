import Foundation

// MARK: - SubscriptionCancellationDB
//
// Knowledge base pentru anularea celor mai populare servicii folosite de români.
// Spec §13.3: top 30 services cu cancellation guides.
//
// Fiecare entry conține:
//   - URL direct la pagina de anulare (sau settings unde se face)
//   - Pași sumari (1-2 propoziții) ca user-ul să știe ce-l așteaptă
//   - Avertismente (penalty, perioadă fără rambursare etc.)
//   - Sugestie de alternativă (când e cazul)
//
// Folosit din SubscriptionAuditView pentru a popula `cancellationUrl` etc.
// la subscription-ele detectate auto.

public enum SubscriptionCancellationDB {

    public struct Entry: Sendable, Hashable {
        public let nameMatchPatterns: [String]   // toate lowercase
        public let cancellationUrl: URL?
        public let stepsSummary: String
        public let warning: String?
        public let alternative: String?
        public let difficulty: CancellationDifficulty

        public init(
            nameMatchPatterns: [String],
            cancellationUrl: URL?,
            stepsSummary: String,
            warning: String? = nil,
            alternative: String? = nil,
            difficulty: CancellationDifficulty = .medium
        ) {
            self.nameMatchPatterns = nameMatchPatterns.map { $0.lowercased() }
            self.cancellationUrl = cancellationUrl
            self.stepsSummary = stepsSummary
            self.warning = warning
            self.alternative = alternative
            self.difficulty = difficulty
        }
    }

    /// Caută entry-ul potrivit pentru un subscription după nume.
    public static func entry(forSubscriptionName name: String) -> Entry? {
        let lower = name.lowercased()
        return all.first { entry in
            entry.nameMatchPatterns.contains { lower.contains($0) }
        }
    }

    // MARK: - Top 30 servicii (RO + globale frecvent folosite)

    public static let all: [Entry] = [

        // ── Streaming Video ─────────────────────────────────────────────────
        .init(
            nameMatchPatterns: ["netflix"],
            cancellationUrl: URL(string: "https://www.netflix.com/cancelplan"),
            stepsSummary: "Logare → Account → Cancel Membership. Active până la sfârșitul perioadei plătite.",
            warning: nil,
            alternative: "Dacă ai folosit doar 1 lună din 12, consideră Plan Standard with Ads",
            difficulty: .easy
        ),
        .init(
            nameMatchPatterns: ["hbo", "hbo max", "max"],
            cancellationUrl: URL(string: "https://play.max.com/account/preferences"),
            stepsSummary: "Settings → Subscription → Cancel. Pierzi acces imediat după perioada curentă.",
            difficulty: .easy
        ),
        .init(
            nameMatchPatterns: ["disney"],
            cancellationUrl: URL(string: "https://www.disneyplus.com/account/subscription"),
            stepsSummary: "Account → Subscription → Cancel.",
            difficulty: .easy
        ),
        .init(
            nameMatchPatterns: ["voyo"],
            cancellationUrl: URL(string: "https://www.voyo.ro/contul-meu"),
            stepsSummary: "Logare pe voyo.ro → Contul meu → Anulează abonamentul.",
            difficulty: .medium
        ),
        .init(
            nameMatchPatterns: ["antena play"],
            cancellationUrl: URL(string: "https://antenaplay.ro/contul-meu/abonament"),
            stepsSummary: "Logare antenaplay.ro → Contul meu → Renunță la abonament.",
            difficulty: .medium
        ),

        // ── Streaming Audio ─────────────────────────────────────────────────
        .init(
            nameMatchPatterns: ["spotify"],
            cancellationUrl: URL(string: "https://www.spotify.com/account/subscription/"),
            stepsSummary: "Account → Subscription → Cancel Premium.",
            alternative: "Spotify Free e gratuit cu reclame",
            difficulty: .easy
        ),
        .init(
            nameMatchPatterns: ["apple music"],
            cancellationUrl: URL(string: "https://music.apple.com/account/subscriptions"),
            stepsSummary: "Settings → [Numele tău] → Subscriptions → Apple Music → Cancel.",
            difficulty: .easy
        ),
        .init(
            nameMatchPatterns: ["youtube premium", "youtube music"],
            cancellationUrl: URL(string: "https://www.youtube.com/paid_memberships"),
            stepsSummary: "youtube.com → Avatar → Purchases → Cancel YouTube Premium.",
            difficulty: .easy
        ),
        .init(
            nameMatchPatterns: ["audible"],
            cancellationUrl: URL(string: "https://www.audible.com/account/subscription-management"),
            stepsSummary: "audible.com → Account → Cancel Membership.",
            warning: "Pierdere credite necheltuite",
            difficulty: .medium
        ),

        // ── Productivity / Cloud ────────────────────────────────────────────
        .init(
            nameMatchPatterns: ["icloud", "icloud+"],
            cancellationUrl: URL(string: "https://support.apple.com/en-us/HT207024"),
            stepsSummary: "Settings → [Numele tău] → iCloud → Manage Storage → Change Storage Plan → Downgrade.",
            warning: "Dacă ai mai mult de 5GB stocat, fișierele se pot șterge",
            alternative: "Free 5GB iCloud sau Google Drive 15GB",
            difficulty: .medium
        ),
        .init(
            nameMatchPatterns: ["google one"],
            cancellationUrl: URL(string: "https://one.google.com/storage"),
            stepsSummary: "one.google.com → Settings → Cancel membership.",
            difficulty: .easy
        ),
        .init(
            nameMatchPatterns: ["dropbox"],
            cancellationUrl: URL(string: "https://www.dropbox.com/account/plan"),
            stepsSummary: "Account → Plan → Downgrade to Basic (free).",
            difficulty: .easy
        ),
        .init(
            nameMatchPatterns: ["adobe creative cloud", "adobe"],
            cancellationUrl: URL(string: "https://account.adobe.com/plans"),
            stepsSummary: "Plans → Manage plan → Cancel.",
            warning: "Penalty 50% din suma rămasă pe contract anual",
            alternative: "GIMP, Affinity Photo (one-time payment)",
            difficulty: .hard
        ),
        .init(
            nameMatchPatterns: ["microsoft 365", "office 365"],
            cancellationUrl: URL(string: "https://account.microsoft.com/services"),
            stepsSummary: "account.microsoft.com → Services & subscriptions → Cancel.",
            difficulty: .easy
        ),
        .init(
            nameMatchPatterns: ["notion"],
            cancellationUrl: URL(string: "https://www.notion.so/my-integrations"),
            stepsSummary: "Settings → Plans → Switch to Free.",
            difficulty: .easy
        ),
        .init(
            nameMatchPatterns: ["1password"],
            cancellationUrl: URL(string: "https://my.1password.com/profile/subscription"),
            stepsSummary: "Profile → Subscription → Cancel.",
            warning: "După cancel, datele tale rămân criptate dar acces read-only",
            difficulty: .medium
        ),

        // ── AI / Dev ─────────────────────────────────────────────────────────
        .init(
            nameMatchPatterns: ["chatgpt", "openai"],
            cancellationUrl: URL(string: "https://chat.openai.com/#settings/Subscription"),
            stepsSummary: "Settings → Subscription → Cancel ChatGPT Plus.",
            difficulty: .easy
        ),
        .init(
            nameMatchPatterns: ["claude.ai", "anthropic"],
            cancellationUrl: URL(string: "https://claude.ai/settings/billing"),
            stepsSummary: "Settings → Billing → Cancel Claude Pro.",
            difficulty: .easy
        ),
        .init(
            nameMatchPatterns: ["github"],
            cancellationUrl: URL(string: "https://github.com/settings/billing"),
            stepsSummary: "Settings → Billing → Cancel plan.",
            difficulty: .easy
        ),
        .init(
            nameMatchPatterns: ["linkedin premium"],
            cancellationUrl: URL(string: "https://www.linkedin.com/premium/manage/cancellation/"),
            stepsSummary: "Account preferences → Manage Premium → Cancel.",
            difficulty: .medium
        ),

        // ── Gaming ──────────────────────────────────────────────────────────
        .init(
            nameMatchPatterns: ["playstation plus", "ps plus"],
            cancellationUrl: URL(string: "https://www.playstation.com/en-us/support/store/turn-off-auto-renew/"),
            stepsSummary: "PSN Account → Subscription → Turn off auto-renew.",
            difficulty: .medium
        ),
        .init(
            nameMatchPatterns: ["xbox game pass"],
            cancellationUrl: URL(string: "https://account.microsoft.com/services"),
            stepsSummary: "Microsoft account → Services → Manage → Cancel.",
            difficulty: .easy
        ),
        .init(
            nameMatchPatterns: ["nintendo"],
            cancellationUrl: URL(string: "https://accounts.nintendo.com"),
            stepsSummary: "Nintendo account → Shop → Cancel auto-renew.",
            difficulty: .medium
        ),

        // ── Wellness ────────────────────────────────────────────────────────
        .init(
            nameMatchPatterns: ["calm"],
            cancellationUrl: URL(string: "https://www.calm.com/profile"),
            stepsSummary: "Profile → Manage Subscription → Cancel.",
            difficulty: .medium
        ),
        .init(
            nameMatchPatterns: ["headspace"],
            cancellationUrl: URL(string: "https://www.headspace.com/subscription"),
            stepsSummary: "Account → Subscription → Cancel.",
            difficulty: .medium
        ),
        .init(
            nameMatchPatterns: ["duolingo"],
            cancellationUrl: URL(string: "https://www.duolingo.com/settings/super"),
            stepsSummary: "Settings → Super → Cancel.",
            alternative: "Duolingo Free e tot Foarte bun",
            difficulty: .easy
        ),

        // ── VPN ─────────────────────────────────────────────────────────────
        .init(
            nameMatchPatterns: ["nordvpn"],
            cancellationUrl: URL(string: "https://my.nordaccount.com/subscriptions"),
            stepsSummary: "Account → Subscriptions → Cancel auto-renewal.",
            warning: "30-day money-back garanție în primele 30 zile",
            difficulty: .medium
        ),
        .init(
            nameMatchPatterns: ["expressvpn"],
            cancellationUrl: URL(string: "https://www.expressvpn.com/support/troubleshooting/cancel-subscription/"),
            stepsSummary: "Account → Cancel Subscription. Cere refund la support pentru primele 30 zile.",
            difficulty: .medium
        ),

        // ── Design ──────────────────────────────────────────────────────────
        .init(
            nameMatchPatterns: ["figma"],
            cancellationUrl: URL(string: "https://www.figma.com/settings/billing"),
            stepsSummary: "Settings → Billing → Cancel plan.",
            difficulty: .easy
        ),
        .init(
            nameMatchPatterns: ["canva"],
            cancellationUrl: URL(string: "https://www.canva.com/settings/billing-and-teams/"),
            stepsSummary: "Settings → Billing → Cancel Pro.",
            difficulty: .easy
        ),
    ]

    // MARK: - Helpers for tests

    public static var totalEntries: Int { all.count }
    public static var supportedDomains: [String] {
        all.flatMap { $0.cancellationUrl?.host.map { [$0] } ?? [] }
    }
}
