import Foundation
import AVFoundation
import Cocoa
import KeyboardShortcuts

@MainActor
final class PermissionManager: ObservableObject {
    @Published var audioPermissionStatus = AVCaptureDevice.authorizationStatus(for: .audio)
    @Published var isAccessibilityEnabled = false
    @Published var isScreenRecordingEnabled = false

    init() {
        checkAllPermissions()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func applicationDidBecomeActive() {
        checkAllPermissions()
    }

    func checkAllPermissions() {
        checkAccessibilityPermissions()
        checkScreenRecordingPermission()
        checkAudioPermissionStatus()
    }

    func checkAccessibilityPermissions() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        isAccessibilityEnabled = AXIsProcessTrustedWithOptions(options)
    }

    func requestAccessibilityPermissions() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options)
    }

    func checkScreenRecordingPermission() {
        isScreenRecordingEnabled = CGPreflightScreenCaptureAccess()
    }

    func requestScreenRecordingPermission() {
        CGRequestScreenCaptureAccess()
    }

    func checkAudioPermissionStatus() {
        audioPermissionStatus = AVCaptureDevice.authorizationStatus(for: .audio)
    }

    func requestAudioPermission() {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            Task { @MainActor in
                self.audioPermissionStatus = granted ? .authorized : .denied
            }
        }
    }
}
