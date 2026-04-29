import Foundation
import Observation
import SwiftUI
import SolomonLLM

// MARK: - ModelDownloadService
//
// State observable pentru UI. Se conectează la MLXLLMProvider și surface state-ul
// (notDownloaded / downloading / loaded / failed) către SwiftUI views.

@Observable @MainActor
public final class ModelDownloadService {

    public static let shared = ModelDownloadService()

    // MARK: - Observable state

    public private(set) var state: MLXLLMProvider.State = .notDownloaded
    public private(set) var config: MLXLLMProvider.Config = .gemmaE2B
    public private(set) var downloadedSizeBytes: Int64 = 0

    // MARK: - Internals

    private var provider: MLXLLMProvider?
    private let downloader = MLXModelDownloader()

    private init() {
        Task { await loadInitialState() }
    }

    // MARK: - Public API

    public func setProvider(_ p: MLXLLMProvider) {
        self.provider = p
        Task { await syncState() }
    }

    /// Returnează un LLMProvider gata de inferență — MLX dacă e descărcat,
    /// altfel TemplateLLMProvider ca fallback sigur. Apelat din TodayViewModel
    /// și orice MomentEngine la construcție.
    public func makeLLMProvider() -> any LLMProvider {
        if let p = provider {
            return SmartLLMProvider(primary: p, fallback: TemplateLLMProvider())
        }
        // Provider nu a fost creat încă (race la cold start) — creăm unul instant
        let p = MLXLLMProvider(config: config)
        self.provider = p
        return SmartLLMProvider(primary: p, fallback: TemplateLLMProvider())
    }

    public func setConfig(_ newConfig: MLXLLMProvider.Config) {
        self.config = newConfig
        Task {
            // Verifică dacă noul config e deja descărcat
            let downloaded = await downloader.isModelDownloaded(modelId: newConfig.modelId)
            self.downloadedSizeBytes = await downloader.sizeOnDisk(modelId: newConfig.modelId)
            self.state = downloaded ? .loaded : .notDownloaded
        }
    }

    /// Pornește download-ul + load. Apelat din onboarding sau Settings.
    public func startDownloadAndLoad() async {
        // Creem provider-ul dacă nu există — fără recursie
        if provider == nil { await createProvider() }
        guard let provider else { return }
        do {
            try await provider.preloadModel()
            await syncState()
        } catch {
            await syncState()
        }
    }

    public func deleteCurrentModel() async {
        try? await downloader.deleteModel(modelId: config.modelId)
        await provider?.unloadModel()
        await syncState()
    }

    // MARK: - Sync

    private func createProvider() async {
        let p = MLXLLMProvider(config: config)
        self.provider = p
        await syncState()
    }

    private func loadInitialState() async {
        await createProvider()
        downloadedSizeBytes = await downloader.sizeOnDisk(modelId: config.modelId)
        let downloaded = await downloader.isModelDownloaded(modelId: config.modelId)
        if downloaded {
            state = .loaded
        }
    }

    private func syncState() async {
        guard let provider else { return }
        state = await provider.currentState()
        downloadedSizeBytes = await downloader.sizeOnDisk(modelId: config.modelId)
    }

    // MARK: - Display helpers

    public var stateLabel: String {
        switch state {
        case .notDownloaded:
            return "Nedescărcat"
        case .downloading(let p):
            return "Descărcare \(Int(p * 100))%"
        case .loaded:
            return "Activ"
        case .loadFailed(let reason):
            return "Eroare: \(reason)"
        }
    }

    public var stateProgress: Double {
        if case .downloading(let p) = state { return p }
        if case .loaded = state { return 1.0 }
        return 0
    }

    public var sizeOnDiskFormatted: String {
        let f = ByteCountFormatter()
        f.allowedUnits = [.useGB, .useMB]
        f.countStyle = .binary
        return f.string(fromByteCount: downloadedSizeBytes)
    }

    public var configSizeFormatted: String {
        let f = ByteCountFormatter()
        f.allowedUnits = [.useGB, .useMB]
        f.countStyle = .binary
        return f.string(fromByteCount: config.approximateSizeBytes)
    }
}
