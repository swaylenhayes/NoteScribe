import Foundation
import KeyboardShortcuts
import AppKit

extension KeyboardShortcuts.Name {
    static let escapeRecorder = Self("escapeRecorder")
    static let cancelRecorder = Self("cancelRecorder")
    // OFFLINE MODE: Removed enhancement and PowerMode shortcuts
}

@MainActor
class MiniRecorderShortcutManager: ObservableObject {
    private var transcriptionState: TranscriptionState
    private var visibilityTask: Task<Void, Never>?
    
    private var isCancelHandlerSetup = false
    
    // Double-tap Escape handling
    private var escFirstPressTime: Date? = nil
    private let escSecondPressThreshold: TimeInterval = 1.5
    private var isEscapeHandlerSetup = false
    private var escapeTimeoutTask: Task<Void, Never>?
    
    init(transcriptionState: TranscriptionState) {
        self.transcriptionState = transcriptionState
        setupVisibilityObserver()
        setupEscapeHandlerOnce()
        setupCancelHandlerOnce()
        // OFFLINE MODE: Removed setupEnhancementShortcut
        NotificationCenter.default.addObserver(self, selector: #selector(settingsDidChange), name: .AppSettingsDidChange, object: nil)
    }

    @objc private func settingsDidChange() {
        // Keep escape-cancel shortcut in sync when recording hotkeys change.
        Task { @MainActor in
            guard transcriptionState.isMiniRecorderVisible else { return }
            deactivateEscapeShortcut()
            activateEscapeShortcut()
        }
    }

    private func setupVisibilityObserver() {
        visibilityTask = Task { @MainActor in
            for await isVisible in transcriptionState.$isMiniRecorderVisible.values {
                if isVisible {
                    activateEscapeShortcut()
                    activateCancelShortcut()
                    // OFFLINE MODE: Removed enhancement and PowerMode shortcut setup
                } else {
                    deactivateEscapeShortcut()
                    deactivateCancelShortcut()
                    // OFFLINE MODE: Removed enhancement and PowerMode shortcut removal
                }
            }
        }
    }
    
    // Setup escape handler once
    private func setupEscapeHandlerOnce() {
        guard !isEscapeHandlerSetup else { return }
        isEscapeHandlerSetup = true
        
        KeyboardShortcuts.onKeyDown(for: .escapeRecorder) { [weak self] in
            Task { @MainActor in
                guard let self = self else { return }
                let isVisible = await MainActor.run { self.transcriptionState.isMiniRecorderVisible }
                guard isVisible else { return }
                
                // Don't process if custom shortcut is configured
                guard KeyboardShortcuts.getShortcut(for: .cancelRecorder) == nil else { return }
                // Don't process if Escape is used as a recording toggle hotkey.
                guard !self.isEscapeReservedForRecordingToggle() else { return }
                
                let now = Date()
                if let firstTime = self.escFirstPressTime,
                   now.timeIntervalSince(firstTime) <= self.escSecondPressThreshold {
                    self.escFirstPressTime = nil
                    await self.transcriptionState.cancelRecording()
                } else {
                    self.escFirstPressTime = now
                    SoundManager.shared.playEscSound()
                    NotificationManager.shared.showNotification(
                        title: "Press ESC again to cancel recording",
                        type: .info,
                        duration: self.escSecondPressThreshold
                    )
                    self.escapeTimeoutTask = Task { [weak self] in
                        try? await Task.sleep(nanoseconds: UInt64((self?.escSecondPressThreshold ?? 1.5) * 1_000_000_000))
                        await MainActor.run {
                            self?.escFirstPressTime = nil
                        }
                    }
                }
            }
        }
    }
    
    private func activateEscapeShortcut() {
        // Don't activate if custom shortcut is configured
        guard KeyboardShortcuts.getShortcut(for: .cancelRecorder) == nil else { return }
        // Don't activate if Escape is used as a recording toggle hotkey.
        guard !isEscapeReservedForRecordingToggle() else { return }
        KeyboardShortcuts.setShortcut(.init(.escape), for: .escapeRecorder)
    }

    private func isEscapeReservedForRecordingToggle() -> Bool {
        let recordingShortcuts = [
            KeyboardShortcuts.getShortcut(for: .toggleRecording),
            KeyboardShortcuts.getShortcut(for: .toggleRecording2)
        ]
        return recordingShortcuts.contains { $0?.key == .escape }
    }
    
    // Setup cancel handler once
    private func setupCancelHandlerOnce() {
        guard !isCancelHandlerSetup else { return }
        isCancelHandlerSetup = true
        
        KeyboardShortcuts.onKeyDown(for: .cancelRecorder) { [weak self] in
            Task { @MainActor in
                guard let self = self else { return }
                let isVisible = await MainActor.run { self.transcriptionState.isMiniRecorderVisible }
                guard isVisible,
                      KeyboardShortcuts.getShortcut(for: .cancelRecorder) != nil else { return }

                await self.transcriptionState.cancelRecording()
            }
        }
    }
    
    private func activateCancelShortcut() {
        // Handler checks if shortcut exists
    }
    
    private func deactivateEscapeShortcut() {
        KeyboardShortcuts.setShortcut(nil, for: .escapeRecorder)
        escFirstPressTime = nil
        escapeTimeoutTask?.cancel()
        escapeTimeoutTask = nil
    }
    
    private func deactivateCancelShortcut() {
        // Shortcut managed by user settings
    }

    // OFFLINE MODE: Removed all enhancement and PowerMode shortcut functions
    
    deinit {
        visibilityTask?.cancel()
        NotificationCenter.default.removeObserver(self)
        Task { @MainActor [weak self] in
            self?.deactivateEscapeShortcut()
            self?.deactivateCancelShortcut()
            // OFFLINE MODE: Removed enhancement and PowerMode shortcut removal
        }
    }
} 
