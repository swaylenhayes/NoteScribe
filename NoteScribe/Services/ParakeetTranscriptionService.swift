import Foundation
import CoreML
import AVFoundation
import FluidAudio
import os.log

class ParakeetTranscriptionService: TranscriptionService {
    private var asrManagers: [AsrModelVersion: AsrManager] = [:]
    private var vadManager: VadManager?
    private var activeVersion: AsrModelVersion?
    private let logger = Logger(subsystem: "com.swaylenhayes.apps.notescribe.parakeet", category: "ParakeetTranscriptionService")

    private func version(for model: any TranscriptionModel) -> AsrModelVersion {
        model.name.lowercased().contains("v2") ? .v2 : .v3
    }

    private func ensureModelsLoaded(for version: AsrModelVersion) async throws {
        if asrManagers[version] != nil {
            activeVersion = version
            return
        }

        // Ensure bundled models are in the FluidAudio cache before loading
        try ModelBundleManager.ensureModelsAvailable()

        let mlConfig = MLModelConfiguration()
        mlConfig.computeUnits = .all

        let manager = AsrManager(config: .default)
        let models = try await AsrModels.loadFromCache(
            configuration: mlConfig,
            version: version
        )
        try await manager.initialize(models: models)
        self.asrManagers[version] = manager
        self.activeVersion = version
    }

    func loadModel(for model: ParakeetModel) async throws {
        try await ensureModelsLoaded(for: version(for: model))
    }

    func transcribe(audioURL: URL, model: any TranscriptionModel, useVAD: Bool) async throws -> String {
        let targetVersion = version(for: model)
        try await ensureModelsLoaded(for: targetVersion)
        activeVersion = targetVersion

        guard let asrManager = asrManagers[targetVersion] else {
            throw ASRError.notInitialized
        }

        let ioStart = Date()
        let audioSamples = try readAudioSamples(from: audioURL)
        logger.notice("[perf] readAudioSamples: \(String(format: "%.2f", Date().timeIntervalSince(ioStart)))s")

        let durationSeconds = Double(audioSamples.count) / 16000.0

        var speechAudio = audioSamples
        if durationSeconds >= 20.0, useVAD {
            if vadManager == nil {
                let vadStart = Date()
                vadManager = try await VadManager(config: VadConfig(defaultThreshold: 0.7))
                logger.notice("[perf] VadManager init: \(String(format: "%.2f", Date().timeIntervalSince(vadStart)))s")
            }

            if let vadManager {
                let vadStart = Date()
                do {
                    let segments = try await vadManager.segmentSpeechAudio(audioSamples)
                    speechAudio = segments.isEmpty ? audioSamples : segments.flatMap { $0 }
                    logger.notice("[perf] VAD segmentation: \(String(format: "%.2f", Date().timeIntervalSince(vadStart)))s, segments=\(segments.count)")
                } catch {
                    logger.notice("VAD segmentation failed; using full audio: \(error.localizedDescription)")
                    speechAudio = audioSamples
                }
            }
        }

        let asrStart = Date()
        let result = try await asrManager.transcribe(speechAudio, source: .microphone)
        logger.notice("[perf] ASR transcribe: \(String(format: "%.2f", Date().timeIntervalSince(asrStart)))s")

        return result.text
    }

    private func readAudioSamples(from url: URL) throws -> [Float] {
        do {
            let data = try Data(contentsOf: url)
            guard data.count > 44 else {
                throw ASRError.invalidAudioData
            }

            let floats = stride(from: 44, to: data.count, by: 2).map {
                return data[$0..<$0 + 2].withUnsafeBytes {
                    let short = Int16(littleEndian: $0.load(as: Int16.self))
                    return max(-1.0, min(Float(short) / 32767.0, 1.0))
                }
            }

            return floats
        } catch {
            throw ASRError.invalidAudioData
        }
    }

    func cleanup() {
        for manager in asrManagers.values {
            manager.cleanup()
        }
        asrManagers.removeAll()
        vadManager = nil
        activeVersion = nil
    }
}
