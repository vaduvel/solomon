import Foundation
import SolomonCore

/// Wrapper peste `SolomonContextCoder` — serializare context → JSON string pentru LLM.
///
/// Folosit de fiecare builder de moment înainte de a trimite contextul la LLM.
/// Strategia de chei Solomon (camelCase ↔ snake_case cu reguli cifră-literă) e
/// aplicată automat de `SolomonContextCoder`.
public struct JSONContextBuilder: Sendable {

    public init() {}

    // MARK: - Encode

    /// Serializează un context encodable în JSON compact (fără spații extra).
    public func build<T: Encodable>(_ context: T) throws -> String {
        try SolomonContextCoder.encodeAsJSONString(context)
    }

    /// Serializează un context în JSON pretty-printed (pentru debugging / logging).
    public func buildPretty<T: Encodable>(_ context: T) throws -> String {
        try SolomonContextCoder.encodeAsPrettyJSONString(context)
    }

    // MARK: - Validation

    /// Verifică că JSON-ul produs poate fi decodat înapoi în același tip (round-trip).
    ///
    /// Util în teste pentru a valida că schema e corectă.
    public func roundTrip<T: Codable>(_ context: T) throws -> T {
        try SolomonContextCoder.roundTrip(context)
    }

    /// Estimare token-uri (aprox. 4 caractere per token GPT-4; MLX Gemma e similar).
    public func estimatedTokenCount<T: Encodable>(_ context: T) throws -> Int {
        let json = try build(context)
        return max(1, json.count / 4)
    }

    // MARK: - JSON key validation

    /// Extrage cheile de top-level din JSON-ul produs.
    /// Util în teste pentru a verifica că `moment_type`, `user` etc. sunt prezente.
    public func topLevelKeys<T: Encodable>(_ context: T) throws -> [String] {
        let json = try build(context)
        guard let data = json.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return []
        }
        return Array(obj.keys).sorted()
    }
}
