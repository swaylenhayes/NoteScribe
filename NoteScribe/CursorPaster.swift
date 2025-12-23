import Foundation
import AppKit
import ApplicationServices

class CursorPaster {
    private static let pasteRetryDelay: TimeInterval = 0.25
    private static let maxPasteRetries = 20
    private static let restoreDelay: TimeInterval = 0.9

    static func pasteAtCursor(_ text: String) {
        let pasteboard = NSPasteboard.general
        let preserveTranscript = UserDefaults.standard.bool(forKey: "preserveTranscriptInClipboard")

        var savedContents: [(NSPasteboard.PasteboardType, Data)] = []

        // Only save clipboard contents if we plan to restore them
        if !preserveTranscript {
            let currentItems = pasteboard.pasteboardItems ?? []

            for item in currentItems {
                for type in item.types {
                    if let data = item.data(forType: type) {
                        savedContents.append((type, data))
                    }
                }
            }
        }

        _ = ClipboardManager.setClipboard(text, transient: !preserveTranscript)

        attemptPaste(
            savedContents: savedContents,
            preserveTranscript: preserveTranscript,
            attempt: 0
        )
    }
    
    private static func attemptPaste(
        savedContents: [(NSPasteboard.PasteboardType, Data)],
        preserveTranscript: Bool,
        attempt: Int
    ) {
        if !isAccessibilityTrusted(prompt: true) {
            if attempt == 0 {
                Task { @MainActor in
                    NotificationManager.shared.showNotification(
                        title: "Enable Accessibility to paste. Will retry…",
                        type: .info
                    )
                }
            }

            if attempt < maxPasteRetries {
                DispatchQueue.main.asyncAfter(deadline: .now() + pasteRetryDelay) {
                    attemptPaste(
                        savedContents: savedContents,
                        preserveTranscript: preserveTranscript,
                        attempt: attempt + 1
                    )
                }
            } else if !preserveTranscript {
                restoreClipboard(savedContents)
            }
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            performPaste()
        }

        if !preserveTranscript {
            DispatchQueue.main.asyncAfter(deadline: .now() + restoreDelay) {
                restoreClipboard(savedContents)
            }
        }
    }

    private static func isAccessibilityTrusted(prompt: Bool) -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt]
        return AXIsProcessTrustedWithOptions(options)
    }

    private static func restoreClipboard(_ savedContents: [(NSPasteboard.PasteboardType, Data)]) {
        guard !savedContents.isEmpty else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        for (type, data) in savedContents {
            pasteboard.setData(data, forType: type)
        }
    }

    private static func performPaste() {
        let source = CGEventSource(stateID: .hidSystemState)
        
        let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
        let vDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        let vUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)
        
        cmdDown?.flags = .maskCommand
        vDown?.flags = .maskCommand
        vUp?.flags = .maskCommand
        
        cmdDown?.post(tap: .cghidEventTap)
        vDown?.post(tap: .cghidEventTap)
        vUp?.post(tap: .cghidEventTap)
        cmdUp?.post(tap: .cghidEventTap)
    }

    // Simulate pressing the Return / Enter key
    static func pressEnter() {
        guard AXIsProcessTrusted() else { return }
        let source = CGEventSource(stateID: .hidSystemState)
        let enterDown = CGEvent(keyboardEventSource: source, virtualKey: 0x24, keyDown: true)
        let enterUp = CGEvent(keyboardEventSource: source, virtualKey: 0x24, keyDown: false)
        enterDown?.post(tap: .cghidEventTap)
        enterUp?.post(tap: .cghidEventTap)
    }
}
