import Testing
@testable import SolomonCore

@Test func versionIsSet() {
    #expect(!Solomon.version.isEmpty)
}
