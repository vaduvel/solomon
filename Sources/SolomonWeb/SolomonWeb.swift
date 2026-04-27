import Foundation
import SolomonCore

/// Modulul SolomonWeb — web search client cu DDG Instant Answers, cache TTL, whitelist domenii și scam detection.
///
/// Componente principale:
/// - `SolomonWebClient` — actor orchestrator (cache + DDG + whitelist + scam)
/// - `DDGInstantAnswerClient` — HTTP client DuckDuckGo Instant Answer API
/// - `WebSearchCache` — actor cache în memorie cu TTL per query type
/// - `WebWhitelistFilter` — filtrare domenii aprobate (BNR, ANAF, conso.ro etc.)
/// - `ScamPatternMatcher` — detectare pattern-uri de scam în texte RO
///
/// Spec: §3.1 (DDG), §9 (whitelist), §10.4 (scam patterns).
public enum SolomonWeb {
    public static let version = "1.0.0"
    public static let primarySearchProvider = "DuckDuckGo"
    public static let primarySearchProviderURL = "https://api.duckduckgo.com/"
}
