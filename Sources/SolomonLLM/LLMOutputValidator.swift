import Foundation
import SolomonCore

// MARK: - LLMOutputValidator
//
// Implementare conform spec §7.3 — validează output-ul textual al LLM-ului
// înainte de a fi prezentat utilizatorului.
//
// Verificări:
//   1. Cifrele critice din contextul JSON apar în output
//   2. NU există cuvinte engleze comune (English bleed-through)
//   3. Lungime ≤ maxWords
//   4. Diacritice românești prezente (>30 cuv. → trebuie să existe ăâîșț)
//
// Strategie retry: max 2 retry cu prompt strict, apoi fallback template.

public struct LLMOutputValidator: Sendable {

    // MARK: - Configurare

    /// Cuvinte englezești comune care NU ar trebui să apară în output RO.
    /// Lista din spec §7.3 + extensii practice.
    public static let englishLeakWords: Set<String> = [
        "budget", "savings", "expense", "income", "monthly",
        "subscription", "weekly", "amount", "balance", "spending",
        "today", "tomorrow", "yesterday", "good morning", "hello",
        "thank you", "you are", "your", "have", "the", "your money",
        "let me", "i can", "i will", "you can", "you should",
        "you have", "i think", "however"
    ]

    /// Diacritice românești obligatorii pentru output > 30 cuvinte.
    public static let romanianDiacritics: Set<Character> = [
        "ă", "â", "î", "ș", "ț", "Ă", "Â", "Î", "Ș", "Ț"
    ]

    /// Pragul de cuvinte după care diacriticele sunt obligatorii.
    public static let diacriticsRequiredAboveWords: Int = 30

    // MARK: - Result type

    public struct Result: Sendable, Equatable {
        public let passed: Bool
        public let errors: [Error]
        public let wordCount: Int

        public enum Error: Sendable, Equatable, Hashable {
            case missingCriticalNumber(value: Int, formatted: String)
            case englishWordFound(String)
            case tooLong(wordCount: Int, maxAllowed: Int)
            case missingDiacritics(wordCount: Int)
            case empty

            public var description: String {
                switch self {
                case .missingCriticalNumber(let v, let f):
                    return "Numărul critic lipsește: \(f) (\(v))"
                case .englishWordFound(let w):
                    return "Cuvânt englez detectat: '\(w)'"
                case .tooLong(let wc, let max):
                    return "Output prea lung: \(wc) > \(max) cuvinte"
                case .missingDiacritics(let wc):
                    return "Lipsesc diacritice în output de \(wc) cuvinte"
                case .empty:
                    return "Output gol"
                }
            }
        }
    }

    // MARK: - Public API

    public init() {}

    /// Validează output-ul LLM contra unei liste de cifre critice + max words.
    public func validate(
        output: String,
        criticalNumbers: [Int],
        maxWords: Int
    ) -> Result {
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)

        var errors: [Result.Error] = []

        // 0. Empty
        if trimmed.isEmpty {
            return Result(passed: false, errors: [.empty], wordCount: 0)
        }

        let words = trimmed.split { $0.isWhitespace || $0.isNewline }
        let wordCount = words.count

        // 1. Critical numbers
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        formatter.locale = Locale(identifier: "ro_RO")

        for number in criticalNumbers {
            let formatted = formatter.string(from: NSNumber(value: number)) ?? "\(number)"
            // Verificăm dacă apare formatat (ex: 1.234) sau plain (ex: 1234)
            let containsFormatted = trimmed.contains(formatted)
            let containsPlain = trimmed.contains(String(number))
            if !containsFormatted && !containsPlain {
                errors.append(.missingCriticalNumber(value: number, formatted: formatted))
            }
        }

        // 2. English words
        let lowerOutput = trimmed.lowercased()
        for word in Self.englishLeakWords {
            // Verificăm word-boundary (start/end of word) ca să evităm fals-pozitive
            // (ex: "have" în "haven't" e ok)
            if containsAsWord(word, in: lowerOutput) {
                errors.append(.englishWordFound(word))
            }
        }

        // 3. Length
        if wordCount > maxWords {
            errors.append(.tooLong(wordCount: wordCount, maxAllowed: maxWords))
        }

        // 4. Diacritics (doar pentru output > 30 cuvinte)
        if wordCount > Self.diacriticsRequiredAboveWords {
            let hasAnyDiacritic = trimmed.contains { Self.romanianDiacritics.contains($0) }
            if !hasAnyDiacritic {
                errors.append(.missingDiacritics(wordCount: wordCount))
            }
        }

        return Result(passed: errors.isEmpty, errors: errors, wordCount: wordCount)
    }

    // MARK: - Helpers

    /// Verifică dacă `word` apare ca cuvânt complet (nu ca substring) în `text`.
    /// Exemple:
    ///   containsAsWord("the", in: "the cat") → true
    ///   containsAsWord("the", in: "they") → false
    func containsAsWord(_ word: String, in text: String) -> Bool {
        let pattern = "\\b\(NSRegularExpression.escapedPattern(for: word))\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return text.contains(word)
        }
        let range = NSRange(text.startIndex..., in: text)
        return regex.firstMatch(in: text, range: range) != nil
    }
}

// MARK: - Convenience

public extension LLMOutputValidator {
    /// Validare rapidă cu doar cifrele critice (folosește 100 ca max default).
    func validateQuick(output: String, expectedNumbers: [Int]) -> Result {
        validate(output: output, criticalNumbers: expectedNumbers, maxWords: 100)
    }
}
