import Testing
@testable import SolomonLLM

@Suite struct SolomonLLMSmokeTests {

    @Test func defaultModelIsGemma() {
        #expect(SolomonLLM.defaultModel.lowercased().contains("gemma"))
    }

    @Test func defaultBaseURLIsLocalhost() {
        #expect(SolomonLLM.defaultBaseURL.contains("localhost"))
    }

    @Test func versionNotEmpty() {
        #expect(!SolomonLLM.version.isEmpty)
    }

    @Test func ollamaProviderDefaultsAreCorrect() {
        let p = OllamaLLMProvider()
        #expect(p.model == "gemma4:e2b")
        #expect(p.baseURL == "http://localhost:11434")
        #expect(p.temperature > 0)
        #expect(p.timeoutSeconds >= 60)
    }

    @Test func ollamaProviderCustomInit() {
        let p = OllamaLLMProvider(
            baseURL: "http://localhost:8080",
            model: "gemma4:e4b",
            temperature: 0.7,
            timeoutSeconds: 120
        )
        #expect(p.model == "gemma4:e4b")
        #expect(p.baseURL == "http://localhost:8080")
        #expect(p.temperature == 0.7)
    }
}
