import Foundation
import SwiftUI
import os

// MARK: - UI Management Extension
extension TranscriptionState {
    
    // MARK: - Recorder Panel Management
    
    func showRecorderPanel() {
        // UI recorder panels are disabled; rely on the menu bar indicator only.
    }
    
    func hideRecorderPanel() {
        // UI recorder panels are disabled; nothing to hide.
    }
    
    // MARK: - Mini Recorder Management
    
    func toggleMiniRecorder() async {
        if isMiniRecorderVisible {
            if recordingState == .recording {
                await toggleRecord()
            } else {
                await cancelRecording()
            }
        } else {
            SoundManager.shared.playStartSound()

            await toggleRecord()

            await MainActor.run {
                isMiniRecorderVisible = true // This will call showRecorderPanel() via didSet
            }
        }
    }
    
    func dismissMiniRecorder() async {
        if recordingState == .busy { return }

        let wasRecording = recordingState == .recording
 
        await MainActor.run {
            self.recordingState = .busy
        }
        
        if wasRecording {
            recorder.stopRecording()
        }
        
        hideRecorderPanel()

        // OFFLINE MODE: Removed enhancement service context clearing

        await MainActor.run {
            isMiniRecorderVisible = false
        }

        // v1.2: Parakeet V3 - no model cleanup needed

        // OFFLINE MODE: Removed PowerMode auto-restore

        await MainActor.run {
            recordingState = .idle
        }
    }
    
    func resetOnLaunch() async {
        logger.notice("🔄 Resetting recording state on launch")
        recorder.stopRecording()
        hideRecorderPanel()
        await MainActor.run {
            isMiniRecorderVisible = false
            shouldCancelRecording = false
            miniRecorderError = nil
            recordingState = .idle
        }
        // v1.2: Parakeet V3 - no model cleanup needed
    }
    
    func cancelRecording() async {
        SoundManager.shared.playEscSound()
        shouldCancelRecording = true
        await dismissMiniRecorder()
    }
    
    // MARK: - Notification Handling
    
    func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleToggleMiniRecorder), name: .toggleMiniRecorder, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleDismissMiniRecorder), name: .dismissMiniRecorder, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleLicenseStatusChanged), name: .licenseStatusChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handlePromptChange), name: .promptDidChange, object: nil)
    }
    
    @objc public func handleToggleMiniRecorder() {
        Task {
            await toggleMiniRecorder()
        }
    }
    
    @objc public func handleDismissMiniRecorder() {
        Task {
            await dismissMiniRecorder()
        }
    }
    
    // OFFLINE MODE: Removed license handling
    @objc func handleLicenseStatusChanged() {
        // No-op in offline mode
    }
    
    @objc func handlePromptChange() {
        // Update the transcription context with the new prompt
        updateContextPrompt()
    }
    
    private func updateContextPrompt() {
        // Always reload the prompt from UserDefaults to ensure we have the latest
        _ = UserDefaults.standard.string(forKey: "TranscriptionPrompt") ?? transcriptionPrompt.transcriptionPrompt
        // v1.2: Parakeet V3 - no transcription context to update
    }
}
