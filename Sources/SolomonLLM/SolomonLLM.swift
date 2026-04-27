import Foundation
import SolomonCore

// MARK: - LLMProvider protocol (definit în SolomonLLM, folosit de SolomonMoments)

/// Abstracție peste LLM local — permite injectarea unui MockLLMProvider în teste fără LLM real.
///
/// Contractul: primește system prompt + context JSON → returnează text în română,
/// cel mult `maxWords` cuvinte.
///
/// Implementări disponibile:
/// - `OllamaLLMProvider` — apelează Ollama local (Gemma 4 E2B via localhost:11434)
/// - `MockLLMProvider` din SolomonMoments — pentru teste unitare
public protocol LLMProvider: Sendable {
    func generate(systemPrompt: String, userContext: String, maxWords: Int) async throws -> String
}

// MARK: - LLM errors

public enum LLMError: Error, Sendable {
    case modelNotLoaded
    case contextTooLong(charCount: Int)
    case generationFailed(reason: String)
    case timeout
    case emptyResponse
}

// MARK: - Module marker

public enum SolomonLLM {
    public static let version = "1.0.0"
    public static let defaultModel = "gemma4:e2b"
    public static let defaultBaseURL = "http://localhost:11434"
}
