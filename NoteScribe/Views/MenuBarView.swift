import SwiftUI
import LaunchAtLogin

struct MenuBarView: View {
    @EnvironmentObject var transcriptionState: TranscriptionState
    @EnvironmentObject var menuBarManager: MenuBarManager
    // OFFLINE MODE: Removed enhancementService and aiService
    @State private var launchAtLoginEnabled = LaunchAtLogin.isEnabled
    
    var body: some View {
        VStack {
            // Model loading status indicator
            if transcriptionState.isModelLoading {
                HStack {
                    ProgressView()
                        .controlSize(.small)
                    Text("Loading AI model...")
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
                Divider()
            }

            Button("Open Scratch Pad") {
                menuBarManager.openMainWindowAndNavigate(to: "Scratch Pad")
            }

            Divider()

            Button("Retry Last Transcription") {
                LastTranscriptionService.retryLastTranscription(from: transcriptionState.modelContext, transcriptionState: transcriptionState)
            }
            
            Button("Copy Last Transcription") {
                LastTranscriptionService.copyLastTranscription(from: transcriptionState.modelContext)
            }

            Button("Open Transcription") {
                menuBarManager.openMainWindowAndNavigate(to: "Transcription")
            }

            Button("Open Settings") {
                menuBarManager.openMainWindowAndNavigate(to: "Settings")
            }
            .keyboardShortcut(",", modifiers: .command)
            
            Divider()

            Button(menuBarManager.isMenuBarOnly ? "Show Dock Icon" : "Hide Dock Icon") {
                menuBarManager.toggleMenuBarOnly()
            }
            
            Toggle("Launch at Login", isOn: $launchAtLoginEnabled)
                .onChange(of: launchAtLoginEnabled) { oldValue, newValue in
                    LaunchAtLogin.isEnabled = newValue
                }

            Button("Quit NoteScribe") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
