import Foundation
import SwiftUI
import AVFoundation
import SwiftData
import os

@MainActor
class AudioTranscriptionService: ObservableObject {
    @Published var isTranscribing = false
    @Published var currentError: TranscriptionError?

    private let modelContext: ModelContext
    private let transcriptionState: TranscriptionState
    private let logger = Logger(subsystem: "com.swaylenhayes.apps.notescribe", category: "AudioTranscriptionService")
    
    // v1.2: Only Parakeet transcription service
    private lazy var parakeetTranscriptionService = ParakeetTranscriptionService()
    
    enum TranscriptionError: Error {
        case noAudioFile
        case transcriptionFailed
        case modelNotLoaded
        case invalidAudioFormat
    }
    
    init(modelContext: ModelContext, transcriptionState: TranscriptionState) {
        self.modelContext = modelContext
        self.transcriptionState = transcriptionState
    }
    
    func retranscribeAudio(from url: URL, using model: any TranscriptionModel) async throws -> Transcription {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw TranscriptionError.noAudioFile
        }
        
        await MainActor.run {
            isTranscribing = true
        }
        
        do {
            // Delegate transcription to Parakeet service
            let transcriptionStart = Date()
            var text: String

            // v1.2: Only Parakeet V3
            let useVAD = UserDefaults.standard.object(forKey: "IsVADEnabledFile") as? Bool ?? true
            text = try await parakeetTranscriptionService.transcribe(audioURL: url, model: model, useVAD: useVAD)
            logger.notice("[perf] File transcription total: \(String(format: "%.2f", Date().timeIntervalSince(transcriptionStart)))s (useVAD=\(useVAD))")
            
            let transcriptionDuration = Date().timeIntervalSince(transcriptionStart)
            text = TranscriptionOutputFilter.filter(text)
            text = text.trimmingCharacters(in: .whitespacesAndNewlines)

            if UserDefaults.standard.object(forKey: "IsTextFormattingEnabled") as? Bool ?? true {
                text = TranscriptionTextFormatter.format(text)
            }

            text = WordReplacementService.shared.applyReplacements(to: text)
            logger.notice("✅ Word replacements applied")
            
            // Get audio duration
            let audioAsset = AVURLAsset(url: url)
            let duration = CMTimeGetSeconds(try await audioAsset.load(.duration))
            
            // Create a permanent copy of the audio file
            let recordingsDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("com.swaylenhayes.apps.notescribe")
                .appendingPathComponent("Recordings")
            
            let fileName = "retranscribed_\(UUID().uuidString).wav"
            let permanentURL = recordingsDirectory.appendingPathComponent(fileName)
            
            do {
                try FileManager.default.copyItem(at: url, to: permanentURL)
            } catch {
                logger.error("❌ Failed to create permanent copy of audio: \(error.localizedDescription)")
                isTranscribing = false
                throw error
            }
            
            let permanentURLString = permanentURL.absoluteString

            // OFFLINE MODE: Removed prompt detection and AI enhancement

            // Create transcription without enhancement
            let newTranscription = Transcription(
                text: text,
                duration: duration,
                audioFileURL: permanentURLString,
                transcriptionModelName: model.displayName,
                promptName: nil,
                transcriptionDuration: transcriptionDuration,
                powerModeName: nil,
                powerModeEmoji: nil
            )
            modelContext.insert(newTranscription)
            do {
                try modelContext.save()
                NotificationCenter.default.post(name: .transcriptionCreated, object: newTranscription)
            } catch {
                logger.error("❌ Failed to save transcription: \(error.localizedDescription)")
            }

            await MainActor.run {
                isTranscribing = false
            }

            return newTranscription
        } catch {
            logger.error("❌ Transcription failed: \(error.localizedDescription)")
            currentError = .transcriptionFailed
            isTranscribing = false
            throw error
        }
    }
}
