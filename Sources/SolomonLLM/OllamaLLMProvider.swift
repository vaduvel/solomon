import Foundation

// MARK: - Ollama request/response types

private struct OllamaGenerateRequest: Encodable {
    let model: String
    let prompt: String
    let stream: Bool
    /// `false` = dezactivează gândirea internă (thinking phase) pentru Gemma4/alte modele
    /// care suportă modul think. Solomon nu are nevoie de reasoning — JSON-ul furnizează toate
    /// faptele, modelul doar le transformă în text natural.
    let think: Bool
    let options: OllamaOptions?
}

private struct OllamaOptions: Encodable {
    let temperature: Double
    let topP: Double
    let numPredict: Int

    enum CodingKeys: String, CodingKey {
        case temperature
        case topP        = "top_p"
        case numPredict  = "num_predict"
    }
}

private struct OllamaStreamChunk: Decodable {
    let response: String
    /// Conținut din faza de gândire (thinking phase). Prezent doar când `think:true`.
    /// Solomon îl ignoră — vrem doar răspunsul final din câmpul `response`.
    let thinking: String?
    let done: Bool
    let evalCount: Int?
    let totalDuration: Int?
    let loadDuration: Int?

    enum CodingKeys: String, CodingKey {
        case response
        case thinking
        case done
        case evalCount    = "eval_count"
        case totalDuration = "total_duration"
        case loadDuration  = "load_duration"
    }
}

// MARK: - Provider errors

public enum OllamaError: Error, Sendable {
    case invalidURL
    case httpError(statusCode: Int)
    case streamFailed
    case emptyResponse
    case timeout
    case networkError(Error)
}

// MARK: - OllamaLLMProvider

/// `LLMProvider` concret care vorbește cu Ollama local (spec §3.2).
///
/// Folosește `/api/generate` cu `stream:true` — tokenuri SSE line-by-line.
/// Model implicit: `gemma4:e2b` rulând pe localhost:11434.
///
/// Thread-safe (struct + URLSession).
public struct OllamaLLMProvider: Sendable {

    public let baseURL: String
    public let model: String
    public let temperature: Double
    public let topP: Double
    /// Timeout total per request în secunde (modelul se încarcă la primul request).
    public let timeoutSeconds: Double

    public init(
        baseURL: String = "http://localhost:11434",
        model: String = "gemma4:e2b",
        temperature: Double = 0.4,
        topP: Double = 0.9,
        timeoutSeconds: Double = 180
    ) {
        self.baseURL = baseURL
        self.model = model
        self.temperature = temperature
        self.topP = topP
        self.timeoutSeconds = timeoutSeconds
    }

    // MARK: - Generate

    /// Generează text prin Ollama streaming API.
    ///
    /// Combină `systemPrompt` + `userContext` într-un singur prompt text,
    /// acumulează tokenurile streamed și returnează textul final.
    public func generate(systemPrompt: String, userContext: String, maxWords: Int) async throws -> String {
        let fullPrompt = buildPrompt(system: systemPrompt, context: userContext)
        // Buffer generos: româna are ~1.5 tokeni/cuvânt; × 5 acoperă variabilitate +
        // orice overhead de formatare. Thinking mode e dezactivat, deci toți tokenele
        // merg direct în răspuns.
        let numPredict = max(maxWords * 5, 200)

        guard let url = URL(string: "\(baseURL)/api/generate") else {
            throw OllamaError.invalidURL
        }

        let body = OllamaGenerateRequest(
            model: model,
            prompt: fullPrompt,
            stream: true,
            think: false,   // Fără thinking phase — JSON-ul furnizează toate faptele,
                            // Gemma4 trebuie doar să le îmbrace în text natural.
            options: OllamaOptions(temperature: temperature, topP: topP, numPredict: numPredict)
        )

        let bodyData = try JSONEncoder().encode(body)

        var request = URLRequest(url: url, timeoutInterval: timeoutSeconds)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeoutSeconds
        config.timeoutIntervalForResource = timeoutSeconds
        let session = URLSession(configuration: config)

        let (asyncBytes, response) = try await session.bytes(for: request)

        if let httpResp = response as? HTTPURLResponse,
           !(200..<300).contains(httpResp.statusCode) {
            throw OllamaError.httpError(statusCode: httpResp.statusCode)
        }

        var accumulated = ""

        for try await line in asyncBytes.lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            guard let data = trimmed.data(using: .utf8),
                  let chunk = try? JSONDecoder().decode(OllamaStreamChunk.self, from: data)
            else { continue }

            accumulated += chunk.response

            if chunk.done { break }
        }

        let result = accumulated.trimmingCharacters(in: .whitespacesAndNewlines)
        if result.isEmpty { throw OllamaError.emptyResponse }
        return result
    }

    // MARK: - Prompt builder

    /// Combină system prompt + context JSON într-un singur text pentru Gemma instruct.
    private func buildPrompt(system: String, context: String) -> String {
        """
        \(system)

        Context JSON:
        \(context)
        """
    }
}

// MARK: - LLMProvider conformance

extension OllamaLLMProvider: LLMProvider {}
