import Foundation
import SolomonCore

// MARK: - Protocol

/// Abstracție peste LLM — permite injectarea unui MockLLMProvider în teste fără LLM real.
///
/// Contractul: primește system prompt + context JSON → returnează text în română,
/// cel mult `maxWords` cuvinte.
///
/// Implementarea reală (MLX Swift / LiteRT-LM) va respecta același contract —
/// decizia de runtime se ia la Faza 9.
public protocol LLMProvider: Sendable {
    func generate(systemPrompt: String, userContext: String, maxWords: Int) async throws -> String
}

// MARK: - Errors

public enum LLMError: Error, Sendable {
    case modelNotLoaded
    case contextTooLong(charCount: Int)
    case generationFailed(reason: String)
    case timeout
}

// MARK: - Mock

/// Mock determinist pentru teste — returnează un răspuns predefinit bazat pe `momentType`.
///
/// Nu face apeluri LLM reale. Output-ul e scurt, respectă maxWords, și include
/// `momentType.rawValue` pentru ca testele să verifice routing-ul corect.
public final class MockLLMProvider: LLMProvider, @unchecked Sendable {

    /// Răspunsul forțat — dacă nil, se generează automat din system prompt.
    public var forcedResponse: String? = nil
    /// Numărul de apeluri generate — util pentru a verifica că LLM-ul a fost invocat.
    public private(set) var generateCallCount = 0
    /// Ultimul system prompt primit.
    public private(set) var lastSystemPrompt: String? = nil
    /// Ultimul context primit.
    public private(set) var lastUserContext: String? = nil
    /// Dacă true, aruncă `LLMError.generationFailed` la orice apel.
    public var shouldThrow: Bool = false

    public init() {}

    public func generate(systemPrompt: String, userContext: String, maxWords: Int) async throws -> String {
        generateCallCount += 1
        lastSystemPrompt = systemPrompt
        lastUserContext = userContext

        if shouldThrow {
            throw LLMError.generationFailed(reason: "Mock forced failure")
        }

        if let forced = forcedResponse { return forced }

        // Răspuns auto-generat: extrage tipul din system prompt sau returnează un text generic
        let momentHint = extractMomentHint(from: systemPrompt)
        return "[\(momentHint)] Răspuns generat automat de MockLLMProvider pentru contextul furnizat."
    }

    // MARK: - Private

    private func extractMomentHint(from prompt: String) -> String {
        for type in MomentType.allCases {
            if prompt.lowercased().contains(type.rawValue.lowercased().replacingOccurrences(of: "_", with: " ")) {
                return type.rawValue
            }
        }
        return "mock_response"
    }
}
