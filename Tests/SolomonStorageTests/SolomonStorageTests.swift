import Testing
@testable import SolomonStorage

@Test func moduleVersionIsSet() {
    #expect(!SolomonStorage.moduleVersion.isEmpty)
}

@Test func schemaVersionIsOne() {
    #expect(SolomonStorage.schemaVersion == 1)
}

@Test @MainActor func inMemoryContainerLoadsWithoutError() {
    let ctrl = SolomonPersistenceController.makeInMemory()
    #expect(ctrl.container.persistentStoreCoordinator.persistentStores.count == 1)
}
