import Foundation
import SolomonCore

// MARK: - MLXLLMProvider
//
// Provider on-device pentru Gemma 4 (E2B / E4B) folosind MLX Swift.
// Apple-native, optimizat Metal/Apple Silicon.
//
// Stadiu Faza 26: SCAFFOLD COMPLET (provider stub + UI + download manager + state).
// Implementarea inference reală se adaugă într-o iterație separată prin vendoring
// MLXLLM source code din mlx-swift-examples (Apple nu publică MLXLLM ca SPM lib).
//
// Modele suportate:
//   - "mlx-community/gemma-2-2b-it-4bit"     ~1.5GB → iPhone 14+ (calibrare → E2B)
//   - "mlx-community/gemma-2-9b-it-4bit"     ~5.0GB → iPhone 15 Pro+ (production → E4B)
//
// Când inference-ul e wired, calibrarea (system prompts, JSON contexts, max words)
// rămâne IDENTICĂ — doar swap implementation.

public actor MLXLLMProvider: LLMProvider {

    // MARK: - Config

    public struct Config: Sendable {
        public let modelId: String
        public let displayName: String
        public let approximateSizeBytes: Int64
        public let maxTokens: Int
        public let temperature: Float
        public let topP: Float

        public static let gemmaE2B = Config(
            modelId: "mlx-community/gemma-2-2b-it-4bit",
            displayName: "Gemma 2 (2B)",
            approximateSizeBytes: 1_550_000_000,    // ~1.5 GB
            maxTokens: 200,
            temperature: 0.4,
            topP: 0.9
        )

        public static let gemmaE4B = Config(
            modelId: "mlx-community/gemma-2-9b-it-4bit",
            displayName: "Gemma 2 (9B)",
            approximateSizeBytes: 5_200_000_000,    // ~5 GB
            maxTokens: 240,
            temperature: 0.4,
            topP: 0.9
        )

        public init(
            modelId: String,
            displayName: String,
            approximateSizeBytes: Int64,
            maxTokens: Int = 200,
            temperature: Float = 0.4,
            topP: Float = 0.9
        ) {
            self.modelId = modelId
            self.displayName = displayName
            self.approximateSizeBytes = approximateSizeBytes
            self.maxTokens = maxTokens
            self.temperature = temperature
            self.topP = topP
        }
    }

    // MARK: - State

    public enum State: Sendable, Equatable {
        case notDownloaded
        case downloading(progress: Double)
        case loaded
        case loadFailed(reason: String)
    }

    private let config: Config
    private var state: State = .notDownloaded
    private var modelHandle: Any?    // placeholder pentru ModelContainer real

    // MARK: - Init

    public init(config: Config = .gemmaE2B) {
        self.config = config
    }

    // MARK: - Public state queries

    public func currentState() async -> State { state }
    public func currentConfig() async -> Config { config }
    public func isModelLoaded() async -> Bool { if case .loaded = state { return true } else { return false } }

    // MARK: - Download / preload

    /// Verifică dacă modelul e descărcat local și-l încarcă în RAM.
    /// Dacă lipsește, declanșează download de pe HuggingFace prin MLXModelDownloader.
    /// Apelat la first launch (după onboarding) sau la upgrade model în Settings.
    public func preloadModel() async throws {
        if case .loaded = state { return }

        let downloader = MLXModelDownloader()
        do {
            try await downloader.ensureModelDownloaded(modelId: config.modelId) { [weak self] progress in
                Task { await self?.updateProgress(progress) }
            }

            // Real load: prin MLXLLM container (vendored ulterior).
            // Pentru moment marcăm ca .loadFailed pentru ca MomentEngine
            // să facă fallback la TemplateLLMProvider.
            state = .loadFailed(reason: "MLX inference runtime nu e wired încă în această versiune")
            throw LLMError.modelNotLoaded
        } catch {
            state = .loadFailed(reason: error.localizedDescription)
            throw error
        }
    }

    private func updateProgress(_ progress: Double) {
        if case .loaded = state { return }
        state = .downloading(progress: progress)
    }

    public func unloadModel() async {
        modelHandle = nil
        state = .notDownloaded
    }

    // MARK: - LLMProvider

    public func generate(
        systemPrompt: String,
        userContext: String,
        maxWords: Int
    ) async throws -> String {
        guard case .loaded = state else {
            throw LLMError.modelNotLoaded
        }
        // TODO Faza 26B: inference real prin MLXLLM container.
        // Token loop, streaming output, max words enforcement.
        throw LLMError.generationFailed(reason: "MLX inference runtime nu e wired în această versiune")
    }
}
