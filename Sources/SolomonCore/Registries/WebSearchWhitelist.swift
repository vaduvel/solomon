import Foundation

/// Categoria unei surse web care apare în whitelist (spec §9).
public enum WebSourceCategory: String, Sendable, Hashable, Codable, CaseIterable {
    case official       // BNR, ANAF, ASF, ANPC, MS, CSALB
    case comparator     // conso.ro, finzoom etc.
    case news
    case education
}

/// Cât de multă încredere acordăm răspunsurilor scrape-uite din această sursă.
public enum WebTrustLevel: String, Sendable, Hashable, Codable, Comparable {
    case low, medium, high

    private var rank: Int {
        switch self {
        case .low: return 0
        case .medium: return 1
        case .high: return 2
        }
    }
    public static func < (lhs: WebTrustLevel, rhs: WebTrustLevel) -> Bool { lhs.rank < rhs.rank }
}

/// Durata implicită de cache pentru o sursă, în secunde (spec §9.5).
public struct WebCachePolicy: Sendable, Hashable, Codable {
    public var seconds: Int

    public init(seconds: Int) { self.seconds = seconds }

    public static let oneHour       = WebCachePolicy(seconds: 60 * 60)
    public static let sixHours      = WebCachePolicy(seconds: 6 * 60 * 60)
    public static let twentyFourH   = WebCachePolicy(seconds: 24 * 60 * 60)
    public static let sevenDays     = WebCachePolicy(seconds: 7 * 24 * 60 * 60)
}

/// Înregistrare pentru un domeniu permis în Solomon Web (spec §9).
public struct WhitelistedDomain: Sendable, Hashable, Codable, Identifiable {
    public var id: String { host }
    public var host: String
    public var displayName: String
    public var category: WebSourceCategory
    public var trustLevel: WebTrustLevel
    public var defaultCachePolicy: WebCachePolicy
    public var topicTags: [String]

    public init(host: String, displayName: String, category: WebSourceCategory,
                trustLevel: WebTrustLevel, defaultCachePolicy: WebCachePolicy,
                topicTags: [String] = []) {
        self.host = host
        self.displayName = displayName
        self.category = category
        self.trustLevel = trustLevel
        self.defaultCachePolicy = defaultCachePolicy
        self.topicTags = topicTags
    }
}

/// Whitelist-ul de domenii pe care Solomon le poate scrape-ui (spec §9).
public enum WebSearchWhitelist {

    public static let all: [WhitelistedDomain] = official + comparators + news + education

    // MARK: - §9.1 Surse oficiale

    public static let official: [WhitelistedDomain] = [
        .init(host: "bnr.ro",          displayName: "Banca Națională a României",
              category: .official, trustLevel: .high, defaultCachePolicy: .sixHours,
              topicTags: ["curs_valutar", "dobanzi_referinta"]),
        .init(host: "anaf.gov.ro",     displayName: "ANAF",
              category: .official, trustLevel: .high, defaultCachePolicy: .twentyFourH,
              topicTags: ["impozite", "deduceri", "e_factura"]),
        .init(host: "asf.ro",          displayName: "ASF",
              category: .official, trustLevel: .high, defaultCachePolicy: .oneHour,
              topicTags: ["scam_alerts", "investitii"]),
        .init(host: "anpc.ro",         displayName: "ANPC",
              category: .official, trustLevel: .high, defaultCachePolicy: .oneHour,
              topicTags: ["scam_alerts", "drepturi_consumator"]),
        .init(host: "ms.ro",           displayName: "Ministerul Sănătății",
              category: .official, trustLevel: .high, defaultCachePolicy: .twentyFourH,
              topicTags: ["deduceri_sanatate"]),
        .init(host: "ec.europa.eu",    displayName: "EURES",
              category: .official, trustLevel: .high, defaultCachePolicy: .twentyFourH,
              topicTags: ["munca_ue"]),
        .init(host: "csalb.ro",        displayName: "CSALB",
              category: .official, trustLevel: .high, defaultCachePolicy: .twentyFourH,
              topicTags: ["mediere_bancara"])
    ]

    // MARK: - §9.2 Comparații financiare

    public static let comparators: [WhitelistedDomain] = [
        .init(host: "conso.ro",        displayName: "Conso",            category: .comparator, trustLevel: .medium, defaultCachePolicy: .twentyFourH, topicTags: ["depozite", "credite", "carduri"]),
        .init(host: "finzoom.ro",      displayName: "FinZoom",          category: .comparator, trustLevel: .medium, defaultCachePolicy: .twentyFourH, topicTags: ["credite"]),
        .init(host: "creditede.ro",    displayName: "CreditedeRomânia", category: .comparator, trustLevel: .medium, defaultCachePolicy: .twentyFourH, topicTags: ["credite"]),
        .init(host: "cumparcasa.ro",   displayName: "CumpărCasa",       category: .comparator, trustLevel: .medium, defaultCachePolicy: .twentyFourH, topicTags: ["imobiliar"]),
        .init(host: "ratemyrate.ro",   displayName: "Rate My Rate",     category: .comparator, trustLevel: .medium, defaultCachePolicy: .twentyFourH, topicTags: ["depozite"])
    ]

    // MARK: - §9.3 Știri financiare RO

    public static let news: [WhitelistedDomain] = [
        .init(host: "zf.ro",           displayName: "Ziarul Financiar", category: .news, trustLevel: .medium, defaultCachePolicy: .sevenDays, topicTags: ["stiri_economie"]),
        .init(host: "profit.ro",       displayName: "Profit.ro",        category: .news, trustLevel: .medium, defaultCachePolicy: .sevenDays, topicTags: ["stiri_economie"]),
        .init(host: "economica.net",   displayName: "Economica.net",    category: .news, trustLevel: .medium, defaultCachePolicy: .sevenDays, topicTags: ["stiri_economie"]),
        .init(host: "bursa.ro",        displayName: "Bursa",            category: .news, trustLevel: .medium, defaultCachePolicy: .sevenDays, topicTags: ["stiri_economie", "burse"]),
        .init(host: "hotnews.ro",      displayName: "HotNews Economie", category: .news, trustLevel: .medium, defaultCachePolicy: .sevenDays, topicTags: ["stiri_economie"])
    ]

    // MARK: - §9.4 Educație financiară

    public static let education: [WhitelistedDomain] = [
        .init(host: "iancuguda.ro",            displayName: "Iancu Guda",         category: .education, trustLevel: .medium, defaultCachePolicy: .sevenDays, topicTags: ["educatie"]),
        .init(host: "moneymag.ro",             displayName: "Money.ro",           category: .education, trustLevel: .medium, defaultCachePolicy: .sevenDays, topicTags: ["educatie"]),
        .init(host: "finantepersonale.ro",     displayName: "Finanțe Personale",  category: .education, trustLevel: .medium, defaultCachePolicy: .sevenDays, topicTags: ["educatie"]),
        .init(host: "educatiefinanciara.ro",   displayName: "Educație Financiară",category: .education, trustLevel: .medium, defaultCachePolicy: .sevenDays, topicTags: ["educatie"])
    ]

    // MARK: - Lookup

    public static func entry(forHost host: String) -> WhitelistedDomain? {
        let normalized = host.lowercased()
        return all.first { $0.host == normalized }
    }

    /// Verifică dacă un URL are host-ul în whitelist (sau un subdomeniu al unei intrări).
    public static func isAllowed(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        if all.contains(where: { $0.host == host }) { return true }
        return all.contains(where: { host.hasSuffix("." + $0.host) })
    }

    public static func entries(for category: WebSourceCategory) -> [WhitelistedDomain] {
        all.filter { $0.category == category }
    }
}
