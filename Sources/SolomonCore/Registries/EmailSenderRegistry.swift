import Foundation

/// Categoria de business pentru un sender e-mail (spec §8).
public enum EmailSenderCategory: String, Sendable, Hashable, Codable, CaseIterable {
    case bank
    case foodDelivery     = "food_delivery"
    case streaming
    case utility
    case shoppingOnline   = "shopping_online"
    case bnpl
    case ifn
    case travel
    case entertainment
    case transport
    case insurance
}

/// Cât de încredere e match-ul prin doar verificarea sender-ului.
public enum SenderMatchConfidence: String, Sendable, Hashable, Codable {
    /// Sender e match exact pe whitelist.
    case exact   = "high"
    /// Match pe domeniu părinte (ex: subdomain).
    case domain  = "medium"
    /// Sender necunoscut, doar keywords match — necesită confirmare manuală.
    case keyword = "low"
}

/// Înregistrare pentru un sender de e-mail recunoscut.
public struct EmailSender: Sendable, Hashable, Codable, Identifiable {
    public var id: String { sender.lowercased() }
    /// Pattern complet de match (e.g. „no-reply@glovoapp.com").
    public var sender: String
    public var displayName: String
    public var category: EmailSenderCategory
    /// Categoria de tranzacție implicit asociată (Glovo → foodDelivery, etc.).
    public var defaultTransactionCategory: TransactionCategory

    public init(sender: String, displayName: String,
                category: EmailSenderCategory,
                defaultTransactionCategory: TransactionCategory) {
        self.sender = sender
        self.displayName = displayName
        self.category = category
        self.defaultTransactionCategory = defaultTransactionCategory
    }

    public var domain: String {
        sender.split(separator: "@").last.map(String.init)?.lowercased() ?? ""
    }
}

/// Whitelist-ul complet de sender-i e-mail folosit de email parser (spec §8).
public enum EmailSenderRegistry {

    public static let all: [EmailSender] = banks + foodDelivery + streaming
        + utilities + shopping + bnplAndIfn + travel + entertainment
        + transport + insurance

    // MARK: - §8.1 Bănci RO

    public static let banks: [EmailSender] = [
        .init(sender: "notificare@bt.ro",            displayName: "Banca Transilvania",  category: .bank, defaultTransactionCategory: .unknown),
        .init(sender: "no-reply@bcr.ro",             displayName: "BCR (George)",        category: .bank, defaultTransactionCategory: .unknown),
        .init(sender: "notificari@ing.ro",           displayName: "ING Bank",            category: .bank, defaultTransactionCategory: .unknown),
        .init(sender: "e-banking@raiffeisen.ro",     displayName: "Raiffeisen Bank",     category: .bank, defaultTransactionCategory: .unknown),
        .init(sender: "no-reply@revolut.com",        displayName: "Revolut",             category: .bank, defaultTransactionCategory: .unknown),
        .init(sender: "no-reply@cec.ro",             displayName: "CEC Bank",            category: .bank, defaultTransactionCategory: .unknown),
        .init(sender: "e-banking@unicredit.ro",      displayName: "UniCredit Bank",      category: .bank, defaultTransactionCategory: .unknown),
        .init(sender: "notify@patriabank.ro",        displayName: "Patria Bank",         category: .bank, defaultTransactionCategory: .unknown),
        .init(sender: "e-banking@procreditbank.ro",  displayName: "ProCredit",           category: .bank, defaultTransactionCategory: .unknown),
        .init(sender: "notify@libra.ro",             displayName: "Libra Internet Bank", category: .bank, defaultTransactionCategory: .unknown),
        .init(sender: "no-reply@garantibbva.ro",     displayName: "Garanti BBVA",        category: .bank, defaultTransactionCategory: .unknown),
        .init(sender: "e-banking@firstbank.ro",      displayName: "First Bank",          category: .bank, defaultTransactionCategory: .unknown),
        .init(sender: "no-reply@alphabank.ro",       displayName: "Alpha Bank",          category: .bank, defaultTransactionCategory: .unknown),
        .init(sender: "e-banking@otpbank.ro",        displayName: "OTP Bank",            category: .bank, defaultTransactionCategory: .unknown),
        .init(sender: "no-reply@idea-bank.ro",       displayName: "Idea Bank",           category: .bank, defaultTransactionCategory: .unknown)
    ]

    // MARK: - §8.2 Food delivery

    public static let foodDelivery: [EmailSender] = [
        .init(sender: "no-reply@glovoapp.com",       displayName: "Glovo",     category: .foodDelivery, defaultTransactionCategory: .foodDelivery),
        .init(sender: "help@wolt.com",               displayName: "Wolt",      category: .foodDelivery, defaultTransactionCategory: .foodDelivery),
        .init(sender: "no-reply@tazz.ro",            displayName: "Tazz",      category: .foodDelivery, defaultTransactionCategory: .foodDelivery),
        .init(sender: "no-reply@boltfood.com",       displayName: "Bolt Food", category: .foodDelivery, defaultTransactionCategory: .foodDelivery),
        .init(sender: "no-reply@foodpanda.com",      displayName: "Foodpanda", category: .foodDelivery, defaultTransactionCategory: .foodDelivery)
    ]

    // MARK: - §8.3 Streaming și abonamente digitale

    public static let streaming: [EmailSender] = [
        .init(sender: "info@account.netflix.com",    displayName: "Netflix",          category: .streaming, defaultTransactionCategory: .subscriptions),
        .init(sender: "no-reply@email.hbomax.com",   displayName: "HBO Max",          category: .streaming, defaultTransactionCategory: .subscriptions),
        .init(sender: "no-reply@spotify.com",        displayName: "Spotify",          category: .streaming, defaultTransactionCategory: .subscriptions),
        .init(sender: "no-reply@apple.com",          displayName: "Apple Services",   category: .streaming, defaultTransactionCategory: .subscriptions),
        .init(sender: "no-reply@youtube.com",        displayName: "YouTube Premium",  category: .streaming, defaultTransactionCategory: .subscriptions),
        .init(sender: "billing@disneyplus.com",      displayName: "Disney+",          category: .streaming, defaultTransactionCategory: .subscriptions),
        .init(sender: "no-reply@github.com",         displayName: "GitHub",           category: .streaming, defaultTransactionCategory: .subscriptions),
        .init(sender: "mail@adobe.com",              displayName: "Adobe Creative Cloud", category: .streaming, defaultTransactionCategory: .subscriptions),
        .init(sender: "no-reply@dropbox.com",        displayName: "Dropbox",          category: .streaming, defaultTransactionCategory: .subscriptions),
        .init(sender: "billing@1password.com",       displayName: "1Password",        category: .streaming, defaultTransactionCategory: .subscriptions),
        .init(sender: "no-reply@figma.com",          displayName: "Figma",            category: .streaming, defaultTransactionCategory: .subscriptions),
        .init(sender: "no-reply@notion.so",          displayName: "Notion",           category: .streaming, defaultTransactionCategory: .subscriptions),
        .init(sender: "no-reply@calm.com",           displayName: "Calm",             category: .streaming, defaultTransactionCategory: .subscriptions),
        .init(sender: "no-reply@headspace.com",      displayName: "Headspace",        category: .streaming, defaultTransactionCategory: .subscriptions),
        .init(sender: "no-reply@duolingo.com",       displayName: "Duolingo",         category: .streaming, defaultTransactionCategory: .subscriptions)
    ]

    // MARK: - §8.4 Utilități RO

    public static let utilities: [EmailSender] = [
        .init(sender: "contact@enel.ro",                       displayName: "Enel",                  category: .utility, defaultTransactionCategory: .utilities),
        .init(sender: "office@digi.ro",                        displayName: "Digi",                  category: .utility, defaultTransactionCategory: .utilities),
        .init(sender: "clientservice@rcs-rds.ro",              displayName: "RCS-RDS",               category: .utility, defaultTransactionCategory: .utilities),
        .init(sender: "help@orange.ro",                        displayName: "Orange",                category: .utility, defaultTransactionCategory: .utilities),
        .init(sender: "contact@vodafone.ro",                   displayName: "Vodafone",              category: .utility, defaultTransactionCategory: .utilities),
        .init(sender: "servicii@telekom.ro",                   displayName: "Telekom",               category: .utility, defaultTransactionCategory: .utilities),
        .init(sender: "clienti@engie.ro",                      displayName: "Engie",                 category: .utility, defaultTransactionCategory: .utilities),
        .init(sender: "contact@e-on.ro",                       displayName: "E.ON",                  category: .utility, defaultTransactionCategory: .utilities),
        .init(sender: "clienti@apanovabucuresti.ro",           displayName: "Apa Nova București",    category: .utility, defaultTransactionCategory: .utilities),
        .init(sender: "clienti@distributiegazenaturale.ro",    displayName: "Distrigaz",             category: .utility, defaultTransactionCategory: .utilities)
    ]

    // MARK: - §8.5 Shopping online

    public static let shopping: [EmailSender] = [
        .init(sender: "no-reply@emag.ro",            displayName: "eMAG",            category: .shoppingOnline, defaultTransactionCategory: .shoppingOnline),
        .init(sender: "no-reply@altex.ro",           displayName: "Altex",           category: .shoppingOnline, defaultTransactionCategory: .shoppingOnline),
        .init(sender: "no-reply@flanco.ro",          displayName: "Flanco",          category: .shoppingOnline, defaultTransactionCategory: .shoppingOnline),
        .init(sender: "no-reply@elefant.ro",         displayName: "Elefant",         category: .shoppingOnline, defaultTransactionCategory: .shoppingOnline),
        .init(sender: "no-reply@bookuriste.ro",      displayName: "Bookurile",       category: .shoppingOnline, defaultTransactionCategory: .shoppingOnline),
        .init(sender: "no-reply@sephora.ro",         displayName: "Sephora",         category: .shoppingOnline, defaultTransactionCategory: .shoppingOnline),
        .init(sender: "no-reply@douglas.ro",         displayName: "Douglas",         category: .shoppingOnline, defaultTransactionCategory: .shoppingOnline),
        .init(sender: "no-reply@h-and-m.com",        displayName: "H&M",             category: .shoppingOnline, defaultTransactionCategory: .shoppingOnline),
        .init(sender: "no-reply@zalando.com",        displayName: "Zalando",         category: .shoppingOnline, defaultTransactionCategory: .shoppingOnline),
        .init(sender: "no-reply@aboutyou.ro",        displayName: "About You",       category: .shoppingOnline, defaultTransactionCategory: .shoppingOnline),
        .init(sender: "no-reply@fashiondays.ro",     displayName: "Fashion Days",    category: .shoppingOnline, defaultTransactionCategory: .shoppingOnline),
        .init(sender: "no-reply@decathlon.ro",       displayName: "Decathlon",       category: .shoppingOnline, defaultTransactionCategory: .shoppingOnline),
        .init(sender: "no-reply@dedeman.ro",         displayName: "Dedeman",         category: .shoppingOnline, defaultTransactionCategory: .shoppingOnline),
        .init(sender: "no-reply@ikea.ro",            displayName: "IKEA",            category: .shoppingOnline, defaultTransactionCategory: .shoppingOnline),
        .init(sender: "no-reply@auchan.ro",          displayName: "Auchan online",   category: .shoppingOnline, defaultTransactionCategory: .foodGrocery),
        .init(sender: "no-reply@kaufland.ro",        displayName: "Kaufland online", category: .shoppingOnline, defaultTransactionCategory: .foodGrocery),
        .init(sender: "no-reply@carrefour.ro",       displayName: "Carrefour online",category: .shoppingOnline, defaultTransactionCategory: .foodGrocery)
    ]

    // MARK: - §8.6 BNPL și IFN

    public static let bnplAndIfn: [EmailSender] = [
        .init(sender: "hello@mokka.ro",              displayName: "Mokka",        category: .bnpl, defaultTransactionCategory: .bnpl),
        .init(sender: "no-reply@tbi.ro",             displayName: "TBI Bank",     category: .bnpl, defaultTransactionCategory: .bnpl),
        .init(sender: "support@paypo.ro",            displayName: "PayPo",        category: .bnpl, defaultTransactionCategory: .bnpl),
        .init(sender: "support@klarna.com",          displayName: "Klarna",       category: .bnpl, defaultTransactionCategory: .bnpl),
        .init(sender: "hello@felice.ro",             displayName: "Felice",       category: .bnpl, defaultTransactionCategory: .bnpl),

        .init(sender: "no-reply@credius.ro",         displayName: "Credius",      category: .ifn, defaultTransactionCategory: .loansIFN),
        .init(sender: "office@providentromania.ro",  displayName: "Provident",    category: .ifn, defaultTransactionCategory: .loansIFN),
        .init(sender: "no-reply@iutecredit.ro",      displayName: "IUTE Credit",  category: .ifn, defaultTransactionCategory: .loansIFN),
        .init(sender: "contact@vivacredit.ro",       displayName: "Viva Credit",  category: .ifn, defaultTransactionCategory: .loansIFN),
        .init(sender: "contact@horacredit.ro",       displayName: "Hora Credit",  category: .ifn, defaultTransactionCategory: .loansIFN),
        .init(sender: "suport@maimaicredit.ro",      displayName: "MaiMai Credit",category: .ifn, defaultTransactionCategory: .loansIFN),
        .init(sender: "contact@acredit.ro",          displayName: "Acredit",      category: .ifn, defaultTransactionCategory: .loansIFN),
        .init(sender: "support@ferratum.ro",         displayName: "Ferratum",     category: .ifn, defaultTransactionCategory: .loansIFN),
        .init(sender: "support@cetelem.ro",          displayName: "Cetelem",      category: .ifn, defaultTransactionCategory: .loansIFN)
    ]

    // MARK: - §8.7 Travel

    public static let travel: [EmailSender] = [
        .init(sender: "no-reply@booking.com",          displayName: "Booking.com",     category: .travel, defaultTransactionCategory: .travel),
        .init(sender: "automated@airbnb.com",          displayName: "Airbnb",          category: .travel, defaultTransactionCategory: .travel),
        .init(sender: "no-reply@esky.ro",              displayName: "eSky",            category: .travel, defaultTransactionCategory: .travel),
        .init(sender: "no-reply@vola.ro",              displayName: "Vola.ro",         category: .travel, defaultTransactionCategory: .travel),
        .init(sender: "flightcenter@kiwi.com",         displayName: "Kiwi.com",        category: .travel, defaultTransactionCategory: .travel),
        .init(sender: "no-reply@tarom.ro",             displayName: "TAROM",           category: .travel, defaultTransactionCategory: .travel),
        .init(sender: "booking@blueair.aero",          displayName: "Blue Air",        category: .travel, defaultTransactionCategory: .travel),
        .init(sender: "no-reply@wizzair.com",          displayName: "Wizz Air",        category: .travel, defaultTransactionCategory: .travel),
        .init(sender: "no-reply@ryanair.com",          displayName: "Ryanair",         category: .travel, defaultTransactionCategory: .travel),
        .init(sender: "contact@christiantour.ro",      displayName: "Christian Tour",  category: .travel, defaultTransactionCategory: .travel),
        .init(sender: "contact@paraleladu.ro",         displayName: "Paralela 45",     category: .travel, defaultTransactionCategory: .travel)
    ]

    // MARK: - §8.8 Entertainment

    public static let entertainment: [EmailSender] = [
        .init(sender: "no-reply@eventim.ro",         displayName: "Eventim",          category: .entertainment, defaultTransactionCategory: .entertainment),
        .init(sender: "contact@iabilet.ro",          displayName: "iaBilet",          category: .entertainment, defaultTransactionCategory: .entertainment),
        .init(sender: "hello@bilet.ro",              displayName: "Bilet.ro",         category: .entertainment, defaultTransactionCategory: .entertainment),
        .init(sender: "support@untold.com",          displayName: "UNTOLD",           category: .entertainment, defaultTransactionCategory: .entertainment),
        .init(sender: "hello@electriccastle.ro",     displayName: "Electric Castle",  category: .entertainment, defaultTransactionCategory: .entertainment)
    ]

    // MARK: - §8.9 Transport

    public static let transport: [EmailSender] = [
        .init(sender: "no-reply@bolt.eu",            displayName: "Bolt",       category: .transport, defaultTransactionCategory: .transport),
        .init(sender: "no-reply@uber.com",           displayName: "Uber",       category: .transport, defaultTransactionCategory: .transport),
        .init(sender: "no-reply@yango.com",          displayName: "Yango",      category: .transport, defaultTransactionCategory: .transport),
        .init(sender: "contact@stb.ro",              displayName: "STB",        category: .transport, defaultTransactionCategory: .transport),
        .init(sender: "no-reply@cfr-calatori.ro",    displayName: "CFR Călători",category: .transport, defaultTransactionCategory: .transport),
        .init(sender: "contact@blablacar.com",       displayName: "BlaBlaCar",  category: .transport, defaultTransactionCategory: .transport),
        .init(sender: "hello@taxify.eu",             displayName: "Taxify",     category: .transport, defaultTransactionCategory: .transport)
    ]

    // MARK: - §8.10 Asigurări

    public static let insurance: [EmailSender] = [
        .init(sender: "contact@allianz.ro",          displayName: "Allianz",        category: .insurance, defaultTransactionCategory: .health),
        .init(sender: "contact@asirom.ro",           displayName: "Asirom",         category: .insurance, defaultTransactionCategory: .health),
        .init(sender: "clienti@groupama.ro",         displayName: "Groupama",       category: .insurance, defaultTransactionCategory: .health),
        .init(sender: "contact@nn.ro",               displayName: "NN Asigurări",   category: .insurance, defaultTransactionCategory: .health),
        .init(sender: "clienti@omniasig.ro",         displayName: "Omniasig",       category: .insurance, defaultTransactionCategory: .health),
        .init(sender: "contact@uniqa.ro",            displayName: "Uniqa",          category: .insurance, defaultTransactionCategory: .health)
    ]

    // MARK: - Lookup

    /// Caută match exact pe sender (case insensitive).
    public static func sender(matching sender: String) -> EmailSender? {
        let normalized = sender.lowercased()
        return all.first { $0.sender.lowercased() == normalized }
    }

    /// Caută cel mai bun match pentru un sender. Întâi exact, apoi prin domeniu părinte.
    public static func match(for senderEmail: String) -> (EmailSender, SenderMatchConfidence)? {
        let normalized = senderEmail.lowercased()
        if let exact = sender(matching: normalized) {
            return (exact, .exact)
        }
        guard let domain = normalized.split(separator: "@").last.map(String.init) else { return nil }
        if let byDomain = all.first(where: { $0.domain == domain }) {
            return (byDomain, .domain)
        }
        // Match doar pe domeniul părinte (ex: subdomain.bcr.ro → bcr.ro).
        let parts = domain.split(separator: ".")
        guard parts.count >= 2 else { return nil }
        let parentDomain = parts.suffix(2).joined(separator: ".")
        if let byParent = all.first(where: { $0.domain == parentDomain }) {
            return (byParent, .domain)
        }
        return nil
    }

    /// Toate senderii dintr-o categorie dată.
    public static func senders(in category: EmailSenderCategory) -> [EmailSender] {
        all.filter { $0.category == category }
    }
}
