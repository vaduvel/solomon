import Testing
@testable import SolomonWeb

/// Smoke test — modulul SolomonWeb e importat corect și constantele sunt prezente.
@Suite struct SolomonWebSmokeTests {
    @Test func primaryProviderIsDuckDuckGo() {
        #expect(SolomonWeb.primarySearchProvider == "DuckDuckGo")
    }

    @Test func primaryProviderURLContainsDDG() {
        #expect(SolomonWeb.primarySearchProviderURL.contains("duckduckgo"))
    }

    @Test func versionStringNotEmpty() {
        #expect(!SolomonWeb.version.isEmpty)
    }
}
