import Testing
@testable import SolomonAnalytics

@Test func moduleVersionIsSet() {
    #expect(!SolomonAnalytics.moduleVersion.isEmpty)
}
