import Foundation
import CryptoKit

// MARK: - DeterministicUUID
//
// Generează UUID-uri deterministice (același input → același UUID) folosit
// pentru deduplicare la ingestie de notificări/email-uri.
//
// Algoritm: SHA-256(input) → primii 16 bytes → UUID (cu variant/version setate
// după RFC 4122 §4.4 pentru a fi un UUIDv5-like name-based identifier).
//
// **De ce nu UUIDv5 pur**: UUIDv5 cere namespace UUID + name string.  Aici nu
// avem nevoie de namespace — folosim doar SHA-256 al unui string compus
// (ex. "notification|TEXT|TIMESTAMP").

public extension UUID {

    /// Construiește un UUID deterministic dintr-un string sursă.
    ///
    /// Folosit pentru deduplicare: același conținut → același UUID → repository
    /// upsert detectează duplicatul și nu creează un rând nou.
    ///
    /// - Parameter source: stringul de unicizare (ex. "notif|raw text|epoch_minute")
    /// - Returns: UUID identic la fiecare apel cu același input.
    static func deterministic(from source: String) -> UUID {
        let data = Data(source.utf8)
        let digest = SHA256.hash(data: data)

        // Luăm primii 16 bytes din digestul SHA-256.
        var bytes = Array(digest.prefix(16))

        // Setăm bits version (UUIDv5 = 0101) și variant (RFC 4122 = 10xx) ca să
        // fie un UUID valid sintactic.
        bytes[6] = (bytes[6] & 0x0F) | 0x50   // version 5
        bytes[8] = (bytes[8] & 0x3F) | 0x80   // RFC 4122 variant

        return UUID(uuid: (
            bytes[0],  bytes[1],  bytes[2],  bytes[3],
            bytes[4],  bytes[5],  bytes[6],  bytes[7],
            bytes[8],  bytes[9],  bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }
}
