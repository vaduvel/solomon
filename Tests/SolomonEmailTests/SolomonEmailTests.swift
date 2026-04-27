import Testing
@testable import SolomonEmail

@Test func moduleVersionIsSet() {
    #expect(!SolomonEmail.moduleVersion.isEmpty)
}
