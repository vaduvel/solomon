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
          "just eat", "wolt", "uber eat", "delivery hero",
          "tazz.ro", "wolt.com", "tasty", "delivery rapid"],
         .foodDelivery),

        // ── Restaurante / cafenele ───────────────────────────────────────────
        (["mcdonald", "kfc", "burger king", "subway", "pizza",
          "starbucks", "costa coffee", "immensa", "la mama",
          "vivo", "cuptorul", "byblos", "doi bucatari", "barlife",
          "restaurant", "bistro", "cofetarie", "patiserie", "covrigarie",
          "sushi", "shaorma", "kebab", "taco", "dining",
          "ted's coffee", "5 to go", "trattoria", "casa di david",
          "city grill", "mado", "il calcio", "linea", "anna",
          "brutaria", "donut", "cheese", "shaormeria"],
         .foodDining),

        // ── Alimentare / supermarket ─────────────────────────────────────────
        (["kaufland", "lidl", "aldi", "carrefour", "auchan",
          "penny", "profi", "mega image", "mega-image",
          "selgros", "metro", "cora", "rewe", "spar",
          "supermarket", "hipermarket", "minimarket",
          "mac express", "shop&go", "diana", "annabella",
          "macroplaza", "piata"],
         .foodGrocery),

        // ── Transport ────────────────────────────────────────────────────────
        (["bolt", "uber", "taxify", "cabify", "lynx",
          "ratt", "stb", "metrou", "ratb", "cfr", "tarom",
          "ryanair", "wizz", "blue air", "lufthansa", "klm",
          "parking", "parcare", "smart parking", "speedy parking",
          "autostrada", "rovigneta", "e-vigneta", "autobuz",
          "tram", "taxi", "petrom", "omv", "mol", "rompetrol",
          "lukoil", "socar", "shell", "carburanti", "benzinarie",
          "gpl", "carbur"],
         .transport),

        // ── Utilități ────────────────────────────────────────────────────────
        (["enel", "electrica", "cez", "eon", "digi",
          "orange", "vodafone", "telekom", "rcs", "rds",
          "romtelecom", "apa nova", "apavital", "engie",
          "distrigaz", "gdf suez", "eelectrica", "termoenergetica",
          "internet", "telefon", "utilities", "utilitat",
          "rebu", "sigurnet", "salubritate", "compania apa",
          "raja", "deltaroum", "factura energie", "factura gaz"],
         .utilities),

        // ── Abonamente / streaming ───────────────────────────────────────────
        (["netflix", "spotify", "hbo", "hbo max", "disney",
          "apple one", "apple tv", "apple music", "youtube premium",
          "amazon prime", "dazn", "antena play", "voyo",
          "adobe", "microsoft 365", "office 365", "dropbox",
          "icloud", "google one", "chatgpt", "openai",
          "claude.ai", "anthropic", "github", "linkedin premium",
          "duolingo", "headspace", "calm", "1password",
          "nordvpn", "expressvpn", "surfshark", "apple arcade",
          "playstation plus", "xbox game pass", "patreon", "substack",
          "audible", "kindle unlimited", "elementor", "canva",
          "figma", "miro", "notion", "todoist", "evernote"],
         .subscriptions),

        // ── Cumpărături online ───────────────────────────────────────────────
        (["emag", "altex", "flanco", "mediagalaxy",
          "amazon", "aliexpress", "alibaba", "ebay",
          "fashiondays", "elefant", "pcgarage", "cel.ro",
          "iulius mall", "online", "shop", "store",
          "vivre", "answear", "factory", "footshop", "asos",
          "zalando", "evomag", "bookurile", "libris", "carturesti.ro",
          "olx", "olx.ro", "vinted", "shopee", "temu"],
         .shoppingOnline),

        // ── Sănătate (înainte de shopping — sensiblu/catena/farmacia sunt health) ──
        (["farmac", "sensiblu", "catena", "help net", "dr. max",
          "spital", "clinica", "cabinet", "medical", "stomatolog",
          "dentist", "medic", "laborator", "synevo", "regina maria",
          "medicover", "sanador", "mfax", "medlife", "ovidius",
          "policlinica", "ginecologie", "pediatru", "oftalmolog",
          "kinetoterapie", "fizio", "psiho", "terapie",
          "dona", "remedia", "amalia", "tei", "ardealul"],
         .health),

        // ── Cumpărături offline ──────────────────────────────────────────────
        (["zara", "h&m", "reserved", "pull&bear", "bershka",
          "ikea", "jysk", "leroy merlin", "dedeman",
          "dm drogerie", "magazine", "mall",
          "decathlon", "intersport", "sportmaster", "nike", "adidas",
          "stradivarius", "massimo dutti", "uniqlo", "c&a",
          "tezyo", "ccc", "deichmann", "humanic", "ten gallon",
          "praktiker", "brico depot", "hornbach", "auchan brico",
          "douglas", "marionnaud", "yves rocher", "lush"],
         .shoppingOffline),

        // ── Divertisment ────────────────────────────────────────────────────
        (["cinema", "uci", "cineplex", "multiplex",
          "teatru", "filarmonica", "concert", "bilet",
          "iticket", "eventim", "ticketmaster", "steam",
          "playstation", "xbox", "gaming", "bar", "club",
          "escape room", "bowling", "operetta", "opera",
          "revolution", "club a", "expirat", "kristal",
          "vama veche", "muzeu", "expozitie", "festival",
          "untold", "neversea", "afterhills", "summer well",
          "nintendo", "epic games", "humble bundle"],
         .entertainment),

        // ── Călătorii ────────────────────────────────────────────────────────
        (["booking", "airbnb", "trivago", "hotels.com",
          "expedia", "trip.com", "hotel", "hostel",
          "pensiune", "cazare", "vacanta", "vacanță",
          "litoral", "saturn", "mamaia", "eforie", "constanta turism",
          "bran", "predeal", "sinaia", "poiana brasov", "brasov hotel"],
         .travel),

        // ── IFN / credite IFN ────────────────────────────────────────────────
        (["provident", "cetelem", "brd finance", "rrfsa",
          "credit europe", "tbi bank", "viva credit", "ipf",
          "id finance", "monedo", "cream credit", "cashpot",
          "ok money", "mini credit", "imprumut rapid",
          "ifn", "extra credit", "iute credit", "credius",
          "hora credit", "viva", "axi card", "creditplus",
          "ferratum", "moneyman", "vivus", "easycredit",
          "sukidi", "credit24", "credius ifn"],
         .loansIFN),

        // ── BNPL ─────────────────────────────────────────────────────────────
        (["klarna", "afterpay", "twisto", "pay in", "rate fara",
          "bnpl", "pay later", "instalments",
          "alma", "paypo", "scalapay", "splitit", "zilch",
          "tbi pay", "rate online", "cash to go"],
         .bnpl),

        // ── Credite bancare ──────────────────────────────────────────────────
        (["rata credit", "rambursare credit", "imprumut",
          "ipoteca", "mortgage", "rate banca", "brd ", " bcr ",
          "raiffeisen credit", "unicredit credit", "transilvania credit",
          "first bank credit", "alpha bank credit", "ing credit",
          "patria bank credit", "garanti credit"],
         .loansBank),

        // ── Economii ─────────────────────────────────────────────────────────
        (["economii", "savings", "depozit", "fond", "investitie",
          "banca transilvania fond", "robor", "depozit termen",
          "etf", "raiffeisen invest", "ngam", "btim", "blackrock",
          "vanguard", "binance earn", "trezor"],
         .savings),
    ]
}
