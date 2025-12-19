import Foundation
import os.log

/// Service responsible for initializing bundled models on first app launch
class ModelInitializationService {
    private let logger = Logger(subsystem: "com.swaylenhayes.apps.notescribe", category: "ModelInitialization")
    private let fileManager = FileManager.default

    // MARK: - Directories

    private var appSupportDirectory: URL {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("com.swaylenhayes.apps.notescribe")
    }

    private var fluidAudioDirectory: URL {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("FluidAudio")
            .appendingPathComponent("Models")
    }

    private var bundledResourcesDirectory: URL? {
        guard let resourcePath = Bundle.main.resourcePath else { return nil }
        return URL(fileURLWithPath: resourcePath)
    }

    // MARK: - Initialization Check

    /// Checks if models have been initialized and copies them if needed
    func initializeModelsIfNeeded() async throws {
        let modelsInitializedKey = "NoteScribeModelsInitializedV1"

        // Check if we've already initialized models for this version
        if UserDefaults.standard.bool(forKey: modelsInitializedKey) {
            logger.info("Models already initialized for v1.2")
            return
        }

        logger.info("First launch detected - initializing Parakeet V3 model...")

        // Copy Parakeet V3 model only (if bundled)
        try await copyParakeetModels()
        try await copyVADModel()

        // Mark as initialized
        UserDefaults.standard.set(true, forKey: modelsInitializedKey)
        logger.info("Model initialization complete")
    }

    // MARK: - Parakeet V3 Model

    private func copyParakeetModels() async throws {
        guard let resourcesDir = bundledResourcesDirectory else {
            logger.error("Bundle resources directory not found")
            throw ModelInitializationError.bundleNotFound
        }

        // Create FluidAudio models directory if needed
        try fileManager.createDirectory(at: fluidAudioDirectory, withIntermediateDirectories: true)

        // Parakeet V3 (CoreML)
        let modelName = "parakeet-tdt-0.6b-v3-coreml"
        // Folder references in Xcode land the bundle at Resources/<lastPathComponent>,
        // so prefer the simple folder name and fall back to the legacy nested path.
        let candidatePaths = [
            modelName,
            "BundledModels/Parakeet/\(modelName)"
        ]
        guard let sourceURL = candidatePaths
            .map({ resourcesDir.appendingPathComponent($0) })
            .first(where: { fileManager.fileExists(atPath: $0.path) }) else {
            logger.error("Parakeet V3 model not found in bundle")
            throw ModelInitializationError.bundleNotFound
        }

        let destinationURL = fluidAudioDirectory.appendingPathComponent(modelName)

        // If an incomplete cache exists (e.g., missing Preprocessor.mlmodelc), nuke and recopy
        if fileManager.fileExists(atPath: destinationURL.path) {
            let preprocessorPath = destinationURL.appendingPathComponent("Preprocessor.mlmodelc").path
            if fileManager.fileExists(atPath: preprocessorPath) {
                logger.info("Parakeet V3 model already exists")
                return
            } else {
                logger.warning("Parakeet V3 model cache incomplete; recreating from bundle")
                try fileManager.removeItem(at: destinationURL)
            }
        }

        logger.info("Copying Parakeet V3 model...")
        try fileManager.copyItem(at: sourceURL, to: destinationURL)
        logger.info("Parakeet V3 model copied successfully")
    }

    // MARK: - VAD Model

    private func copyVADModel() async throws {
        let modelName = "silero-vad-coreml"
        let bundledModelFolderName = "silero-vad-unified-256ms-v6.0.0.mlmodelc"
        let candidatePaths = [
            "VAD/\(modelName)",
            modelName
        ]

        guard let resourcesDir = bundledResourcesDirectory else {
            logger.error("Bundle resources directory not found")
            throw ModelInitializationError.bundleNotFound
        }

        guard let sourceURL = candidatePaths
            .map({ resourcesDir.appendingPathComponent($0) })
            .first(where: { fileManager.fileExists(atPath: $0.path) }) else {
            logger.error("VAD model not found in bundle")
            throw ModelInitializationError.bundleNotFound
        }

        let destinationURL = fluidAudioDirectory.appendingPathComponent(modelName)
        let expectedModelPath = destinationURL
            .appendingPathComponent(bundledModelFolderName)
            .path

        // If VAD cache exists but is incomplete, delete and recopy
        if fileManager.fileExists(atPath: destinationURL.path) {
            if fileManager.fileExists(atPath: expectedModelPath) {
                logger.info("VAD model already exists")
                return
            } else {
                logger.warning("VAD model cache incomplete; recreating from bundle")
                try fileManager.removeItem(at: destinationURL)
            }
        }

        logger.info("Copying VAD model...")
        try fileManager.copyItem(at: sourceURL, to: destinationURL)
        logger.info("VAD model copied successfully")
    }
}

// MARK: - Errors

enum ModelInitializationError: Error, LocalizedError {
    case bundleNotFound
    case copyFailed(String)

    var errorDescription: String? {
        switch self {
        case .bundleNotFound:
            return "Could not find bundled models in application bundle"
        case .copyFailed(let details):
            return "Failed to copy models: \(details)"
        }
    }
}
