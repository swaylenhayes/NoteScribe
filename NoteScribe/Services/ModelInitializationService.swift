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

        logger.info("First launch detected - initializing bundled Parakeet model...")

        // Copy whichever Parakeet model is bundled (v2 or v3)
        try await copyParakeetModels()
        try await copyVADModel()

        // Mark as initialized
        UserDefaults.standard.set(true, forKey: modelsInitializedKey)
        logger.info("Model initialization complete")
    }

    // MARK: - Parakeet Model (auto-detect v2 or v3)

    private func copyParakeetModels() async throws {
        guard let resourcesDir = bundledResourcesDirectory else {
            logger.error("Bundle resources directory not found")
            throw ModelInitializationError.bundleNotFound
        }

        // Create FluidAudio models directory if needed
        try fileManager.createDirectory(at: fluidAudioDirectory, withIntermediateDirectories: true)

        // Auto-detect which Parakeet model is bundled (v2 or v3)
        guard let (modelName, sourceURL) = detectBundledParakeetModel(in: resourcesDir) else {
            logger.error("No Parakeet model found in bundle")
            throw ModelInitializationError.bundleNotFound
        }

        let destinationURL = fluidAudioDirectory.appendingPathComponent(modelName)

        // If an incomplete cache exists (e.g., missing Preprocessor.mlmodelc), nuke and recopy
        if fileManager.fileExists(atPath: destinationURL.path) {
            let preprocessorPath = destinationURL.appendingPathComponent("Preprocessor.mlmodelc").path
            if fileManager.fileExists(atPath: preprocessorPath) {
                logger.info("Parakeet model already exists: \(modelName)")
                return
            } else {
                logger.warning("Parakeet model cache incomplete; recreating from bundle")
                try fileManager.removeItem(at: destinationURL)
            }
        }

        logger.info("Copying Parakeet model: \(modelName)...")
        try fileManager.copyItem(at: sourceURL, to: destinationURL)
        logger.info("Parakeet model copied successfully")
    }

    /// Detects which Parakeet model is bundled and returns its name and source URL
    private func detectBundledParakeetModel(in resourcesDir: URL) -> (name: String, url: URL)? {
        let modelNames = ["parakeet-tdt-0.6b-v3-coreml", "parakeet-tdt-0.6b-v2-coreml"]

        // Check all possible paths where models might be located
        let searchPaths = [
            "Parakeet",                    // New unified build: Resources/Parakeet/
            "",                            // Direct in Resources/
            "BundledModels/Parakeet"       // Legacy nested path
        ]

        for searchPath in searchPaths {
            let basePath = searchPath.isEmpty ? resourcesDir : resourcesDir.appendingPathComponent(searchPath)
            for modelName in modelNames {
                let modelPath = basePath.appendingPathComponent(modelName)
                if fileManager.fileExists(atPath: modelPath.path) {
                    return (modelName, modelPath)
                }
            }
        }

        return nil
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
