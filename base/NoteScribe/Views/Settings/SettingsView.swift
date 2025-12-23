import SwiftUI
import Cocoa
import KeyboardShortcuts
import LaunchAtLogin

// OFFLINE MODE: Detect offline mode
#if !ENABLE_AI_ENHANCEMENT
private let isOfflineMode = true
#else
private let isOfflineMode = false
#endif

struct SettingsView: View {
    @EnvironmentObject private var menuBarManager: MenuBarManager
    @EnvironmentObject private var hotkeyManager: HotkeyManager
    @EnvironmentObject private var transcriptionState: TranscriptionState
    @ObservedObject private var soundManager = SoundManager.shared
    @ObservedObject private var mediaController = MediaController.shared
    @ObservedObject private var playbackController = PlaybackController.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @AppStorage("autoUpdateCheck") private var autoUpdateCheck = true
    @AppStorage("enableAnnouncements") private var enableAnnouncements = true
    @AppStorage("IsVADEnabledLive") private var isVADEnabledLive = true
    @AppStorage("IsVADEnabledFile") private var isVADEnabledFile = true
    @AppStorage("preserveTranscriptInClipboard") private var preserveTranscriptInClipboard = true
    @State private var showResetOnboardingAlert = false
    @State private var isCustomSoundsExpanded = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                sectionBlock("Shortcuts") {
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            shortcutPickerRow(title: "Hotkey 1", binding: $hotkeyManager.selectedHotkey1, name: .toggleRecording)
                            shortcutPickerRow(title: "Hotkey 2", binding: $hotkeyManager.selectedHotkey2, name: .toggleRecording2)
                        }
                        Text("Quick tap to start/stop hands-free recording. Press and hold for push-to-talk.")
                            .font(.footnote)
                            .foregroundColor(.secondary)

                        Divider()

                        shortcutRecorderRow(title: "Custom Cancel Shortcut", name: .cancelRecorder, message: "Interrupt an in-progress recording or transcription.")

                        Divider()

                        shortcutRecorderRow(title: "Paste Last Transcript", name: .pasteLastTranscription, message: "Shortcut for pasting the most recent transcription.")
                    }
                }

                sectionBlock("Voice Activity Detection") {
                    Toggle("Use VAD for live dictation (hotkey)", isOn: $isVADEnabledLive)
                        .help("Skips silence and background noise while recording. Turn off for fastest, clean dictation.")
                    Toggle("Use VAD for file transcription", isOn: $isVADEnabledFile)
                        .help("Skips silence in imported files. Turn off to maximize speed on short or clean clips.")
                }

                sectionBlock("Recording Feedback") {
                    Toggle("Sound feedback", isOn: $soundManager.isEnabled)
                        .onTapGesture {
                            if soundManager.isEnabled {
                                withAnimation { isCustomSoundsExpanded.toggle() }
                            }
                        }

                    if soundManager.isEnabled && isCustomSoundsExpanded {
                        CustomSoundSettingsView()
                    }

                    Toggle("Mute system audio during recording", isOn: $mediaController.isSystemMuteEnabled)
                    Toggle("Preserve transcript in clipboard", isOn: $preserveTranscriptInClipboard)
                }

                sectionBlock("General") {
                    Toggle("Hide Dock Icon (Menu Bar Only)", isOn: $menuBarManager.isMenuBarOnly)
                    LaunchAtLogin.Toggle()
                    // Auto-update/announcements disabled for open source distribution
                }

                sectionBlock("Import & Export") {
                    Text("Export your custom prompts, word replacements, shortcuts, and preferences to a backup file. API keys are not included.")
                        .font(.footnote)
                        .foregroundColor(.secondary)

                    HStack {
                        Button {
                            ImportExportService.shared.importSettings(
                                transcriptionPrompt: transcriptionState.transcriptionPrompt,
                                hotkeyManager: hotkeyManager,
                                menuBarManager: menuBarManager,
                                mediaController: MediaController.shared,
                                playbackController: PlaybackController.shared,
                                soundManager: SoundManager.shared,
                                transcriptionState: transcriptionState
                            )
                        } label: {
                            Label("Import Settings...", systemImage: "arrow.down.doc")
                        }

                        Button {
                            ImportExportService.shared.exportSettings(
                                transcriptionPrompt: transcriptionState.transcriptionPrompt,
                                hotkeyManager: hotkeyManager,
                                menuBarManager: menuBarManager,
                                mediaController: MediaController.shared,
                                playbackController: PlaybackController.shared,
                                soundManager: SoundManager.shared,
                                transcriptionState: transcriptionState
                            )
                        } label: {
                            Label("Export Settings...", systemImage: "arrow.up.doc")
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .safeAreaInset(edge: .top) {
            Color.clear.frame(height: 24)
        }
        .alert("Reset Onboarding", isPresented: $showResetOnboardingAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                DispatchQueue.main.async { hasCompletedOnboarding = false }
            }
        } message: {
            Text("Are you sure you want to reset the onboarding? You'll see the introduction screens again the next time you launch the app.")
        }
    }

    private func shortcutPickerRow(title: String, binding: Binding<HotkeyManager.HotkeyOption>, name: KeyboardShortcuts.Name) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text("Toggle recording")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Menu {
                ForEach(HotkeyManager.HotkeyOption.allCases, id: \.self) { option in
                    Button(option.displayName) { binding.wrappedValue = option }
                }
            } label: {
                HStack(spacing: 8) {
                    Text(binding.wrappedValue.displayName)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .menuStyle(.borderlessButton)
            .frame(width: 200, alignment: .trailing)

            if binding.wrappedValue == .custom {
                KeyboardShortcuts.Recorder(for: name)
                    .controlSize(.small)
            }
        }
    }

    private func shortcutRecorderRow(title: String, name: KeyboardShortcuts.Name, message: String) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(message)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            Spacer()
            KeyboardShortcuts.Recorder(for: name)
                .controlSize(.small)
        }
    }

    private func sectionBlock(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.windowBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
            )
        }
    }
}
