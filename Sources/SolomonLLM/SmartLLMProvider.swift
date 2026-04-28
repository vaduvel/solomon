import Foundation
import SolomonCore

// MARK: - SmartLLMProvider
//
// Wrapper care încearcă providerul "real" (MLX, Ollama, etc.) și cade pe Template
// dacă acela eșuează. Asta garantează că Solomon NICIODATĂ nu rămâne fără răspuns.
//
// Folosit ca default în MomentEngine pentru:
//   - First launch (înainte ca modelul MLX să fie descărcat) → Template
//   - Model corupt / error inference → Template
//   - Memory pressure → Template (fallback automat)
//
// Strategy: try → catch any LLMError → fallback la Template

public final class SmartLLMProvider: LLMProvider, @unchecked Sendable {

    private let primary: any LLMProvider
    private let fallback: any LLMProvider

    public init(
        primary: any LLMProvider,
        fallback: any LLMProvider = TemplateLLMProvider()
    ) {
        self.primary = primary
        self.fallback = fallback
    }

    public func generate(
        systemPrompt: String,
        userContext: String,
        maxWords: Int
    ) async throws -> String {
        do {
            return try await primary.generate(
                systemPrompt: systemPrompt,
                userContext: userContext,
                maxWords: maxWords
            )
        } catch {
            // Log pentru observability (fără PII)
            print("⚠️ SmartLLMProvider: primary failed (\(type(of: primary))), falling back to template — \(error.localizedDescription)")
            return try await fallback.generate(
                systemPrompt: systemPrompt,
                userContext: userContext,
                maxWords: maxWords
            )
        }
    }
}
