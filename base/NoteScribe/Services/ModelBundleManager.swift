import Foundation
import os

/// Manages copying bundled CoreML models to the FluidAudio cache directory.
/// FluidAudio expects models in ~/Library/Application Support/FluidAudio/Models/<model-name>/
///
/// This manager is idempotent: it checks if all required files exist in the cache
/// before every load attempt, and re-copies from the bundle if anything is missing.
enum ModelBundleManager {
    private static let logger = Logger(subsystem: "com.swaylenhayes.apps.notescribe", category: "ModelBundleManager")
    private static let fileManager = FileManager.default
    private typealias NamedModelDirectory = (name: String, url: URL)

    /// The FluidAudio cache directory for models
    private static var fluidAudioModelsDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("FluidAudio", isDirectory: true)
            .appendingPathComponent("Models", isDirectory: true)
    }

    /// Required Parakeet model files
    private static let parakeetModelFiles = [
        "Encoder.mlmodelc",
        "Decoder.mlmodelc",
        "JointDecision.mlmodelc",
        "Preprocessor.mlmodelc"
    ]
    private static let parakeetModelNames = [
        "parakeet-tdt-0.6b-v3-coreml",
        "parakeet-tdt-0.6b-v2-coreml"
    ]

    /// Vocabulary files (at least one required)
    private static let vocabFiles = [
        "parakeet_v3_vocab.json",
        "parakeet_vocab.json"
    ]

    /// VAD model file
    private static let vadModelFile = "silero-vad-unified-256ms-v6.0.0.mlmodelc"

    /// Ensures bundled models are copied to the FluidAudio cache directory.
    /// Returns true if models are ready to use.
    @discardableResult
    static func ensureModelsAvailable() throws -> Bool {
        guard let resourcePath = Bundle.main.resourcePath else {
            logger.error("No resource path in bundle")
            return false
        }
        let bundleURL = URL(fileURLWithPath: resourcePath)

        // Prefer bundled models, then fall back to developer models directory for Xcode runs.
        let bundledSources = detectBundledParakeetModels(in: bundleURL)
        let sourceModels = bundledSources.isEmpty ? detectDeveloperParakeetModels() : bundledSources

        guard !sourceModels.isEmpty else {
            logger.error("No Parakeet model found in bundle or developer models directory")
            logBundleContents(at: bundleURL)
            return false
        }

        for sourceModel in sourceModels {
            if sourceModel.url.path.hasPrefix(bundleURL.path) {
                logger.info("Found bundled Parakeet model: \(sourceModel.name)")
            } else {
                logger.info("Using developer Parakeet model source: \(sourceModel.url.path)")
            }

            // Target directory for FluidAudio cache
            let parakeetCacheDir = fluidAudioModelsDirectory.appendingPathComponent(sourceModel.name)

            // Check if already copied and complete
            if modelsExistInCache(at: parakeetCacheDir) {
                logger.info("Parakeet model already present and complete in cache: \(sourceModel.name)")
            } else {
                // Copy (or re-copy) model to cache
                try copyModelDirectory(from: sourceModel.url, to: parakeetCacheDir)
            }
        }

        // Also copy VAD model if present in bundle or developer directory
        try copyVADModelIfNeeded(from: bundleURL, developerModelsDir: developerModelsDirectory)

        return true
    }

    // MARK: - Detection

    /// Detects bundled Parakeet models and returns each folder name and source URL.
    private static func detectBundledParakeetModels(in resourcesDir: URL) -> [NamedModelDirectory] {
        let searchPaths = [
            "Parakeet",
            "",
            "BundledModels/Parakeet"
        ]

        return parakeetModelNames.compactMap { modelName in
            for searchPath in searchPaths {
                let basePath = searchPath.isEmpty ? resourcesDir : resourcesDir.appendingPathComponent(searchPath)
                let modelPath = basePath.appendingPathComponent(modelName, isDirectory: true)
                if isValidParakeetModelDirectory(at: modelPath) {
                    return (modelName, modelPath)
                }
            }
            return nil
        }
    }

    /// Detects Parakeet models from the repo-level `models/` directory during local development.
    private static func detectDeveloperParakeetModels() -> [NamedModelDirectory] {
        guard let modelsDir = developerModelsDirectory else { return [] }

        let candidates: [NamedModelDirectory] = [
            ("parakeet-tdt-0.6b-v3-coreml", modelsDir.appendingPathComponent("parakeet-v3/parakeet-tdt-0.6b-v3-coreml", isDirectory: true)),
            ("parakeet-tdt-0.6b-v2-coreml", modelsDir.appendingPathComponent("parakeet-v2/parakeet-tdt-0.6b-v2-coreml", isDirectory: true))
        ]

        return candidates.filter { isValidParakeetModelDirectory(at: $0.url) }
    }

    /// Optional local models directory override for development.
    private static var developerModelsDirectory: URL? {
        if let configuredPath = ProcessInfo.processInfo.environment["NOTESCRIBE_MODELS_DIR"],
           !configuredPath.isEmpty {
            let configuredURL = URL(fileURLWithPath: configuredPath, isDirectory: true)
            if fileManager.fileExists(atPath: configuredURL.path) {
                return configuredURL
            }
            logger.warning("NOTESCRIBE_MODELS_DIR does not exist: \(configuredPath)")
        }

        #if DEBUG
        var current = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        for _ in 0..<8 {
            let candidate = current.appendingPathComponent("models", isDirectory: true)
            if fileManager.fileExists(atPath: candidate.path) {
                return candidate
            }

            let parent = current.deletingLastPathComponent()
            if parent.path == current.path {
                break
            }
            current = parent
        }
        #endif

        return nil
    }

    // MARK: - Cache Validation

    /// Checks if required model files exist in the cache directory
    private static func modelsExistInCache(at directory: URL) -> Bool {
        isValidParakeetModelDirectory(at: directory)
    }

    /// Checks whether a model directory has all required CoreML and vocab files.
    private static func isValidParakeetModelDirectory(at directory: URL) -> Bool {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: directory.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            return false
        }

        let allFilesExist = parakeetModelFiles.allSatisfy { fileName in
            fileManager.fileExists(atPath: directory.appendingPathComponent(fileName).path)
        }

        let hasVocab = vocabFiles.contains { fileName in
            fileManager.fileExists(atPath: directory.appendingPathComponent(fileName).path)
        }

        return allFilesExist && hasVocab
    }

    // MARK: - Copying

    /// Copies an entire model directory from bundle to cache, replacing incomplete copies
    private static func copyModelDirectory(from source: URL, to destination: URL) throws {
        let fileManager = FileManager.default

        // Remove incomplete cache if it exists
        if fileManager.fileExists(atPath: destination.path) {
            logger.warning("Removing incomplete model cache at \(destination.path)")
            try fileManager.removeItem(at: destination)
        }

        // Create parent directory
        try fileManager.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)

        try fileManager.copyItem(at: source, to: destination)
        logger.info("Copied Parakeet model to cache: \(destination.path)")
    }

    /// Copies VAD model to cache if present in bundle or developer models directory.
    private static func copyVADModelIfNeeded(from bundleURL: URL, developerModelsDir: URL?) throws {
        var candidateURLs = [
            bundleURL.appendingPathComponent("VAD/silero-vad-coreml", isDirectory: true),
            bundleURL.appendingPathComponent("silero-vad-coreml", isDirectory: true)
        ]
        if let developerModelsDir {
            candidateURLs.append(
                developerModelsDir.appendingPathComponent("vad/silero-vad-coreml", isDirectory: true)
            )
        }

        guard let sourceURL = candidateURLs.first(where: { sourceDir in
            fileManager.fileExists(atPath: sourceDir.appendingPathComponent(vadModelFile, isDirectory: true).path)
        }) else {
            logger.info("No VAD model in bundle or developer models directory, skipping")
            return
        }

        let vadCacheDir = fluidAudioModelsDirectory.appendingPathComponent("silero-vad-coreml")
        let expectedModelPath = vadCacheDir.appendingPathComponent(vadModelFile).path

        if fileManager.fileExists(atPath: expectedModelPath) {
            logger.info("VAD model already in cache")
            return
        }

        // Remove incomplete VAD cache if it exists
        if fileManager.fileExists(atPath: vadCacheDir.path) {
            try fileManager.removeItem(at: vadCacheDir)
        }

        try fileManager.createDirectory(at: vadCacheDir.deletingLastPathComponent(), withIntermediateDirectories: true)
        try fileManager.copyItem(at: sourceURL, to: vadCacheDir)
        logger.info("Copied VAD model to cache")
    }

    /// Logs bundle contents for debugging
    private static func logBundleContents(at url: URL) {
        if let contents = try? FileManager.default.contentsOfDirectory(atPath: url.path) {
            logger.warning("Bundle contents:")
            for item in contents.sorted().prefix(30) {
                logger.warning("  - \(item)")
            }
        }
    }

    /// Clears cached models (useful for debugging or freeing space)
    static func clearCache() throws {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: fluidAudioModelsDirectory.path) {
            try fileManager.removeItem(at: fluidAudioModelsDirectory)
            logger.info("Cleared model cache")
        }
    }
}

enum ModelBundleManagerError: Error, LocalizedError {
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
