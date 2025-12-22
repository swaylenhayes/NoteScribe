import AppIntents
import Foundation
import AppKit

struct StartStopRecordingIntent: AppIntent {
    static var title: LocalizedStringResource = "Start/Stop NoteScribe Recording"
    static var description = IntentDescription("Start or stop NoteScribe recording for transcription.")

    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        NotificationCenter.default.post(name: .toggleRecording, object: nil)

        let dialog = IntentDialog(stringLiteral: "NoteScribe recording toggled")
        return .result(dialog: dialog)
    }
}

enum IntentError: Error, LocalizedError {
    case appNotAvailable
    case serviceNotAvailable

    var errorDescription: String? {
        switch self {
        case .appNotAvailable:
            return "NoteScribe app is not available"
        case .serviceNotAvailable:
            return "NoteScribe recording service is not available"
        }
    }
}
