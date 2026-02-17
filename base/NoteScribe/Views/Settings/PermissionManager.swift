import Foundation
import AVFoundation
import Cocoa
import KeyboardShortcuts

@MainActor
final class PermissionManager: ObservableObject {
    private static var didRequestInitialPermissionsThisSession = false

    @Published var audioPermissionStatus = AVCaptureDevice.authorizationStatus(for: .audio)
    @Published var isAccessibilityEnabled = false

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

    static func requestInitialPermissions() {
        guard !didRequestInitialPermissionsThisSession else { return }
        didRequestInitialPermissionsThisSession = true

        let audioStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        let promptAccessibilityIfNeeded = {
            guard !AXIsProcessTrusted() else { return }
            let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
            _ = AXIsProcessTrustedWithOptions(options)
        }

        if audioStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .audio) { _ in
                DispatchQueue.main.async {
                    promptAccessibilityIfNeeded()
                }
            }
        } else {
            promptAccessibilityIfNeeded()
        }
    }
}
