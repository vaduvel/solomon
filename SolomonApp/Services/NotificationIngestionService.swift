import Foundation
import SolomonCore
import SolomonStorage
import Combine

// MARK: - NotificationIngestionService
//
// Primește URL-uri de la iOS Shortcuts și le transformă în Transaction-uri stocate.
//
// Flux complet:
//   Bank push notification →
//   iOS Shortcuts automation →
//   solomon://transaction?raw=Plată%2065,00%20RON%20la%20Glovo →
//   SolomonApp.onOpenURL →
//   NotificationIngestionService.ingest(url) →
//   BankNotificationParser.parse(raw:) →
//   TransactionRepository.upsert(_:) →
//   Publishers.lastTransaction emite →
//   MomentOrchestrator re-evaluează (Faza 12+)
//
// Format URL suportat:
//   solomon://transaction?raw=<notificare URL-encoded>
//
// Exemplu Shortcuts action:
//   Open URL: solomon://transaction?raw=[Conținut notificare]

@MainActor
public final class NotificationIngestionService: ObservableObject {

    // MARK: - Singleton

    public static let shared = NotificationIngestionService()

    // MARK: - Published state

    /// Ultima tranzacție parsată — UI poate observa pentru feedback instant.
    @Published public private(set) var lastIngested: Transaction?

    /// Numărul total de tranzacții ingested în sesiunea curentă.
    @Published public private(set) var sessionCount: Int = 0

    /// Eroarea ultimei ingestii (nil dacă succes).
    @Published public private(set) var lastError: IngestionError?

    // MARK: - Dependencies

    private var repository: (any TransactionRepository)?

    // MARK: - Init

    private init() {}

    /// Injectează repository-ul. Apelat din SolomonApp după init PersistenceController.
    public func configure(repository: any TransactionRepository) {
        self.repository = repository
    }

    // MARK: - URL Handling

    /// Procesează un URL de tip `solomon://transaction?raw=...`.
    /// - Returns: `true` dacă URL-ul a fost recunoscut și procesat.
    @discardableResult
    public func ingest(url: URL) -> Bool {
        guard url.scheme == "solomon" else { return false }

        switch url.host {
        case "transaction":
            return handleTransactionURL(url)
        default:
            return false
        }
    }

    // MARK: - Transaction URL

    private func handleTransactionURL(_ url: URL) -> Bool {
        guard
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let rawParam = components.queryItems?.first(where: { $0.name == "raw" })?.value,
            !rawParam.isEmpty
        else {
            lastError = .missingRawParam
            return false
        }

        // Verificare: arată ca o notificare bancară?
        guard BankNotificationParser.looksLikeBankNotification(rawParam) else {
            lastError = .notRecognizedAsBankNotification(rawParam)
            return false
        }

        guard let transaction = BankNotificationParser.parse(raw: rawParam) else {
            lastError = .parseFailed(rawParam)
            return false
        }

        do {
            try repository?.upsert(transaction)
            lastIngested = transaction
            sessionCount += 1
            lastError = nil
            return true
        } catch {
            lastError = .storageFailed(error.localizedDescription)
            return false
        }
    }

    // MARK: - Errors

    public enum IngestionError: LocalizedError, Equatable {
        case missingRawParam
        case notRecognizedAsBankNotification(String)
        case parseFailed(String)
        case storageFailed(String)

        public var errorDescription: String? {
            switch self {
            case .missingRawParam:
                return "URL-ul nu conține parametrul 'raw'."
            case .notRecognizedAsBankNotification(let raw):
                return "Textul nu pare o notificare bancară: \(raw.prefix(60))"
            case .parseFailed(let raw):
                return "Nu am putut parsa suma din: \(raw.prefix(60))"
            case .storageFailed(let msg):
                return "Eroare stocare: \(msg)"
            }
        }

        public static func == (lhs: IngestionError, rhs: IngestionError) -> Bool {
            switch (lhs, rhs) {
            case (.missingRawParam, .missingRawParam): return true
            case (.notRecognizedAsBankNotification(let a), .notRecognizedAsBankNotification(let b)):
                return a == b
            case (.parseFailed(let a), .parseFailed(let b)): return a == b
            case (.storageFailed(let a), .storageFailed(let b)): return a == b
            default: return false
            }
        }
    }
}
