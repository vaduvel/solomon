import Foundation

// MARK: - MLXModelDownloader
//
// Descarcă fișierele model `.safetensors` + tokenizer + config de pe HuggingFace
// pentru un repository (ex: "mlx-community/gemma-2-2b-it-4bit").
//
// Stochează în Application Support / SolomonModels / <repo>/ pentru a persista
// între reinstalări de app (iOS pune Application Support în iCloud doar dacă e
// configurat, default e local).
//
// Fișiere standard într-un repo MLX format:
//   - config.json
//   - tokenizer.json (sau tokenizer.model)
//   - tokenizer_config.json
//   - special_tokens_map.json
//   - model.safetensors  (sau model-00001-of-00002.safetensors etc.)
//   - model.safetensors.index.json (când e split în multiple files)

public actor MLXModelDownloader {

    public init() {}

    public typealias ProgressHandler = @Sendable (Double) -> Void

    public enum DownloadError: Error, LocalizedError, Sendable {
        case missingDocumentsFolder
        case manifestFetchFailed
        case fileFetchFailed(file: String, status: Int)

        public var errorDescription: String? {
            switch self {
            case .missingDocumentsFolder:
                return "Folder Application Support indisponibil pe acest device."
            case .manifestFetchFailed:
                return "Nu s-a putut descărca lista de fișiere de pe HuggingFace."
            case .fileFetchFailed(let file, let status):
                return "Eșec descărcare \(file) (HTTP \(status))."
            }
        }
    }

    // MARK: - Public API

    /// Verifică dacă modelul e prezent local. Dacă nu, îl descarcă în întregime.
    public func ensureModelDownloaded(
        modelId: String,
        progress: ProgressHandler? = nil
    ) async throws {
        let dir = try modelDirectory(for: modelId)
        if isModelComplete(in: dir) {
            progress?(1.0)
            return
        }

        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        // 1. Listează fișierele necesare via HuggingFace API
        let manifest = try await fetchManifest(modelId: modelId)
        let totalBytes = manifest.reduce(0) { $0 + $1.size }

        // 2. Descarcă fișier cu fișier, calculând progress cumulativ
        // (downloadedBytes e mutat doar în actor context — safe)
        downloadedBytes = 0
        for entry in manifest {
            let target = dir.appendingPathComponent(entry.path)
            if let size = try? FileManager.default.attributesOfItem(atPath: target.path)[.size] as? Int64,
               size == entry.size {
                downloadedBytes += entry.size
                progress?(min(1.0, Double(downloadedBytes) / Double(max(1, totalBytes))))
                continue
            }

            let bytes = try await downloadFile(modelId: modelId, path: entry.path, to: target)
            downloadedBytes += bytes
            progress?(min(1.0, Double(downloadedBytes) / Double(max(1, totalBytes))))
        }

        progress?(1.0)
    }

    private var downloadedBytes: Int64 = 0

    public func deleteModel(modelId: String) throws {
        let dir = try modelDirectory(for: modelId)
        if FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.removeItem(at: dir)
        }
    }

    public func modelDirectory(for modelId: String) throws -> URL {
        let fm = FileManager.default
        guard let appSupport = try? fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ) else {
            throw DownloadError.missingDocumentsFolder
        }
        let safe = modelId.replacingOccurrences(of: "/", with: "__")
        return appSupport.appendingPathComponent("SolomonModels/\(safe)", isDirectory: true)
    }

    public func isModelDownloaded(modelId: String) async -> Bool {
        guard let dir = try? modelDirectory(for: modelId) else { return false }
        return isModelComplete(in: dir)
    }

    public func sizeOnDisk(modelId: String) async -> Int64 {
        guard let dir = try? modelDirectory(for: modelId) else { return 0 }
        return computeFolderSize(at: dir)
    }

    // MARK: - Internals

    private struct ManifestEntry: Sendable {
        let path: String
        let size: Int64
    }

    /// Cele mai uzuale fișiere într-un repo MLX. Prima trecere folosim un set fix.
    /// Pentru robusteță, fetchăm manifest-ul real prin HuggingFace API.
    private static let requiredFilesFallback: [String] = [
        "config.json",
        "tokenizer.json",
        "tokenizer_config.json",
        "special_tokens_map.json",
        "model.safetensors"
    ]

    private func isModelComplete(in dir: URL) -> Bool {
        let fm = FileManager.default
        guard fm.fileExists(atPath: dir.path) else { return false }
        // Heuristic: există config.json + tokenizer + cel puțin un .safetensors
        let configExists = fm.fileExists(atPath: dir.appendingPathComponent("config.json").path)
        let tokenizerExists = fm.fileExists(atPath: dir.appendingPathComponent("tokenizer.json").path)
            || fm.fileExists(atPath: dir.appendingPathComponent("tokenizer.model").path)
        guard configExists, tokenizerExists else { return false }

        // Verifică prezența cel puțin unui fișier .safetensors
        guard let contents = try? fm.contentsOfDirectory(atPath: dir.path) else { return false }
        return contents.contains { $0.hasSuffix(".safetensors") }
    }

    private func fetchManifest(modelId: String) async throws -> [ManifestEntry] {
        // HuggingFace tree API: https://huggingface.co/api/models/{repo}/tree/main
        guard let url = URL(string: "https://huggingface.co/api/models/\(modelId)/tree/main") else {
            throw DownloadError.manifestFetchFailed
        }
        var req = URLRequest(url: url)
        req.timeoutInterval = 30
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
            throw DownloadError.manifestFetchFailed
        }
        // Parse JSON: array of {path, size, type}
        struct TreeItem: Decodable { let path: String; let size: Int64?; let type: String }
        let items = (try? JSONDecoder().decode([TreeItem].self, from: data)) ?? []
        let files = items.filter { $0.type == "file" }
        let relevant = files.filter { item in
            let p = item.path.lowercased()
            return p.hasSuffix(".json") || p.hasSuffix(".safetensors") || p.hasSuffix(".model") || p.hasSuffix(".bin")
        }
        if relevant.isEmpty {
            return Self.requiredFilesFallback.map { ManifestEntry(path: $0, size: 100_000_000) }
        }
        return relevant.map { ManifestEntry(path: $0.path, size: $0.size ?? 100_000_000) }
    }

    /// Descarcă un fișier și returnează numărul de bytes scrisi pe disc.
    private func downloadFile(
        modelId: String,
        path: String,
        to destination: URL
    ) async throws -> Int64 {
        guard let url = URL(string: "https://huggingface.co/\(modelId)/resolve/main/\(path)") else {
            throw DownloadError.fileFetchFailed(file: path, status: -1)
        }
        var req = URLRequest(url: url)
        req.timeoutInterval = 120

        let (tempURL, resp) = try await URLSession.shared.download(for: req)
        guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
            let status = (resp as? HTTPURLResponse)?.statusCode ?? -1
            throw DownloadError.fileFetchFailed(file: path, status: status)
        }

        let fm = FileManager.default
        try? fm.removeItem(at: destination)
        try fm.moveItem(at: tempURL, to: destination)

        return (try? fm.attributesOfItem(atPath: destination.path)[.size] as? Int64) ?? 0
    }

    private func computeFolderSize(at url: URL) -> Int64 {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                total += Int64(size)
            }
        }
        return total
    }
}
