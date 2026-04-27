import Testing
import Foundation
@testable import SolomonLLM

// MARK: - LLMOutputValidatorTests

@Suite struct LLMOutputValidatorTests {

    let validator = LLMOutputValidator()

    // MARK: - Basics

    @Test func emptyOutputFails() {
        let r = validator.validate(output: "", criticalNumbers: [], maxWords: 100)
        #expect(r.passed == false)
        #expect(r.errors.contains(.empty))
    }

    @Test func validShortOutputPasses() {
        let r = validator.validate(
            output: "Da, poți. După pizza ai 81 RON pe zi pentru 9 zile.",
            criticalNumbers: [81, 9],
            maxWords: 50
        )
        #expect(r.passed == true)
        #expect(r.errors.isEmpty)
    }

    // MARK: - Critical numbers

    @Test func detectsMissingCriticalNumber() {
        let r = validator.validate(
            output: "Da, poți să-ți permiți. Salutare!",
            criticalNumbers: [735, 81],
            maxWords: 50
        )
        #expect(r.passed == false)
        #expect(r.errors.contains { e in
            if case .missingCriticalNumber(let v, _) = e, v == 735 { return true }
            return false
        })
    }

    @Test func acceptsFormattedNumber() {
        // Format român: 1.234
        let r = validator.validate(
            output: "După plată ai disponibili 1.234 RON pentru 30 de zile.",
            criticalNumbers: [1234],
            maxWords: 50
        )
        #expect(r.passed == true)
    }

    @Test func acceptsPlainNumber() {
        let r = validator.validate(
            output: "Salariul tău e 5200 RON net.",
            criticalNumbers: [5200],
            maxWords: 50
        )
        #expect(r.passed == true)
    }

    // MARK: - English leak detection

    @Test func detectsEnglishWord() {
        let r = validator.validate(
            output: "Your monthly budget is 5000 RON. Excellent!",
            criticalNumbers: [5000],
            maxWords: 50
        )
        #expect(r.passed == false)
        #expect(r.errors.contains(where: {
            if case .englishWordFound = $0 { return true }
            return false
        }))
    }

    @Test func acceptsRomanianOutput() {
        let r = validator.validate(
            output: "Soldul tău rămâne 1234 RON până la salariul următor.",
            criticalNumbers: [1234],
            maxWords: 50
        )
        #expect(r.passed == true)
    }

    @Test func wordBoundaryAvoidsFalsePositive() {
        // "have" în "behave" NU ar trebui să declanșeze fals-pozitiv
        // (deși e improbabil într-un text românesc)
        let r = validator.validate(
            output: "Cele 200 RON rămase îți ajung 5 zile.",
            criticalNumbers: [200, 5],
            maxWords: 50
        )
        #expect(r.passed == true)
    }

    // MARK: - Length

    @Test func detectsTooLongOutput() {
        let longText = String(repeating: "cuvânt ", count: 60)
        let r = validator.validate(
            output: longText + "1234 RON",
            criticalNumbers: [1234],
            maxWords: 40
        )
        #expect(r.passed == false)
        #expect(r.errors.contains { e in
            if case .tooLong = e { return true }
            return false
        })
    }

    @Test func acceptsExactMaxLength() {
        let exactly10 = "unu doi trei patru cinci șase șapte opt nouă 10"
        let r = validator.validate(
            output: exactly10,
            criticalNumbers: [10],
            maxWords: 10
        )
        #expect(r.passed == true)
    }

    // MARK: - Diacritics

    @Test func detectsMissingDiacriticsInLongOutput() {
        // Output > 30 cuvinte fără diacritice
        let words = Array(repeating: "cuvant", count: 35)
        let output = words.joined(separator: " ") + " 100 RON"
        let r = validator.validate(
            output: output,
            criticalNumbers: [100],
            maxWords: 50
        )
        #expect(r.passed == false)
        #expect(r.errors.contains { e in
            if case .missingDiacritics = e { return true }
            return false
        })
    }

    @Test func shortOutputWithoutDiacriticsIsOK() {
        // Output ≤ 30 cuvinte — diacriticele NU sunt obligatorii
        let r = validator.validate(
            output: "Da, poti cumpara pizza. Iti raman 81 RON pe zi.",
            criticalNumbers: [81],
            maxWords: 50
        )
        #expect(r.passed == true)
    }

    @Test func longOutputWithDiacriticsIsOK() {
        // Output > 30 cuvinte CU diacritice
        let words = Array(repeating: "cuvântă", count: 35)
        let output = words.joined(separator: " ") + " 100 RON"
        let r = validator.validate(
            output: output,
            criticalNumbers: [100],
            maxWords: 100
        )
        #expect(r.passed == true)
    }

    // MARK: - Combined errors

    @Test func multipleErrorsReported() {
        let output = "Your budget is 0 RON for monthly expense"
        let r = validator.validate(
            output: output,
            criticalNumbers: [5200, 81],
            maxWords: 50
        )
        #expect(r.passed == false)
        #expect(r.errors.count >= 3)  // missing 5200, missing 81, multiple english
    }

    // MARK: - Word boundary helper

    @Test func wordBoundaryWorks() {
        #expect(validator.containsAsWord("the", in: "the cat") == true)
        #expect(validator.containsAsWord("the", in: "they ran") == false)
        #expect(validator.containsAsWord("budget", in: "your budget is") == true)
        #expect(validator.containsAsWord("the", in: "another") == false)
    }

    // MARK: - Word count

    @Test func wordCountCorrect() {
        let r = validator.validate(
            output: "unu doi trei",
            criticalNumbers: [],
            maxWords: 10
        )
        #expect(r.wordCount == 3)
    }
}
