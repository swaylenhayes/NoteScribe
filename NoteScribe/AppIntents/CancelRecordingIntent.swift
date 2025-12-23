import AppIntents
import Foundation
import AppKit

struct CancelRecordingIntent: AppIntent {
    static var title: LocalizedStringResource = "Cancel NoteScribe Recording"
    static var description = IntentDescription("Cancel the current NoteScribe recording.")

    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        NotificationCenter.default.post(name: .cancelRecording, object: nil)

        let dialog = IntentDialog(stringLiteral: "NoteScribe recording cancelled")
        return .result(dialog: dialog)
    }
}
