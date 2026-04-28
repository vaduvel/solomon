import Foundation
import SolomonCore

#if canImport(MLXLLM) && canImport(MLXLMCommon)
import MLX
import MLXLLM
import MLXLMCommon
import MLXHuggingFace
import HuggingFace
import Tokenizers
#endif

// MARK: - MLXLLMProvider
//
// Provider on-device pentru Gemma 4 (E2B / E4B) folosind MLX Swift via shareup/mlx-swift-lm.
// Apple-native, optimizat Metal/Apple Silicon.
//
// Modele recomandate:
//   - "mlx-community/gemma-2-2b-it-4bit"     ~1.5GB → iPhone 14+ (calibrare → E2B)
//   - "mlx-community/gemma-2-9b-it-4bit"     ~5.0GB → iPhone 15 Pro+ (production → E4B)
//
// Calibrarea (system prompts, JSON contexts, max words) e identică între cele 2 modele.

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
            approximateSizeBytes: 1_550_000_000,
            maxTokens: 200,
            temperature: 0.4,
            topP: 0.9
        )

        public static let gemmaE4B = Config(
            modelId: "mlx-community/gemma-2-9b-it-4bit",
            displayName: "Gemma 2 (9B)",
            approximateSizeBytes: 5_200_000_000,
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

    #if canImport(MLXLLM) && canImport(MLXLMCommon)
    private var modelContainer: ModelContainer?
    #endif

    // MARK: - Init

    public init(config: Config = .gemmaE2B) {
        self.config = config
    }

    // MARK: - Public state queries

    public func currentState() async -> State { state }
    public func currentConfig() async -> Config { config }
    public func isModelLoaded() async -> Bool { if case .loaded = state { return true } else { return false } }

    // MARK: - Preload

    public func preloadModel() async throws {
        if case .loaded = state { return }

        #if canImport(MLXLLM) && canImport(MLXLMCommon)
        do {
            state = .downloading(progress: 0.0)
            let configuration = ModelConfiguration(id: config.modelId)

            // Folosim macro-urile MLXHuggingFace pentru download + tokenizer
            let container = try await #huggingFaceLoadModelContainer(
                configuration: configuration,
                progressHandler: { progress in
                    Task { [weak self] in
                        await self?.updateProgress(progress.fractionCompleted)
                    }
                }
            )
            modelContainer = container
            state = .loaded
        } catch {
            state = .loadFailed(reason: error.localizedDescription)
            throw error
        }
        #else
        state = .loadFailed(reason: "MLX runtime nu e disponibil pe această platformă")
        throw LLMError.modelNotLoaded
        #endif
    }

    private func updateProgress(_ progress: Double) {
        if case .loaded = state { return }
        state = .downloading(progress: progress)
    }

    public func unloadModel() async {
        #if canImport(MLXLLM) && canImport(MLXLMCommon)
        modelContainer = nil
        #endif
        state = .notDownloaded
    }

    // MARK: - LLMProvider — generate

    public func generate(
        systemPrompt: String,
        userContext: String,
        maxWords: Int
    ) async throws -> String {
        #if canImport(MLXLLM) && canImport(MLXLMCommon)
        guard let container = modelContainer else {
            throw LLMError.modelNotLoaded
        }

        let chatPrompt = """
        \(systemPrompt)

        Context (JSON):
        \(userContext)

        Răspuns (max \(maxWords) cuvinte, în română):
        """

        let parameters = GenerateParameters(
            temperature: config.temperature,
            topP: config.topP
        )

        let result = try await container.perform { context in
            let userInput = UserInput(prompt: .text(chatPrompt))
            let lmInput = try await context.processor.prepare(input: userInput)

            var output = ""
            let stream = try MLXLMCommon.generate(
                input: lmInput,
                parameters: parameters,
                context: context
            )
            for await item in stream {
                switch item {
                case .chunk(let text):
                    output += text
                    let wordCount = output.split { $0.isWhitespace }.count
                    if wordCount > maxWords + 30 {
                        return output
                    }
                case .info:
                    continue
                @unknown default:
                    continue
                }
            }
            return output
        }

        let trimmed = result.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { throw LLMError.emptyResponse }
        return trimmed
        #else
        throw LLMError.modelNotLoaded
        #endif
    }
}
