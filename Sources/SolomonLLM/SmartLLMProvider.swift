import Foundation
import os
import SolomonCore

// MARK: - SmartLLMProvider
//
// Wrapper care încearcă providerul "real" (MLX, Ollama, etc.) și cade pe Template
// dacă acela eșuează SAU dacă depășește timeout-ul. Asta garantează că Solomon
// NICIODATĂ nu rămâne fără răspuns și nici nu blochează UI-ul.
//
// Folosit ca default în MomentEngine pentru:
//   - First launch (înainte ca modelul MLX să fie descărcat) → Template
//   - Model corupt / error inference → Template
//   - Memory pressure → Template (fallback automat)
//   - FAZA A3: inferență blocată > 25s → cancel + Template fallback
//
// Strategy: try with timeout → catch any LLMError / TimeoutError → fallback la Template

public final class SmartLLMProvider: LLMProvider, @unchecked Sendable {

    private let primary: any LLMProvider
    private let fallback: any LLMProvider
    private let timeout: TimeInterval

    private static let logger = Logger(subsystem: "ro.solomon.llm", category: "SmartLLMProvider")

    /// - Parameters:
    ///   - primary: providerul preferat (MLX/Ollama)
    ///   - fallback: providerul de safety net (default Template)
    ///   - timeout: cât așteptăm primary înainte să cădem pe fallback (default 25s)
    public init(
        primary: any LLMProvider,
        fallback: any LLMProvider = TemplateLLMProvider(),
        timeout: TimeInterval = 25
    ) {
        self.primary = primary
        self.fallback = fallback
        self.timeout = timeout
    }

    public func generate(
        systemPrompt: String,
        userContext: String,
        maxWords: Int
    ) async throws -> String {
        do {
            return try await withTimeout(seconds: timeout) {
                try await self.primary.generate(
                    systemPrompt: systemPrompt,
                    userContext: userContext,
                    maxWords: maxWords
                )
            }
        } catch {
            // Log pentru observability (fără PII)
            Self.logger.warning("Primary LLM failed (\(type(of: self.primary), privacy: .public)) → fallback Template: \(error.localizedDescription, privacy: .public)")
            return try await fallback.generate(
                systemPrompt: systemPrompt,
                userContext: userContext,
                maxWords: maxWords
            )
        }
    }

    // MARK: - Timeout helper

    /// FAZA A3: Rulează `operation` cu deadline. Dacă deadline-ul expiră, aruncă
    /// TimeoutError și anulează task-ul background.  Folosit ca să nu lăsăm
    /// MLX inference să atârne UI-ul la nesfârșit.
    private func withTimeout<T: Sendable>(
        seconds: TimeInterval,
        operation: @Sendable @escaping () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask { try await operation() }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw LLMTimeoutError(seconds: seconds)
            }
            // Primul rezultat câștigă (succes sau timeout); cancel celălalt task.
            guard let result = try await group.next() else {
                throw LLMTimeoutError(seconds: seconds)
            }
            group.cancelAll()
            return result
        }
    }
}

/// Eroare aruncată când inferența LLM depășește timeout-ul configurat.
public struct LLMTimeoutError: Error, LocalizedError {
    public let seconds: TimeInterval
    public var errorDescription: String? {
        "LLM inference exceeded \(Int(seconds))s timeout"
    }
}
