import Testing
@testable import SolomonStorage

@Test func schemaVersionIsPositive() {
    #expect(SolomonStorage.schemaVersion >= 1)
}
