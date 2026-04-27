import Testing
@testable import SolomonWeb

@Test func primaryProviderIsDuckDuckGo() {
    #expect(SolomonWeb.primarySearchProvider == "DuckDuckGo")
}
