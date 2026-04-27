import Foundation

/// Encoder/decoder configurat pentru JSON-ul livrat către LLM (spec §6.1).
///
/// Foloseste o pereche de strategii snake_case **custom** simetrice — corecte
/// pentru cazurile cu cifre („count_180d", „amount_total_180d") pe care
/// Foundation `.convertToSnakeCase` / `.convertFromSnakeCase` le rezolvă
/// asimetric și sparg round-trip-ul.
///
/// Reguli encoder (`SolomonKeyStrategy.toSnakeCase`):
/// - inserează `_` la trecere literă-mică → MAJUSCULĂ
/// - inserează `_` la trecere literă → cifră
/// - **nu** inserează `_` la trecere cifră → literă
///
/// Reguli decoder (split la `_`):
/// - prima parte rămâne lowercase
/// - părțile următoare care încep cu literă → capitalize prima literă
/// - părțile care încep cu cifră → rămân ca atare
///
/// Exemple validate cu spec §6.2:
/// ```
/// monthlyAvg              ↔ monthly_avg
/// overdraftUsedCount180d  ↔ overdraft_used_count_180d
/// amountTotal180d         ↔ amount_total_180d
/// ```
public enum SolomonContextCoder {

    public static func encoder(pretty: Bool = false) -> JSONEncoder {
        let enc = JSONEncoder()
        enc.keyEncodingStrategy = SolomonKeyStrategy.toSnakeCase
        enc.dateEncodingStrategy = .iso8601
        if pretty {
            enc.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        } else {
            enc.outputFormatting = [.withoutEscapingSlashes]
        }
        return enc
    }

    public static func decoder() -> JSONDecoder {
        let dec = JSONDecoder()
        dec.keyDecodingStrategy = SolomonKeyStrategy.fromSnakeCase
        dec.dateDecodingStrategy = .iso8601
        return dec
    }

    public static func roundTrip<T: Codable>(_ value: T) throws -> T {
        let data = try encoder().encode(value)
        return try decoder().decode(T.self, from: data)
    }

    public static func encodeAsJSONString<T: Encodable>(_ value: T) throws -> String {
        let data = try encoder(pretty: false).encode(value)
        return String(data: data, encoding: .utf8) ?? ""
    }

    public static func encodeAsPrettyJSONString<T: Encodable>(_ value: T) throws -> String {
        let data = try encoder(pretty: true).encode(value)
        return String(data: data, encoding: .utf8) ?? ""
    }
}

// MARK: - Solomon snake_case strategy

public enum SolomonKeyStrategy {

    /// Strategie de encoding pentru chei: camelCase → snake_case Solomon.
    public static var toSnakeCase: JSONEncoder.KeyEncodingStrategy {
        .custom { codingPath in
            let last = codingPath.last!
            if last.intValue != nil { return last } // array indices
            let snake = SolomonKeyStrategy.camelToSnake(last.stringValue)
            return SolomonAnyKey(stringValue: snake)
        }
    }

    /// Strategie de decoding pentru chei: snake_case → camelCase Solomon.
    public static var fromSnakeCase: JSONDecoder.KeyDecodingStrategy {
        .custom { codingPath in
            let last = codingPath.last!
            if last.intValue != nil { return last } // array indices
            let camel = SolomonKeyStrategy.snakeToCamel(last.stringValue)
            return SolomonAnyKey(stringValue: camel)
        }
    }

    /// Convertește camelCase în snake_case respectând spec-ul Solomon:
    /// - `_` la literă-mică → MAJUSCULĂ
    /// - `_` la literă → cifră
    /// - **fără** `_` la cifră → literă (păstrăm „180d" împreună)
    public static func camelToSnake(_ input: String) -> String {
        var result = ""
        var previous: Character? = nil
        for char in input {
            defer { previous = char }
            if char.isUppercase {
                if let p = previous, p.isLetter || p.isNumber {
                    result.append("_")
                }
                result.append(Character(char.lowercased()))
                continue
            }
            if char.isNumber {
                if let p = previous, p.isLetter, p.isLowercase {
                    result.append("_")
                }
                result.append(char)
                continue
            }
            result.append(char)
        }
        return result
    }

    /// Inversa lui `camelToSnake` — split la `_` și capitalize părțile literelor.
    /// Părțile care încep cu cifră rămân așa cum sunt (ex: „180d").
    public static func snakeToCamel(_ input: String) -> String {
        let parts = input.split(separator: "_", omittingEmptySubsequences: false)
        guard let first = parts.first else { return input }
        var result = String(first)
        for part in parts.dropFirst() {
            guard let head = part.first else { continue }
            if head.isLetter {
                result.append(head.uppercased())
                result.append(contentsOf: part.dropFirst())
            } else {
                result.append(contentsOf: part)
            }
        }
        return result
    }
}

/// Coding key generic pentru a returna stringValue arbitrar din strategy custom.
private struct SolomonAnyKey: CodingKey {
    let stringValue: String
    let intValue: Int? = nil
    init(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { return nil }
}
