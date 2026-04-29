import Testing
import Foundation
@testable import SolomonCore

// MARK: - BankNotificationParserTests
//
// Acoperire completă pentru parserul de notificări bancare românești.
// Bănci: BT, ING, Raiffeisen, BCR, Revolut, CEC, Alpha, Garanti
// Edge cases: virgulă vs. punct zecimal, mii separator, valute, salariu, ATM

@Suite struct BankNotificationParserTests {

    // MARK: - Banca Transilvania (BT)

    @Test func btSimplePlata() {
        let tx = BankNotificationParser.parse(raw: "Plată 65,00 RON la Glovo App")
        #expect(tx != nil)
        #expect(tx?.amount.amount == 65)   // Money e Int RON
        #expect(tx?.direction == .outgoing)
        #expect(tx?.source == .notificationParsed)
    }

    @Test func btPlataFaraZecimale() {
        let tx = BankNotificationParser.parse(raw: "Plată 250 RON la Kaufland")
        #expect(tx != nil)
        #expect(tx?.amount.amount == 250)
        #expect(tx?.merchant?.lowercased().contains("kaufland") == true)
    }

    @Test func btPlataLaSfarsit() {
        let tx = BankNotificationParser.parse(raw: "BT Pay: Plată 1.234,56 RON la IKEA România")
        #expect(tx != nil)
        #expect(tx?.amount.amount == 1235)  // 1234.56 rotunjit la 1235 RON
    }

    @Test func btPlataEUR_skip() {
        // FAZA A1/A4: tranzacțiile non-RON sunt SKIP-uite (returnează nil) ca să nu
        // poluăm Safe-to-Spend cu sume EUR/USD tratate fals ca RON. v2 va aduce conversie FX.
        let tx = BankNotificationParser.parse(raw: "Plată 89,99 EUR la Amazon")
        #expect(tx == nil)
    }

    // MARK: - ING România

    @Test func ingAiPlatit() {
        let tx = BankNotificationParser.parse(raw: "Ai plătit 65,00 RON la Glovo Food")
        #expect(tx != nil)
        #expect(tx?.amount.amount == 65)
        #expect(tx?.direction == .outgoing)
    }

    @Test func ingAiPlatitSumaMare() {
        let tx = BankNotificationParser.parse(raw: "Ai plătit 4.500,00 RON la DEDEMAN")
        #expect(tx != nil)
        #expect(tx?.amount.amount == 4500)
        #expect(tx?.merchant?.uppercased().contains("DEDEMAN") == true || tx?.merchant?.lowercased().contains("dedeman") == true)
    }

    @Test func ingFormat2() {
        let tx = BankNotificationParser.parse(raw: "ING: Ai plătit 45.00 RON Starbucks")
        #expect(tx != nil)
        #expect(tx?.amount.amount == 45)
    }

    // MARK: - Raiffeisen Bank

    @Test func raiffeisenPlataCard() {
        let tx = BankNotificationParser.parse(raw: "Plată card: 65,00 RON la GLOVO APPYYYY")
        #expect(tx != nil)
        #expect(tx?.amount.amount == 65)
        #expect(tx?.direction == .outgoing)
    }

    @Test func raiffeisenTranzactieDebitare() {
        let tx = BankNotificationParser.parse(raw: "Tranzacție debitare 120 RON la Lidl România")
        #expect(tx != nil)
        #expect(tx?.amount.amount == 120)
        #expect(tx?.category == .foodGrocery)
    }

    // MARK: - BCR

    @Test func bcrAiEfectuat() {
        let tx = BankNotificationParser.parse(raw: "Ai efectuat o plată de 65,00 RON la Glovo")
        #expect(tx != nil)
        #expect(tx?.amount.amount == 65)
        #expect(tx?.direction == .outgoing)
    }

    @Test func bcrSumaMareCarrefour() {
        let tx = BankNotificationParser.parse(raw: "BCR: Ai efectuat o plată de 287,45 RON la Carrefour")
        #expect(tx != nil)
        #expect(tx?.amount.amount == 287)  // 287.45 rotunjit la 287
        #expect(tx?.category == .foodGrocery)
    }

    // MARK: - Revolut

    @Test func revolutAiPlatitLui() {
        let tx = BankNotificationParser.parse(raw: "Ai plătit 65 RON lui Glovo Food")
        #expect(tx != nil)
        #expect(tx?.amount.amount == 65)
        #expect(tx?.direction == .outgoing)
    }

    @Test func revolutCardPayment_EUR_skip() {
        // FAZA A1/A4: EUR e skip-uit. Pentru same merchant în RON, tranzacția e procesată.
        let txEUR = BankNotificationParser.parse(raw: "Card payment 89.99 EUR at Netflix")
        #expect(txEUR == nil)

        let txRON = BankNotificationParser.parse(raw: "Card payment 89,99 RON at Netflix")
        #expect(txRON != nil)
        #expect(txRON?.category == .subscriptions)
    }

    @Test func revolutPlataEUR_skip() {
        let tx = BankNotificationParser.parse(raw: "Plată 45 EUR - Starbucks")
        #expect(tx == nil)
    }

    // MARK: - CEC Bank

    @Test func cecTranzactieCard() {
        let tx = BankNotificationParser.parse(raw: "Tranzactie card: -65.00 RON Glovo")
        #expect(tx != nil)
        #expect(tx?.amount.amount == 65)
        #expect(tx?.direction == .outgoing)
    }

    // MARK: - Categorizare merchantI

    @Test func categoreazaGlovoFoodDelivery() {
        let tx = BankNotificationParser.parse(raw: "Plată 32,50 RON la Glovo")
        #expect(tx?.category == .foodDelivery)
    }

    @Test func categoreazaNetflixSubscriptions() {
        let tx = BankNotificationParser.parse(raw: "Plată 39,99 RON la Netflix")
        #expect(tx?.category == .subscriptions)
    }

    @Test func categoreazaKauflandGrocery() {
        let tx = BankNotificationParser.parse(raw: "Plată 134,20 RON la Kaufland Grivita")
        #expect(tx?.category == .foodGrocery)
    }

    @Test func categoreazaBoltTransport() {
        let tx = BankNotificationParser.parse(raw: "Plată 23,00 RON la Bolt Transport")
        // Bolt poate fi transport sau food delivery — acceptăm ambele
        let validCategories: Set<TransactionCategory> = [.transport, .foodDelivery]
        #expect(validCategories.contains(tx?.category ?? .unknown))
    }

    @Test func categoreazaSpotifySubscription() {
        let tx = BankNotificationParser.parse(raw: "Plată 24,99 RON la Spotify")
        #expect(tx?.category == .subscriptions)
    }

    @Test func categoreazaEmagOnlineShopping() {
        let tx = BankNotificationParser.parse(raw: "Plată 299,00 RON la eMAG")
        #expect(tx?.category == .shoppingOnline)
    }

    @Test func categoreazaFarmacieSanatate() {
        let tx = BankNotificationParser.parse(raw: "Plată 45,00 RON la Farmacia Sensiblu")
        #expect(tx?.category == .health)
    }

    @Test func categoreazaNecunoscut() {
        let tx = BankNotificationParser.parse(raw: "Plată 100 RON la Servicii Diverse XYZ")
        #expect(tx?.category == .unknown)
    }

    // MARK: - Incoming (salariu / transfer primit)

    @Test func salariu() {
        let tx = BankNotificationParser.parse(raw: "Salariu creditat: 5.200,00 RON de la Companie SRL")
        #expect(tx != nil)
        #expect(tx?.direction == .incoming)
        #expect(tx?.amount.amount == 5200)
    }

    @Test func transferPrimit() {
        let tx = BankNotificationParser.parse(raw: "Transfer primit 500,00 RON de la Ion Popescu")
        #expect(tx != nil)
        #expect(tx?.direction == .incoming)
    }

    @Test func alimentareCont() {
        let tx = BankNotificationParser.parse(raw: "Alimentare cont 1.000 RON")
        #expect(tx?.direction == .incoming)
    }

    // MARK: - ATM Withdrawal (tot outgoing)

    @Test func retragereATM() {
        let tx = BankNotificationParser.parse(raw: "Retragere ATM 300 RON")
        #expect(tx?.direction == .outgoing)
    }

    // MARK: - Decimal Parsing edge cases (intern — Decimal, nu Money)

    @Test func sumaEuropeana1234_56() {
        let result = BankNotificationParser.parseDecimal("1.234,56")
        #expect(result == Decimal(string: "1234.56"))
    }

    @Test func sumaEuropeana65_00() {
        let result = BankNotificationParser.parseDecimal("65,00")
        #expect(result == Decimal(string: "65"))  // 65,00 → 65.00 → Decimal(65)
    }

    @Test func sumaAmericana65_00() {
        let result = BankNotificationParser.parseDecimal("65.00")
        #expect(result == Decimal(string: "65.00"))
    }

    @Test func sumaIntreaga250() {
        let result = BankNotificationParser.parseDecimal("250")
        #expect(result == Decimal(250))
    }

    @Test func sumaAmericana1234_56() {
        let result = BankNotificationParser.parseDecimal("1,234.56")
        #expect(result == Decimal(string: "1234.56"))
    }

    // MARK: - looksLikeBankNotification

    @Test func recognizeBankNotification() {
        #expect(BankNotificationParser.looksLikeBankNotification("Plată 65,00 RON la Glovo") == true)
        #expect(BankNotificationParser.looksLikeBankNotification("Ai plătit 100 EUR la Amazon") == true)
        #expect(BankNotificationParser.looksLikeBankNotification("Tranzacție debitare 50 RON") == true)
    }

    @Test func rejectNonBankNotification() {
        #expect(BankNotificationParser.looksLikeBankNotification("Bună ziua! Cum ești?") == false)
        #expect(BankNotificationParser.looksLikeBankNotification("") == false)
        #expect(BankNotificationParser.looksLikeBankNotification("Mesaj nou de la Ana") == false)
    }

    // MARK: - Merchant cleanup

    @Test func cleanScreamingCaps() {
        let cleaned = BankNotificationParser.cleanMerchant("GLOVO APP")
        // Title case aplicat
        #expect(cleaned == "Glovo App")
    }

    @Test func keepMixedCase() {
        let cleaned = BankNotificationParser.cleanMerchant("eMAG Romania")
        // NU se schimbă — deja mixed case
        #expect(cleaned == "eMAG Romania")
    }

    // MARK: - Source marcat corect

    @Test func sourceEsteNotificationParsed() {
        let tx = BankNotificationParser.parse(raw: "Plată 65,00 RON la Glovo")
        #expect(tx?.source == .notificationParsed)
    }

    // MARK: - Returneaza nil pentru text necunoscut

    @Test func returneazaNilPentruTextFaraValuta() {
        let tx = BankNotificationParser.parse(raw: "Mesaj de la bancă fără sumă")
        #expect(tx == nil)
    }

    @Test func returneazaNilPentruStringGol() {
        let tx = BankNotificationParser.parse(raw: "")
        #expect(tx == nil)
    }
}

// MARK: - MerchantCategoryMatcherTests

@Suite struct MerchantCategoryMatcherTests {

    @Test func glovoIsDelivery() {
        #expect(MerchantCategoryMatcher.category(for: "Glovo") == .foodDelivery)
    }

    @Test func netflixIsSubscription() {
        #expect(MerchantCategoryMatcher.category(for: "Netflix") == .subscriptions)
    }

    @Test func kauflandIsGrocery() {
        #expect(MerchantCategoryMatcher.category(for: "Kaufland Grivita") == .foodGrocery)
    }

    @Test func spotifyIsSubscription() {
        #expect(MerchantCategoryMatcher.category(for: "Spotify AB") == .subscriptions)
    }

    @Test func boltTransportIsTransport() {
        #expect(MerchantCategoryMatcher.category(for: "Bolt Transport SRL") == .transport)
    }

    @Test func providentIsIFN() {
        #expect(MerchantCategoryMatcher.category(for: "Provident Financial") == .loansIFN)
    }

    @Test func klarnaIsBNPL() {
        #expect(MerchantCategoryMatcher.category(for: "Klarna") == .bnpl)
    }

    @Test func unknownMerchant() {
        #expect(MerchantCategoryMatcher.category(for: "XYZ Service 123") == .unknown)
    }

    @Test func caseInsensitive() {
        #expect(MerchantCategoryMatcher.category(for: "NETFLIX") == .subscriptions)
        #expect(MerchantCategoryMatcher.category(for: "glovo") == .foodDelivery)
        #expect(MerchantCategoryMatcher.category(for: "KAUFLAND") == .foodGrocery)
    }

    // MARK: - FAZA A1: Deterministic ID + deduplication

    @Test func deterministicID_sameContent_sameUUID() {
        // Aceeași notificare la același minut → același UUID (deduplication ready)
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let tx1 = BankNotificationParser.parse(raw: "Plată 65,00 RON la Glovo", date: date)
        let tx2 = BankNotificationParser.parse(raw: "Plată 65,00 RON la Glovo", date: date)
        #expect(tx1?.id == tx2?.id)
    }

    @Test func deterministicID_differentMinutes_differentUUID() {
        let dateA = Date(timeIntervalSince1970: 1_700_000_000)
        let dateB = Date(timeIntervalSince1970: 1_700_000_120) // +2 min
        let tx1 = BankNotificationParser.parse(raw: "Plată 65,00 RON la Glovo", date: dateA)
        let tx2 = BankNotificationParser.parse(raw: "Plată 65,00 RON la Glovo", date: dateB)
        #expect(tx1?.id != tx2?.id)
    }

    @Test func deterministicID_differentContent_differentUUID() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let tx1 = BankNotificationParser.parse(raw: "Plată 65,00 RON la Glovo", date: date)
        let tx2 = BankNotificationParser.parse(raw: "Plată 65,00 RON la Lidl", date: date)
        #expect(tx1?.id != tx2?.id)
    }
}
