import Foundation
import CoreML
import AVFoundation
import FluidAudio
import os.log

class ParakeetTranscriptionService: TranscriptionService {
    private var asrManager: AsrManager?
    private var vadManager: VadManager?
    private var activeVersion: AsrModelVersion?
    private let logger = Logger(subsystem: "com.swaylenhayes.apps.notescribe.parakeet", category: "ParakeetTranscriptionService")
    private var lastTimingLogDate = Date()

    private func version(for model: any TranscriptionModel) -> AsrModelVersion {
        model.name.lowercased().contains("v2") ? .v2 : .v3
    }

    private func ensureModelsLoaded(for version: AsrModelVersion) async throws {
        if asrManager != nil, activeVersion == version {
            return
        }

        cleanup()

        let mlConfig = MLModelConfiguration()
        mlConfig.computeUnits = .all

        let manager = AsrManager(config: .default)
        let models = try await loadModelsOffline(version: version, configuration: mlConfig)
        try await manager.initialize(models: models)
        self.asrManager = manager
        self.activeVersion = version
    }

    func loadModel(for model: ParakeetModel) async throws {
        try await ensureModelsLoaded(for: version(for: model))
    }

    func transcribe(audioURL: URL, model: any TranscriptionModel, useVAD: Bool) async throws -> String {
        let targetVersion = version(for: model)
        try await ensureModelsLoaded(for: targetVersion)

        guard let asrManager = asrManager else {
            throw ASRError.notInitialized
        }

        let ioStart = Date()
        var audioSamples: [Float] = []
        do {
            audioSamples = try readAudioSamples(from: audioURL)
            logger.notice("[perf] readAudioSamples: \(String(format: "%.2f", Date().timeIntervalSince(ioStart)))s")
        } catch {
            logger.error("readAudioSamples failed: \(error.localizedDescription)")
            // Fallback to FluidAudio's file-based converter to avoid transient CoreAudio read errors.
            let result = try await asrManager.transcribe(audioURL)
            return result.text
        }

        let durationSeconds = Double(audioSamples.count) / 16000.0

        var speechAudio = audioSamples
        if durationSeconds >= 20.0, useVAD {
            let vadConfig = VadConfig(defaultThreshold: 0.7)
            if vadManager == nil {
                let vadModel = try VADModelManager.shared.loadModel()
                vadManager = VadManager(config: vadConfig, vadModel: vadModel)
            }

            if let vadManager {
                let vadStart = Date()
                do {
                    let segments = try await vadManager.segmentSpeechAudio(audioSamples)
                    if segments.isEmpty {
                        speechAudio = audioSamples
                    } else {
                        let totalCount = segments.reduce(0) { $0 + $1.count }
                        var merged: [Float] = []
                        merged.reserveCapacity(totalCount)
                        for segment in segments {
                            merged.append(contentsOf: segment)
                        }
                        speechAudio = merged
                    }
                    logger.notice("[perf] VAD segmentation: \(String(format: "%.2f", Date().timeIntervalSince(vadStart)))s, segments=\(segments.count)")
                } catch {
                    logger.notice("VAD segmentation failed; using full audio: \(error.localizedDescription)")
                    speechAudio = audioSamples
                }
            }
        }

        let asrStart = Date()
        let result = try await asrManager.transcribe(speechAudio)
        logger.notice("[perf] ASR transcribe: \(String(format: "%.2f", Date().timeIntervalSince(asrStart)))s")

        return result.text
    }

    private func readAudioSamples(from url: URL) throws -> [Float] {
        let audioFile = try AVAudioFile(forReading: url)
        if audioFile.length == 0 {
            throw ASRError.invalidAudioData
        }
        let inputFormat = audioFile.processingFormat
        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 16000,
            channels: 1,
            interleaved: false
        ) else {
            throw ASRError.invalidAudioData
        }

        guard let converter = AVAudioConverter(from: inputFormat, to: targetFormat) else {
            throw ASRError.invalidAudioData
        }

        let chunkSize: AVAudioFrameCount = 4096
        var samples: [Float] = []
        if audioFile.length > 0 {
            let estimatedFrames = Int(Double(audioFile.length) * targetFormat.sampleRate / inputFormat.sampleRate)
            if estimatedFrames > 0 {
                samples.reserveCapacity(estimatedFrames)
            }
        }

        while true {
            guard let inputBuffer = AVAudioPCMBuffer(
                pcmFormat: inputFormat,
                frameCapacity: chunkSize
            ) else {
                throw ASRError.invalidAudioData
            }

            try audioFile.read(into: inputBuffer, frameCount: chunkSize)
            if inputBuffer.frameLength == 0 {
                break
            }

            let ratio = targetFormat.sampleRate / inputFormat.sampleRate
            let outputCapacity = AVAudioFrameCount(Double(inputBuffer.frameLength) * ratio) + 1
            guard let outputBuffer = AVAudioPCMBuffer(
                pcmFormat: targetFormat,
                frameCapacity: outputCapacity
            ) else {
                throw ASRError.invalidAudioData
            }

            var error: NSError?
            var didSupply = false
            let status = converter.convert(to: outputBuffer, error: &error) { _, outStatus in
                if didSupply {
                    outStatus.pointee = .noDataNow
                    return nil
                }
                didSupply = true
                outStatus.pointee = .haveData
                return inputBuffer
            }

            if status == .error {
                throw error ?? ASRError.invalidAudioData
            }

            guard let channelData = outputBuffer.floatChannelData else {
                throw ASRError.invalidAudioData
            }
            let count = Int(outputBuffer.frameLength)
            samples.append(contentsOf: UnsafeBufferPointer(start: channelData[0], count: count))
        }

        guard !samples.isEmpty else {
            throw ASRError.invalidAudioData
        }

        return samples
    }

    func cleanup() {
        asrManager?.cleanup()
        asrManager = nil
        vadManager = nil
        activeVersion = nil
    }

    // MARK: - Offline model loading (no network)

    private func loadModelsOffline(
        version: AsrModelVersion,
        configuration: MLModelConfiguration
    ) async throws -> AsrModels {
        try await Task.detached(priority: .userInitiated) {
            let repoDir = AsrModels.defaultCacheDirectory(for: version)
            guard AsrModels.modelsExist(at: repoDir, version: version) else {
                throw ASRError.modelLoadFailed
            }

            let preprocessor = try Self.loadModel(
                at: repoDir.appendingPathComponent(ModelNames.ASR.preprocessorFile),
                computeUnits: .cpuOnly,
                baseConfig: configuration
            )
            let encoder = try Self.loadModel(
                at: repoDir.appendingPathComponent(ModelNames.ASR.encoderFile),
                computeUnits: configuration.computeUnits,
                baseConfig: configuration
            )
            let decoder = try Self.loadModel(
                at: repoDir.appendingPathComponent(ModelNames.ASR.decoderFile),
                computeUnits: configuration.computeUnits,
                baseConfig: configuration
            )
            let joint = try Self.loadModel(
                at: repoDir.appendingPathComponent(ModelNames.ASR.jointFile),
                computeUnits: configuration.computeUnits,
                baseConfig: configuration
            )

            let vocabURL = repoDir.appendingPathComponent(ModelNames.ASR.vocabularyFile)
            let vocabulary = try Self.loadVocabulary(from: vocabURL)

            return AsrModels(
                encoder: encoder,
                preprocessor: preprocessor,
                decoder: decoder,
                joint: joint,
                configuration: configuration,
                vocabulary: vocabulary,
                version: version
            )
        }.value
    }

    private static func loadModel(
        at url: URL,
        computeUnits: MLComputeUnits,
        baseConfig: MLModelConfiguration
    ) throws -> MLModel {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            throw ASRError.modelLoadFailed
        }

        let config = MLModelConfiguration()
        config.computeUnits = computeUnits
        config.allowLowPrecisionAccumulationOnGPU = baseConfig.allowLowPrecisionAccumulationOnGPU
        return try MLModel(contentsOf: url, configuration: config)
    }

    private static func loadVocabulary(from url: URL) throws -> [Int: String] {
        let data = try Data(contentsOf: url)
        let jsonDict = try JSONSerialization.jsonObject(with: data) as? [String: String] ?? [:]
        var vocabulary: [Int: String] = [:]
        for (key, value) in jsonDict {
            if let tokenId = Int(key) {
                vocabulary[tokenId] = value
            }
        }
        return vocabulary
    }
}
