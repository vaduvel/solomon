import Foundation
import SolomonCore
import SolomonLLM

// LLMProvider protocol și LLMError sunt definite în SolomonLLM — re-exportate implicit prin import.
// Acest fișier conține doar MockLLMProvider pentru teste.

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

        let momentHint = extractMomentHint(from: systemPrompt)
        return "[\(momentHint)] Răspuns generat automat de MockLLMProvider pentru contextul furnizat."
    }

    private func extractMomentHint(from prompt: String) -> String {
        for type in MomentType.allCases {
            if prompt.lowercased().contains(type.rawValue.lowercased().replacingOccurrences(of: "_", with: " ")) {
                return type.rawValue
            }
        }
        return "mock_response"
    }
}
