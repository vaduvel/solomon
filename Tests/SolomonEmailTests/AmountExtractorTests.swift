import Testing
import Foundation
@testable import SolomonEmail

@Suite struct AmountExtractorTests {

    let ex = AmountExtractor()

    // MARK: - RON formats

    @Test func extractsIntegerRON() {
        let result = ex.extractPrimary(from: "Total plată: 549 RON")
        #expect(result?.value == 549)
        #expect(result?.currency == .ron)
    }

    @Test func extractsRONWithDecimalComma() {
        // 150,99 RON → 151 RON (rotunjit)
        let result = ex.extractPrimary(from: "Valoare comandă: 150,99 RON")
        #expect(result?.value == 151)
        #expect(result?.currency == .ron)
    }

    @Test func extractsRONWithThousandsDotAndDecimalComma() {
        // 1.234,56 RON → 1235 RON
        let result = ex.extractPrimary(from: "Suma de plata este 1.234,56 RON.")
        #expect(result?.value == 1235)
        #expect(result?.currency == .ron)
    }

    @Test func extractsRONWithThousandsSeparatorOnly() {
        // 1.234 RON — punct ca separator de mii (3 cifre după)
        let result = ex.extractPrimary(from: "Total: 1.234 RON")
        #expect(result?.value == 1234)
        #expect(result?.currency == .ron)
    }

    @Test func extractsRONWithLei() {
        let result = ex.extractPrimary(from: "Ai plătit 299 lei.")
        #expect(result?.value == 299)
        #expect(result?.currency == .ron)
    }

    @Test func extractsRONWithEnglishDecimalDot() {
        // 1234.56 RON — format englezesc
        let result = ex.extractPrimary(from: "Amount: 1234.56 RON")
        #expect(result?.value == 1235)
        #expect(result?.currency == .ron)
    }

    // MARK: - EUR

    @Test func extractsEUR() {
        let result = ex.extractPrimary(from: "100 EUR")
        #expect(result?.value == 100)
        #expect(result?.currency == .eur)
    }

    @Test func extractsEURWithDecimal() {
        let result = ex.extractPrimary(from: "49,99 EUR")
        #expect(result?.value == 50)
        #expect(result?.currency == .eur)
    }

    @Test func extractsEURMoneyIsNil() {
        // EUR nu se convertește direct la Money RON
        let result = ex.extractPrimary(from: "100 EUR")
        #expect(result?.moneyRON == nil)
    }

    // MARK: - Multiple amounts

    @Test func extractAllReturnsMultiple() {
        let text = "Taxa livrare: 9 RON. Total comandă: 187 RON. Reducere: 20 RON."
        let all = ex.extractAll(from: text)
        #expect(all.count == 3)
        // Ordonate descrescător
        #expect(all[0].value == 187)
        #expect(all[1].value == 20)
        #expect(all[2].value == 9)
    }

    @Test func extractAllDeduplicatesSameValue() {
        // "187 RON" apare de două ori — trebuie deduplicat
        let text = "Suma 187 RON confirmata. Total: 187 RON."
        let all = ex.extractAll(from: text)
        #expect(all.count == 1)
        #expect(all[0].value == 187)
    }

    // MARK: - Labeled amount extraction

    @Test func extractTransactionAmountPrefersLabeledTotal() {
        // Body conține taxa de livrare și totalul
        let text = """
        Taxa livrare: 15 RON
        Total: 349 RON
        Succes!
        """
        let result = ex.extractTransactionAmount(from: text)
        #expect(result?.value == 349)
    }

    @Test func extractTransactionAmountFallsBackToPrimary() {
        // Niciun label — returnează cea mai mare sumă
        let text = "Comanda 187 RON procesata cu succes."
        let result = ex.extractTransactionAmount(from: text)
        #expect(result?.value == 187)
    }

    // MARK: - No amount

    @Test func returnsNilWhenNoAmount() {
        let result = ex.extractPrimary(from: "Bine ai venit la Solomon! Configurarea a fost finalizata.")
        #expect(result == nil)
    }

    // MARK: - Edge cases

    @Test func handlesLargeAmounts() {
        let result = ex.extractPrimary(from: "Total credit: 12.000 RON aprobat.")
        #expect(result?.value == 12000)
    }

    @Test func handlesSmallAmounts() {
        let result = ex.extractPrimary(from: "Comision: 0,99 RON")
        #expect(result?.value == 1)
    }

    @Test func parseRomanianNumberInteger() {
        #expect(ex.parseRomanianNumber("1234") == 1234)
    }

    @Test func parseRomanianNumberDecimalComma() {
        #expect(ex.parseRomanianNumber("150,99") == 151)
    }

    @Test func parseRomanianNumberThousandsDotDecimalComma() {
        #expect(ex.parseRomanianNumber("1.234,56") == 1235)
    }

    @Test func parseRomanianNumberThousandsSeparatorOnly() {
        #expect(ex.parseRomanianNumber("1.234") == 1234)
    }

    @Test func parseRomanianNumberEnglishDecimal() {
        #expect(ex.parseRomanianNumber("1234.56") == 1235)
    }
}
