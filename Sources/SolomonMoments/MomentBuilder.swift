import Foundation
import SolomonCore
import SolomonLLM

// MARK: - MomentOutput

/// Rezultatul complet al unui builder de moment — context JSON + răspuns LLM + metadate.
public struct MomentOutput: Sendable {
    /// Tipul momentului generat.
    public var momentType: MomentType
    /// JSON-ul de context trimis LLM-ului (schemă Solomon snake_case).
    public var contextJSON: String
    /// System prompt-ul complet trimis LLM-ului.
    public var promptSent: String
    /// Textul generat de LLM (în română).
    public var llmResponse: String
    /// Momentul generării.
    public var generatedAt: Date

    public init(momentType: MomentType, contextJSON: String, promptSent: String,
                llmResponse: String, generatedAt: Date = Date()) {
        self.momentType = momentType
        self.contextJSON = contextJSON
        self.promptSent = promptSent
        self.llmResponse = llmResponse
        self.generatedAt = generatedAt
    }

    /// Numărul de cuvinte din răspunsul LLM.
    public var wordCount: Int {
        llmResponse.split { $0.isWhitespace }.count
    }

    /// True dacă răspunsul respectă limita de cuvinte a momentului.
    public var isWithinWordLimit: Bool {
        wordCount <= momentType.maxWords
    }

    /// True dacă răspunsul conține cel puțin un cuvânt.
    public var hasResponse: Bool {
        !llmResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - MomentBuilder protocol

/// Protocol adoptat de fiecare builder de moment Solomon.
///
/// Fiecare builder știe:
/// 1. Ce tip de context acceptă (`Context`)
/// 2. Ce system prompt îi dă LLM-ului
/// 3. Cum serializează contextul în JSON
/// 4. Cum asamblează `MomentOutput`
///
/// Default `build` implementat în extension — concret builders suprascriu doar `systemPrompt`.
public protocol MomentBuilder: Sendable {
    associatedtype Context: Encodable & Sendable

    var momentType: MomentType { get }
    var systemPrompt: String { get }

    /// Serializare context → JSON string (Solomon snake_case).
    func buildContextJSON(_ context: Context) throws -> String

    /// Generează un moment complet: JSON + LLM call → MomentOutput.
    func build(_ context: Context, using llm: any LLMProvider) async throws -> MomentOutput
}

// MARK: - Default implementation

extension MomentBuilder {

    public func buildContextJSON(_ context: Context) throws -> String {
        try SolomonContextCoder.encodeAsJSONString(context)
    }

    public func build(_ context: Context, using llm: any LLMProvider) async throws -> MomentOutput {
        let json = try buildContextJSON(context)
        let response = try await llm.generate(
            systemPrompt: systemPrompt,
            userContext: json,
            maxWords: momentType.maxWords
        )
        return MomentOutput(
            momentType: momentType,
            contextJSON: json,
            promptSent: systemPrompt,
            llmResponse: response
        )
    }
}
