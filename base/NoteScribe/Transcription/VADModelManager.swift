import Foundation
import OSLog
import CoreML

/// Loads the bundled Silero CoreML VAD model so FluidAudio can run offline.
class VADModelManager {
    static let shared = VADModelManager()
    private let logger = Logger(subsystem: "VADModelManager", category: "ModelManagement")
    private let fileManager = FileManager.default

    private init() {}

    private var appSupportModelURL: URL {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("FluidAudio", isDirectory: true)
            .appendingPathComponent("Models", isDirectory: true)
            .appendingPathComponent("silero-vad-coreml", isDirectory: true)
            .appendingPathComponent("silero-vad-unified-256ms-v6.0.0.mlmodelc", isDirectory: true)
    }

    private var bundledModelURL: URL? {
        guard let resourceURL = Bundle.main.resourceURL else { return nil }
        // Folder reference places the directory directly under Resources
        let directPath = resourceURL
            .appendingPathComponent("silero-vad-coreml", isDirectory: true)
            .appendingPathComponent("silero-vad-unified-256ms-v6.0.0.mlmodelc", isDirectory: true)
        if fileManager.fileExists(atPath: directPath.path) {
            return directPath
        }

        // Fallback to nested path if Xcode ever nests under BundledModels/VAD
        let nestedPath = resourceURL
            .appendingPathComponent("BundledModels/VAD/silero-vad-coreml", isDirectory: true)
            .appendingPathComponent("silero-vad-unified-256ms-v6.0.0.mlmodelc", isDirectory: true)
        return fileManager.fileExists(atPath: nestedPath.path) ? nestedPath : nil
    }

    /// Returns an MLModel loaded from the cached copy (preferred) or from the app bundle.
    func loadModel() throws -> MLModel {
        let modelURL: URL
        if fileManager.fileExists(atPath: appSupportModelURL.path) {
            modelURL = appSupportModelURL
        } else if let bundledURL = bundledModelURL {
            modelURL = bundledURL
        } else {
            logger.error("VAD model not found in cache or bundle")
            throw ModelBundleManagerError.bundleNotFound
        }

        let configuration = MLModelConfiguration()
        configuration.computeUnits = .all
        logger.info("Loading VAD model from \(modelURL.path)")
        return try MLModel(contentsOf: modelURL, configuration: configuration)
    }
}
