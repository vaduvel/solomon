import Foundation

// MARK: - MerchantCategoryMatcher
//
// Mapează numele unui merchant la TransactionCategory pe baza unui dicționar
// de cuvinte-cheie românești + internaționali frecvenți.
//
// Strategia: keyword matching case-insensitive, primul match câștigă.
// Prioritate: categorii specifice (IFN, BNPL) > lifestyle > essentials > unknown.

public enum MerchantCategoryMatcher {

    // MARK: - Public API

    /// Returnează categoria cea mai probabilă pentru un merchant.
    /// Dacă nu există match, returnează `.unknown`.
    public static func category(for merchant: String) -> TransactionCategory {
        let lower = merchant.lowercased()
        for (keywords, category) in rules {
            if keywords.contains(where: { lower.contains($0) }) {
                return category
            }
        }
        return .unknown
    }

    // MARK: - Rules
    // Ordinea contează: mai specific înainte de mai general.

    static let rules: [([String], TransactionCategory)] = [

        // ── Livrări mâncare ──────────────────────────────────────────────────
        (["glovo", "bolt food", "tazz", "foodpanda", "justeat",
          "just eat", "wolt", "uber eat", "delivery hero"],
         .foodDelivery),

        // ── Restaurante / cafenele ───────────────────────────────────────────
        (["mcdonald", "kfc", "burger king", "subway", "pizza",
          "starbucks", "costa coffee", "immensa", "la mama",
          "vivo", "cuptorul", "byblos", "doi bucatari",
          "restaurant", "bistro", "cofetarie", "patiserie",
          "sushi", "shaorma", "kebab", "taco", "dining"],
         .foodDining),

        // ── Alimentare / supermarket ─────────────────────────────────────────
        (["kaufland", "lidl", "aldi", "carrefour", "auchan",
          "penny", "profi", "mega image", "mega-image",
          "selgros", "metro", "cora", "rewe", "spar",
          "supermarket", "hipermarket", "minimarket"],
         .foodGrocery),

        // ── Transport ────────────────────────────────────────────────────────
        (["bolt", "uber", "taxify", "cabify", "lynx",
          "ratt", "stb", "metrou", "ratb", "cfr", "tarom",
          "ryanair", "wizz", "blue air", "parking", "parcare",
          "autostrada", "rovigneta", "e-vigneta", "autobuz",
          "tram", "taxi"],
         .transport),

        // ── Utilități ────────────────────────────────────────────────────────
        (["enel", "electrica", "cez", "eon", "digi",
          "orange", "vodafone", "telekom", "rcs", "rds",
          "romtelecom", "apa nova", "apavital", "engie",
          "distrigaz", "gdf suez", "eelectrica", "termoenergetica",
          "internet", "telefon", "utilities", "utilitat"],
         .utilities),

        // ── Abonamente / streaming ───────────────────────────────────────────
        (["netflix", "spotify", "hbo", "hbo max", "disney",
          "apple one", "apple tv", "apple music", "youtube premium",
          "amazon prime", "dazn", "antena play", "voyo",
          "adobe", "microsoft 365", "office 365", "dropbox",
          "icloud", "google one", "chatgpt", "openai"],
         .subscriptions),

        // ── Cumpărături online ───────────────────────────────────────────────
        (["emag", "altex", "flanco", "mediagalaxy",
          "amazon", "aliexpress", "alibaba", "ebay",
          "fashiondays", "elefant", "pcgarage", "cel.ro",
          "iulius mall", "online", "shop", "store"],
         .shoppingOnline),

        // ── Sănătate (înainte de shopping — sensiblu/catena/farmacia sunt health) ──
        (["farmac", "sensiblu", "catena", "help net", "dr. max",
          "spital", "clinica", "cabinet", "medical", "stomatolog",
          "dentist", "medic", "laborator", "synevo", "regina maria",
          "medicover", "sanador", "mfax"],
         .health),

        // ── Cumpărături offline ──────────────────────────────────────────────
        (["zara", "h&m", "reserved", "pull&bear", "bershka",
          "ikea", "jysk", "leroy merlin", "dedeman",
          "dm drogerie", "magazine", "mall"],
         .shoppingOffline),

        // ── Divertisment ────────────────────────────────────────────────────
        (["cinema", "uci", "cineplex", "multiplex",
          "teatru", "filarmonica", "concert", "bilet",
          "iticket", "eventim", "ticketmaster", "steam",
          "playstation", "xbox", "gaming", "bar", "club",
          "escape room", "bowling"],
         .entertainment),

        // ── Călătorii ────────────────────────────────────────────────────────
        (["booking", "airbnb", "trivago", "hotels.com",
          "expedia", "trip.com", "hotel", "hostel",
          "pensiune", "cazare", "vacanta", "vacanță"],
         .travel),

        // ── IFN / credite IFN ────────────────────────────────────────────────
        (["provident", "cetelem", "brd finance", "rrfsa",
          "credit europe", "tbi bank", "viva credit", "ipf",
          "id finance", "monedo", "cream credit", "cashpot",
          "ok money", "mini credit", "imprumut rapid",
          "ifn", "extra credit"],
         .loansIFN),

        // ── BNPL ─────────────────────────────────────────────────────────────
        (["klarna", "afterpay", "twisto", "pay in", "rate fara",
          "bnpl", "pay later", "instalments"],
         .bnpl),

        // ── Credite bancare ──────────────────────────────────────────────────
        (["rata credit", "rambursare credit", "imprumut",
          "ipoteca", "mortgage", "rate banca", "brd", "bcr",
          "raiffeisen credit", "unicredit credit"],
         .loansBank),

        // ── Economii ─────────────────────────────────────────────────────────
        (["economii", "savings", "depozit", "fond", "investitie",
          "banca transilvania fond", "robor", "depozit termen"],
         .savings),
    ]
}
