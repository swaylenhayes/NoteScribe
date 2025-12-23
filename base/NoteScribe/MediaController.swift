import AppKit
import Combine
import Foundation
import SwiftUI
import CoreAudio

/// Controls system audio management during recording
class MediaController: ObservableObject {
    static let shared = MediaController()
    private var didMuteAudio = false
    private var wasAudioMutedBeforeRecording = false
    private var currentMuteTask: Task<Bool, Never>?
    
    @Published var isSystemMuteEnabled: Bool = UserDefaults.standard.bool(forKey: "isSystemMuteEnabled") {
        didSet {
            UserDefaults.standard.set(isSystemMuteEnabled, forKey: "isSystemMuteEnabled")
        }
    }
    
    private init() {
        // Set default if not already set
        if !UserDefaults.standard.contains(key: "isSystemMuteEnabled") {
            UserDefaults.standard.set(true, forKey: "isSystemMuteEnabled")
        }
        isSystemMuteEnabled = UserDefaults.standard.bool(forKey: "isSystemMuteEnabled")
    }
    
    /// Checks if the system audio is currently muted using CoreAudio
    private func isSystemAudioMuted() -> Bool {
        guard let deviceID = defaultOutputDeviceID() else {
            return false
        }
        return isDeviceMuted(deviceID)
    }
    
    /// Mutes system audio during recording
    func muteSystemAudio() async -> Bool {
        guard isSystemMuteEnabled else { return false }
        
        // Cancel any existing mute task and create a new one
        currentMuteTask?.cancel()
        
        let task = Task<Bool, Never> {
            // First check if audio is already muted
            wasAudioMutedBeforeRecording = isSystemAudioMuted()
            
            // If already muted, no need to mute it again
            if wasAudioMutedBeforeRecording {
                return true
            }
            
            guard let deviceID = defaultOutputDeviceID() else {
                return false
            }

            let success = setDeviceMuted(deviceID: deviceID, muted: true)
            didMuteAudio = success
            return success
        }
        
        currentMuteTask = task
        return await task.value
    }
    
    /// Restores system audio after recording
    func unmuteSystemAudio() async {
        guard isSystemMuteEnabled else { return }
        
        // Wait for any pending mute operation to complete first
        if let muteTask = currentMuteTask {
            _ = await muteTask.value
        }
        
        // Only unmute if we actually muted it (and it wasn't already muted)
        if didMuteAudio && !wasAudioMutedBeforeRecording {
            if let deviceID = defaultOutputDeviceID() {
                _ = setDeviceMuted(deviceID: deviceID, muted: false)
            }
        }
        
        didMuteAudio = false
        currentMuteTask = nil
    }
    
    // MARK: - CoreAudio helpers

    private func defaultOutputDeviceID() -> AudioDeviceID? {
        var deviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &deviceID
        )
        return status == noErr ? deviceID : nil
    }

    private func isDeviceMuted(_ deviceID: AudioDeviceID) -> Bool {
        var mute: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        guard AudioObjectHasProperty(deviceID, &address) else {
            return false
        }

        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &mute)
        return status == noErr && mute != 0
    }

    private func setDeviceMuted(deviceID: AudioDeviceID, muted: Bool) -> Bool {
        var mute: UInt32 = muted ? 1 : 0
        let size = UInt32(MemoryLayout<UInt32>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        guard AudioObjectHasProperty(deviceID, &address) else {
            return false
        }

        let status = AudioObjectSetPropertyData(deviceID, &address, 0, nil, size, &mute)
        return status == noErr
    }
}

extension UserDefaults {
    func contains(key: String) -> Bool {
        return object(forKey: key) != nil
    }
    
    var isSystemMuteEnabled: Bool {
        get { bool(forKey: "isSystemMuteEnabled") }
        set { set(newValue, forKey: "isSystemMuteEnabled") }
    }
}
