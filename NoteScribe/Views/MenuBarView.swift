import SwiftUI
import LaunchAtLogin

struct MenuBarView: View {
    @EnvironmentObject var transcriptionState: TranscriptionState
    @EnvironmentObject var menuBarManager: MenuBarManager
    // OFFLINE MODE: Removed enhancementService and aiService
    @State private var launchAtLoginEnabled = LaunchAtLogin.isEnabled
    
    var body: some View {
        VStack {
            Button("Open NoteScribe") {
                menuBarManager.openMainWindowAndNavigate(to: "NoteScribe")
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])

            Divider()

            Button("Open File Transcription") {
                menuBarManager.openMainWindowAndNavigate(to: "Transcription")
            }

            Button("Retry Last Transcription") {
                LastTranscriptionService.retryLastTranscription(from: transcriptionState.modelContext, transcriptionState: transcriptionState)
            }
            
            Button("Copy Last Transcription") {
                LastTranscriptionService.copyLastTranscription(from: transcriptionState.modelContext)
            }
            .keyboardShortcut("c", modifiers: [.command, .shift])

            Button("Open History") {
                menuBarManager.openMainWindowAndNavigate(to: "History")
            }

            Button("Open Replacements") {
                menuBarManager.openMainWindowAndNavigate(to: "Replacements")
            }

            Button("Open Settings") {
                menuBarManager.openMainWindowAndNavigate(to: "Settings")
            }
            .keyboardShortcut(",", modifiers: .command)
            
            Divider()

            Button(menuBarManager.isMenuBarOnly ? "Show Dock Icon" : "Hide Dock Icon") {
                menuBarManager.toggleMenuBarOnly()
            }
            .keyboardShortcut("d", modifiers: [.command, .shift])
            
            Toggle("Launch at Login", isOn: $launchAtLoginEnabled)
                .onChange(of: launchAtLoginEnabled) { oldValue, newValue in
                    LaunchAtLogin.isEnabled = newValue
                }

            Divider()
            
            Button("Quit NoteScribe") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
