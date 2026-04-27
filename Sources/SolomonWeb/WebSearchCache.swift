import Foundation

/// Cache în memorie thread-safe pentru rezultatele web search.
///
/// TTL-uri configurate per `WebQueryType` (spec §3.1):
/// - curs valutar: 6h
/// - dobânzi: 24h
/// - scam alerts: 1h
///
/// Cache-ul se pierde la restart al aplicației — comportament intenționat
/// (datele sunt impersonale, nu sensibile).
public actor WebSearchCache {

    private struct Entry {
        var result: WebSearchResult
        var expiresAt: Date
        var isExpired: Bool { expiresAt < Date() }
    }

    private var store: [String: Entry] = [:]

    public init() {}

    // MARK: - Public API

    /// Returnează rezultatul din cache dacă e valid (neexpirat).
    public func get(key: String) -> WebSearchResult? {
        guard let entry = store[key] else { return nil }
        if entry.isExpired {
            store.removeValue(forKey: key)
            return nil
        }
        return entry.result.cached()
    }

    /// Stochează un rezultat cu TTL dat în secunde.
    public func set(key: String, result: WebSearchResult, ttl: TimeInterval) {
        store[key] = Entry(
            result: result,
            expiresAt: Date().addingTimeInterval(ttl)
        )
    }

    /// Șterge o intrare specifică (ex: forțare refresh).
    public func invalidate(key: String) {
        store.removeValue(forKey: key)
    }

    /// Șterge tot cache-ul.
    public func purgeAll() {
        store.removeAll()
    }

    /// Șterge intrările expirate (housekeeping).
    public func purgeExpired() {
        store = store.filter { !$0.value.isExpired }
    }

    /// Numărul curent de intrări (incluzând cele expirate).
    public var count: Int { store.count }

    /// Numărul de intrări valide (neexpirate).
    public var validCount: Int { store.values.filter { !$0.isExpired }.count }
}
