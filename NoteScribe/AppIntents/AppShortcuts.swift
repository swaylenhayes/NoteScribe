import AppIntents
import Foundation

struct AppShortcuts : AppShortcutsProvider {
    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
            AppShortcut(
                intent: StartStopRecordingIntent(),
                phrases: [
                    "Start \(.applicationName) recording",
                    "Stop \(.applicationName) recording",
                    "Toggle recording in \(.applicationName)",
                    "Start recording in \(.applicationName)",
                    "Stop recording in \(.applicationName)"
                ],
                shortTitle: "Start/Stop Recording",
                systemImageName: "mic.circle"
            )

            AppShortcut(
                intent: CancelRecordingIntent(),
                phrases: [
                    "Cancel \(.applicationName) recording",
                    "Dismiss \(.applicationName) recording",
                    "Stop and discard \(.applicationName) recording"
                ],
                shortTitle: "Cancel Recording",
                systemImageName: "xmark.circle"
            )
    }
}
