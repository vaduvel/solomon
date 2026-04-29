import Foundation
import os

// MARK: - Solomon structured logging
//
// FAZA C2: înlocuim print() din production paths cu os.Logger structurat,
// vizibil în Console.app pe device pilot și filtrabil per subsystem/category.

public extension Logger {
    /// Subsistem comun pentru toate logurile Solomon
    static let solomonSubsystem = "ro.solomon.app"

    static let onboarding   = Logger(subsystem: solomonSubsystem, category: "Onboarding")
    static let persistence  = Logger(subsystem: solomonSubsystem, category: "Persistence")
    static let llm          = Logger(subsystem: solomonSubsystem, category: "LLM")
    static let moments      = Logger(subsystem: solomonSubsystem, category: "Moments")
    static let ingestion    = Logger(subsystem: solomonSubsystem, category: "Ingestion")
    static let bgTask       = Logger(subsystem: solomonSubsystem, category: "BackgroundTask")
    static let download     = Logger(subsystem: solomonSubsystem, category: "ModelDownload")
    static let app          = Logger(subsystem: solomonSubsystem, category: "App")
}
