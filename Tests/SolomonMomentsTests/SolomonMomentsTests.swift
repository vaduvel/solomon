import Testing
@testable import SolomonMoments
import SolomonCore
import SolomonLLM

// MARK: - Smoke tests

@Suite struct SolomonMomentsSmokeTests {

    @Test func eightMomentsDeclared() {
        #expect(SolomonMoments.momentTypes.count == 8)
    }

    @Test func momentCountIs8() {
        #expect(SolomonMoments.momentCount == 8)
    }

    @Test func versionNotEmpty() {
        #expect(!SolomonMoments.version.isEmpty)
    }

    @Test func momentTypesMatchMomentTypeEnum() {
        let enumTypes = Set(MomentType.allCases.map { $0.rawValue })
        let declared = Set(SolomonMoments.momentTypes)
        #expect(enumTypes == declared)
    }
}

// MARK: - MockLLMProvider tests

@Suite struct MockLLMProviderTests {

    @Test func generateCallCountStartsAtZero() {
        let mock = MockLLMProvider()
        #expect(mock.generateCallCount == 0)
    }

    @Test func generateCallCountIncrementsPerCall() async throws {
        let mock = MockLLMProvider()
        _ = try await mock.generate(systemPrompt: "sys", userContext: "ctx", maxWords: 100)
        _ = try await mock.generate(systemPrompt: "sys", userContext: "ctx", maxWords: 100)
        #expect(mock.generateCallCount == 2)
    }

    @Test func generateReturnsForcedResponseWhenSet() async throws {
        let mock = MockLLMProvider()
        mock.forcedResponse = "Răspuns forțat"
        let response = try await mock.generate(systemPrompt: "sys", userContext: "ctx", maxWords: 50)
        #expect(response == "Răspuns forțat")
    }

    @Test func generateReturnsNonEmptyAutoResponse() async throws {
        let mock = MockLLMProvider()
        let response = try await mock.generate(systemPrompt: "Solomon wow moment test", userContext: "{}", maxWords: 50)
        #expect(!response.isEmpty)
    }

    @Test func generateThrowsWhenShouldThrowIsTrue() async throws {
        let mock = MockLLMProvider()
        mock.shouldThrow = true
        do {
            _ = try await mock.generate(systemPrompt: "sys", userContext: "ctx", maxWords: 50)
            Issue.record("Should have thrown")
        } catch LLMError.generationFailed {
            // OK
        }
    }

    @Test func generateStoresLastSystemPrompt() async throws {
        let mock = MockLLMProvider()
        _ = try await mock.generate(systemPrompt: "prompt_test", userContext: "ctx", maxWords: 50)
        #expect(mock.lastSystemPrompt == "prompt_test")
    }

    @Test func generateStoresLastUserContext() async throws {
        let mock = MockLLMProvider()
        _ = try await mock.generate(systemPrompt: "sys", userContext: "ctx_test", maxWords: 50)
        #expect(mock.lastUserContext == "ctx_test")
    }
}

// MARK: - MomentType maxWords

@Suite struct MomentTypeTests {

    @Test func canIAffordMaxWordsIs60() {
        #expect(MomentType.canIAfford.maxWords == 60)
    }

    @Test func wowMomentMaxWordsIs280() {
        #expect(MomentType.wowMoment.maxWords == 280)
    }

    @Test func spiralAlertMaxWordsIs200() {
        #expect(MomentType.spiralAlert.maxWords == 200)
    }

    @Test func allMomentTypesHavePositiveMaxWords() {
        for type in MomentType.allCases {
            #expect(type.maxWords > 0, "\(type.rawValue) maxWords should be > 0")
        }
    }
}
