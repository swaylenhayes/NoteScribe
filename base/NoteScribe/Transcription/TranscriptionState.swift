import Foundation
import SwiftUI
import AVFoundation
import SwiftData
import AppKit
import KeyboardShortcuts
import os

// MARK: - Recording State Machine
enum RecordingState: Equatable {
    case idle
    case recording
    case transcribing
    case enhancing
    case busy
}

@MainActor
class TranscriptionState: NSObject, ObservableObject {
    @Published var recordingState: RecordingState = .idle
    @Published var isModelLoaded = false
    // v1.2: Removed loadedLocalModel - Parakeet V3 only
    @Published var currentTranscriptionModel: (any TranscriptionModel)?
    @Published var isModelLoading = false
    // v1.2: Removed availableModels - Parakeet V3 only
    @Published var allAvailableModels: [any TranscriptionModel] = PredefinedModels.models
    @Published var clipboardMessage = ""
    @Published var miniRecorderError: String?
    @Published var shouldCancelRecording = false
    @Published var isMiniRecorderVisible = false
    
    let recorder = Recorder()
    var recordedFile: URL? = nil

    let transcriptionPrompt: TranscriptionPrompt
    let modelContext: ModelContext
    
    // v1.2: Only Parakeet transcription service
    internal lazy var parakeetTranscriptionService = ParakeetTranscriptionService()
    
    private var modelUrl: URL? {
        let possibleURLs = [
            Bundle.main.url(forResource: "ggml-base.en", withExtension: "bin", subdirectory: "Models"),
            Bundle.main.url(forResource: "ggml-base.en", withExtension: "bin"),
            Bundle.main.bundleURL.appendingPathComponent("Models/ggml-base.en.bin")
        ]
        
        for url in possibleURLs {
            if let url = url, FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }
        return nil
    }
    
    private enum LoadError: Error {
        case couldNotLocateModel
    }
    
    let modelsDirectory: URL
    let bundledModelsDirectory: URL? // OFFLINE MODE: Check bundle first
    let recordingsDirectory: URL
    // OFFLINE MODE: Removed enhancementService property
    let logger = Logger(subsystem: "com.swaylenhayes.apps.notescribe", category: "TranscriptionState")

    // For model progress tracking
    @Published var downloadProgress: [String: Double] = [:]
    @Published var parakeetDownloadStates: [String: Bool] = [:]

    init(modelContext: ModelContext) {
        self.transcriptionPrompt = TranscriptionPrompt()
        self.modelContext = modelContext
        let appSupportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("com.swaylenhayes.apps.notescribe")

        self.modelsDirectory = appSupportDirectory.appendingPathComponent("Models")
        self.recordingsDirectory = appSupportDirectory.appendingPathComponent("Recordings")

        // Models are copied from bundle to FluidAudio cache on demand.
        // See ModelBundleManager.
        self.bundledModelsDirectory = nil

        super.init()

        // v1.2: Parakeet V3 only - no local transcription service needed

        setupNotifications()
        createModelsDirectoryIfNeeded()
        createRecordingsDirectoryIfNeeded()
        loadAvailableModels()
        loadCurrentTranscriptionModel()
        refreshAllAvailableModels()
    }
    
    private func createRecordingsDirectoryIfNeeded() {
        do {
            try FileManager.default.createDirectory(at: recordingsDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            logger.error("Error creating recordings directory: \(error.localizedDescription)")
        }
    }
    
    func toggleRecord() async {
        if recordingState == .recording {
            await recorder.stopRecordingAndWait()
            if let recordedFile {
                await waitForRecordedFileReady(recordedFile)
                if !shouldCancelRecording {
                    let audioAsset = AVURLAsset(url: recordedFile)
                    let duration = (try? CMTimeGetSeconds(await audioAsset.load(.duration))) ?? 0.0

                    let transcription = Transcription(
                        text: "",
                        duration: duration,
                        audioFileURL: recordedFile.absoluteString,
                        transcriptionStatus: .pending
                    )
                    modelContext.insert(transcription)
                    try? modelContext.save()
                    NotificationCenter.default.post(name: .transcriptionCreated, object: transcription)

                    await transcribeAudio(on: transcription)
                } else {
                    await MainActor.run {
                        recordingState = .idle
                    }
                    // v1.2: Parakeet V3 - no model cleanup needed
                }
            } else {
                logger.error("❌ No recorded file found after stopping recording")
                await MainActor.run {
                    recordingState = .idle
                }
            }
        } else {
            guard currentTranscriptionModel != nil else {
                await MainActor.run {
                    NotificationManager.shared.showNotification(
                        title: "No AI Model Selected",
                        type: .error
                    )
                }
                return
            }
            shouldCancelRecording = false
            requestRecordPermission { [self] granted in
                if granted {
                    Task {
                        do {
                            // --- Prepare permanent file URL ---
                            let fileName = "\(UUID().uuidString).wav"
                            let permanentURL = self.recordingsDirectory.appendingPathComponent(fileName)
                            self.recordedFile = permanentURL
        
                            try await self.recorder.startRecording(toOutputFile: permanentURL)
                            
                            await MainActor.run {
                                self.recordingState = .recording
                            }

                            // OFFLINE MODE: Removed ActiveWindowService (window management)

                            // v1.2: Only Parakeet V3 model
                            if let parakeetModel = self.currentTranscriptionModel as? ParakeetModel {
                                try? await self.parakeetTranscriptionService.loadModel(for: parakeetModel)
                            }

                            // OFFLINE MODE: Removed enhancement service context capture

                        } catch {
                            self.logger.error("❌ Failed to start recording: \(error.localizedDescription)")
                            NotificationManager.shared.showNotification(title: "Recording failed to start", type: .error)
                            await self.cancelRecording(playEscCue: false)
                            // Do not remove the file on a failed start, to preserve all recordings.
                            self.recordedFile = nil
                        }
                    }
                } else {
                    logger.error("❌ Recording permission denied.")
                }
            }
        }
    }
    
    private func requestRecordPermission(response: @escaping (Bool) -> Void) {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        switch status {
        case .authorized:
            response(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                DispatchQueue.main.async {
                    response(granted)
                }
            }
        case .denied, .restricted:
            response(false)
        @unknown default:
            response(false)
        }
    }
    
    private func transcribeAudio(on transcription: Transcription) async {
        guard let urlString = transcription.audioFileURL, let url = URL(string: urlString) else {
            logger.error("❌ Invalid audio file URL in transcription object.")
            await MainActor.run {
                recordingState = .idle
            }
            transcription.text = "Transcription Failed: Invalid audio file URL"
            transcription.transcriptionStatus = TranscriptionStatus.failed.rawValue
            try? modelContext.save()
            return
        }

        if shouldCancelRecording {
            await MainActor.run {
                recordingState = .idle
            }
            // v1.2: Parakeet V3 - no model cleanup needed
            return
        }

        await MainActor.run {
            recordingState = .transcribing
        }

        // Play stop sound when transcription starts with a small delay
        Task {
            let isSystemMuteEnabled = UserDefaults.standard.bool(forKey: "isSystemMuteEnabled")
            if isSystemMuteEnabled {
                try? await Task.sleep(nanoseconds: 200_000_000) // 200 milliseconds delay
            }
            await MainActor.run {
                SoundManager.shared.playStopSound()
            }
        }

        defer {
            if shouldCancelRecording {
                Task {
                    // v1.2: Parakeet V3 - no model cleanup needed
                }
            }
        }

        logger.notice("🔄 Starting transcription...")

        var finalPastedText: String?
        // OFFLINE MODE: Removed prompt detection (AI enhancement feature)

        do {
            guard let model = currentTranscriptionModel else {
                throw TranscriptionStateError.transcriptionFailed
            }

            // v1.2: Only Parakeet V3 model supported
            let transcriptionService: TranscriptionService = parakeetTranscriptionService

            let transcriptionStart = Date()
            let useVAD = UserDefaults.standard.object(forKey: "IsVADEnabledLive") as? Bool ?? true
            var text = try await transcriptionService.transcribe(audioURL: url, model: model, useVAD: useVAD)
            logger.notice("📝 Raw transcript: \(text, privacy: .public)")
            text = TranscriptionOutputFilter.filter(text)
            logger.notice("📝 Output filter result: \(text, privacy: .public)")
            let transcriptionDuration = Date().timeIntervalSince(transcriptionStart)

            // OFFLINE MODE: Removed PowerMode
            let powerModeName: String? = nil
            let powerModeEmoji: String? = nil

            if await checkCancellationAndCleanup() { return }

            text = text.trimmingCharacters(in: .whitespacesAndNewlines)

            if UserDefaults.standard.object(forKey: "IsTextFormattingEnabled") as? Bool ?? true {
                text = TranscriptionTextFormatter.format(text)
                logger.notice("📝 Formatted transcript: \(text, privacy: .public)")
            }

            text = WordReplacementService.shared.applyReplacements(to: text)
            logger.notice("📝 WordReplacement: \(text, privacy: .public)")

            let audioAsset = AVURLAsset(url: url)
            let actualDuration = (try? CMTimeGetSeconds(await audioAsset.load(.duration))) ?? 0.0
            
            transcription.text = text
            transcription.duration = actualDuration
            transcription.transcriptionModelName = model.displayName
            transcription.transcriptionDuration = transcriptionDuration
            transcription.powerModeName = powerModeName
            transcription.powerModeEmoji = powerModeEmoji
            finalPastedText = text

            // OFFLINE MODE: Removed enhancement service (prompt detection and AI enhancement)

            transcription.transcriptionStatus = TranscriptionStatus.completed.rawValue

        } catch {
            let errorDescription = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            let recoverySuggestion = (error as? LocalizedError)?.recoverySuggestion ?? ""
            let fullErrorText = recoverySuggestion.isEmpty ? errorDescription : "\(errorDescription) \(recoverySuggestion)"

            transcription.text = "Transcription Failed: \(fullErrorText)"
            transcription.transcriptionStatus = TranscriptionStatus.failed.rawValue
        }

        // --- Finalize and save ---
        try? modelContext.save()
        
        if transcription.transcriptionStatus == TranscriptionStatus.completed.rawValue {
            NotificationCenter.default.post(name: .transcriptionCompleted, object: transcription)
        }

        if await checkCancellationAndCleanup() { return }

        if let textToPaste = finalPastedText, transcription.transcriptionStatus == TranscriptionStatus.completed.rawValue {
            // OFFLINE MODE: No trial/licensing checks
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                CursorPaster.pasteAtCursor(textToPaste + " ")
                // OFFLINE MODE: Removed PowerMode auto-send feature
            }
        }

        // OFFLINE MODE: Removed prompt detection restore

        await self.cancelRecordingUI()

        shouldCancelRecording = false
    }

    private func waitForRecordedFileReady(_ url: URL) async {
        let fileManager = FileManager.default
        let deadline = Date().addingTimeInterval(2.0)
        var lastSize: UInt64 = 0
        var stableCount = 0

        while Date() < deadline {
            if let attributes = try? fileManager.attributesOfItem(atPath: url.path),
               let size = attributes[.size] as? UInt64,
               size > 0 {
                if size == lastSize {
                    stableCount += 1
                    if stableCount >= 2 {
                        return
                    }
                } else {
                    lastSize = size
                    stableCount = 0
                }
            }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }

        logger.warning("Recording file did not stabilize before transcription; continuing anyway.")
    }

    // OFFLINE MODE: Removed getEnhancementService function

    private func checkCancellationAndCleanup() async -> Bool {
        if shouldCancelRecording {
            // v1.2: Parakeet V3 - no model cleanup needed
            return true
        }
        return false
    }

    private func cleanupAndDismiss() async {
        await cancelRecordingUI()
    }

    // MARK: - v1.2 Stub Functions (Parakeet V3 only - no local Transcription models)

    func createModelsDirectoryIfNeeded() {
        // v1.2: No longer needed - Parakeet models handled by ModelBundleManager
    }

    func loadAvailableModels() {
        // v1.2: No longer needed - only Parakeet V3 model available
    }
}
