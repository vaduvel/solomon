import Testing
@testable import SolomonLLM

@Test func modelMetadataIsSet() {
    #expect(SolomonLLM.modelName.contains("Gemma"))
    #expect(SolomonLLM.modelSizeGB > 0)
}
