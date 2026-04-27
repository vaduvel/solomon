import Foundation

/// Severitatea unui pattern de scam.
public enum ScamSeverity: String, Sendable, Hashable, Codable, Comparable {
    case suspicious     // worth flagging, but not certain
    case likelyScam     = "likely_scam"
    case definiteScam   = "definite_scam"

    private var rank: Int {
        switch self {
        case .suspicious:   return 0
        case .likelyScam:   return 1
        case .definiteScam: return 2
        }
    }
    public static func < (lhs: ScamSeverity, rhs: ScamSeverity) -> Bool { lhs.rank < rhs.rank }
}

/// Categoria de scam — pentru triere și răspunsuri specifice.
public enum ScamCategory: String, Sendable, Hashable, Codable {
    case investmentReturn   = "investment_return"     // randament garantat astronomic
    case crypto             = "crypto"                 // crypto cu garanții
    case forex              = "forex"                  // forex nereglementat în RO
    case pyramidScheme      = "pyramid_scheme"
    case phishingFinancial  = "phishing_financial"     // SMS/email mascat ca bancă
    case investmentImpersonation = "investment_impersonation" // platforme false ASF/BNR
    case loanFee            = "loan_fee"               // „taxă procesare" în avans
    case lottery            = "lottery"
    case romance            = "romance"
}

/// Un pattern de scam recunoscut, cu indicii lingvistice și răspuns recomandat.
public struct ScamPattern: Sendable, Hashable, Codable, Identifiable {
    public var id: String { code }
    public var code: String
    public var category: ScamCategory
    public var severity: ScamSeverity
    /// Cuvinte cheie indicative (lowercase, fără diacritice). Match e substring.
    public var keywords: [String]
    /// Frază model care explică user-ului în RO de ce e scam.
    public var explanation: String
    /// Acțiune recomandată: ce să facă user-ul.
    public var recommendation: String
    /// Sursă oficială (ASF, ANPC) la care să trimitem pentru confirmare.
    public var officialReference: String?

    public init(code: String, category: ScamCategory, severity: ScamSeverity,
                keywords: [String], explanation: String, recommendation: String,
                officialReference: String? = nil) {
        self.code = code
        self.category = category
        self.severity = severity
        self.keywords = keywords
        self.explanation = explanation
        self.recommendation = recommendation
        self.officialReference = officialReference
    }
}

/// Catalogul de pattern-uri de scam recunoscute pe piața RO (spec §10.4).
///
/// Sursa: avertismente ASF/ANPC publicate 2023-2026 + observație empirică Daniel.
/// Lista e *draft de start* — se actualizează când apar avertismente noi.
public enum ScamPatterns {

    public static let all: [ScamPattern] = [
        ScamPattern(
            code: "high_yield_2pct_monthly",
            category: .investmentReturn, severity: .definiteScam,
            keywords: [
                "2% pe luna", "2% lunar", "2% pe lună",
                "5% pe luna", "10% pe luna",
                "garantat", "randament garantat", "profit garantat",
                "fara risc"
            ],
            explanation: "Niciun produs de investiții reglementat nu garantează randament peste 1%/lună fără risc. Promisiunile de 2%+/lună 'garantat' sunt schemă piramidală sau scam direct.",
            recommendation: "Nu plăti nimic. Verifică pe asf.ro dacă platforma e autorizată în RO.",
            officialReference: "https://asf.ro/avertismente"
        ),
        ScamPattern(
            code: "investment_500_to_5000_30days",
            category: .investmentReturn, severity: .definiteScam,
            keywords: [
                "investeste 500", "primesti 5000",
                "în 30 de zile", "in 30 zile",
                "x10 in 30"
            ],
            explanation: "'Investește 500€, primești 5000€ în 30 zile' e formula clasică de scam crypto/forex.",
            recommendation: "Ignoră. Nu trimite niciun ban.",
            officialReference: "https://asf.ro/avertismente"
        ),
        ScamPattern(
            code: "crypto_guaranteed",
            category: .crypto, severity: .likelyScam,
            keywords: [
                "crypto garantat", "bitcoin garantat", "investitie cripto sigura",
                "robot trading crypto"
            ],
            explanation: "Crypto-ul e volatil prin definiție; nimeni nu poate garanta randament.",
            recommendation: "Verifică dacă platforma e listată pe asf.ro înainte de orice contribuție.",
            officialReference: "https://asf.ro/avertismente"
        ),
        ScamPattern(
            code: "forex_unregulated_ro",
            category: .forex, severity: .likelyScam,
            keywords: [
                "forex automat", "trading semnale gratuit",
                "broker forex", "expert advisor garantat"
            ],
            explanation: "Brokerii Forex care operează în RO trebuie autorizați ASF. Multe platforme reclamate sunt offshore.",
            recommendation: "Caută broker-ul pe asf.ro/registru-public. Dacă nu apare, evită.",
            officialReference: "https://asf.ro/registru"
        ),
        ScamPattern(
            code: "loan_fee_advance",
            category: .loanFee, severity: .definiteScam,
            keywords: [
                "taxa procesare in avans", "depune o taxa",
                "100 lei procesare credit", "comision in avans pentru credit",
                "transfera 50 lei pentru aprobare"
            ],
            explanation: "Niciun creditor legal nu îți cere taxă de procesare *înainte* de aprobare/disbursement.",
            recommendation: "Nu plăti nimic în avans. Raportează la ANPC.",
            officialReference: "https://anpc.ro"
        ),
        ScamPattern(
            code: "phishing_bank_link",
            category: .phishingFinancial, severity: .likelyScam,
            keywords: [
                "contul tau a fost suspendat", "click pentru a verifica contul",
                "actualizeaza datele bancare imediat",
                "verifica acum cardul"
            ],
            explanation: "Băncile RO nu cer niciodată actualizare credențiale prin link în e-mail / SMS.",
            recommendation: "Nu da click. Loghează-te direct prin app-ul oficial al băncii.",
            officialReference: "https://anpc.ro"
        ),
        ScamPattern(
            code: "impersonation_asf_bnr",
            category: .investmentImpersonation, severity: .definiteScam,
            keywords: [
                "platforma autorizata asf",   // false claim
                "investitie aprobata bnr",
                "garantat de stat",
                "fond de investitii bnr"
            ],
            explanation: "ASF și BNR nu autorizează / garantează platforme private de investiții individuale.",
            recommendation: "Verifică direct pe asf.ro și bnr.ro. Dacă nu apare, e impersonare.",
            officialReference: "https://asf.ro"
        ),
        ScamPattern(
            code: "pyramid_recruitment",
            category: .pyramidScheme, severity: .likelyScam,
            keywords: [
                "aduci 3 prieteni", "comision daca recrutezi",
                "matrix marketing", "schema 1+2+4+8",
                "venit pasiv recrutare"
            ],
            explanation: "Câștigurile bazate pe recrutare > pe vânzare reală sunt schemă piramidală.",
            recommendation: "Schemele piramidale sunt ilegale în RO. Raportează la ANPC.",
            officialReference: "https://anpc.ro"
        ),
        ScamPattern(
            code: "lottery_unsolicited",
            category: .lottery, severity: .definiteScam,
            keywords: [
                "ai castigat la loterie",
                "premiu de 1.000.000",
                "trimite date pentru a primi premiul",
                "tax for prize"
            ],
            explanation: "Nu ai jucat → nu ai cum să câștigi. Cer o 'taxă' ca să te storcă.",
            recommendation: "Șterge mesajul. Nu răspunde.",
            officialReference: nil
        ),
        ScamPattern(
            code: "romance_money_request",
            category: .romance, severity: .likelyScam,
            keywords: [
                "trimite-mi bani urgent", "am o urgenta medicala",
                "blocat in alta tara", "trimite la western union",
                "ridica un colet pentru mine"
            ],
            explanation: "Cererile de bani de la persoane cunoscute online (mai ales după scurt timp) sunt scam clasic.",
            recommendation: "Nu trimite bani. Verifică prin alte canale dacă persoana e reală.",
            officialReference: nil
        )
    ]

    /// Caută cea mai puternică potrivire pentru un text dat. Returnează `nil` dacă nu găsește.
    public static func match(in text: String) -> ScamPattern? {
        let lowered = text.lowercased().folding(options: .diacriticInsensitive, locale: nil)
        var best: ScamPattern?
        for pattern in all {
            for keyword in pattern.keywords where lowered.contains(keyword) {
                if best == nil || pattern.severity > (best?.severity ?? .suspicious) {
                    best = pattern
                }
                break
            }
        }
        return best
    }

    public static func patterns(in category: ScamCategory) -> [ScamPattern] {
        all.filter { $0.category == category }
    }
}
