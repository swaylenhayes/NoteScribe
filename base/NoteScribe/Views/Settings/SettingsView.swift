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
    @Environment(\.colorScheme) private var colorScheme
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
    @State private var selectedTranscriptionModelName = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LayoutMetrics.sectionGap) {
                AppSectionHeader("Settings")

                VStack(alignment: .leading, spacing: LayoutMetrics.sectionGap) {
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

                    sectionBlock("Transcription Model") {
                        if availableParakeetModels.isEmpty {
                            Text("No bundled Parakeet models were found.")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        } else {
                            if colorScheme == .dark {
                                Menu {
                                    ForEach(availableParakeetModels, id: \.name) { model in
                                        Button {
                                            selectedTranscriptionModelName = model.name
                                        } label: {
                                            if model.name == selectedTranscriptionModelName {
                                                Label(model.displayName, systemImage: "checkmark")
                                            } else {
                                                Text(model.displayName)
                                            }
                                        }
                                    }
                                } label: {
                                    controlSurface {
                                        HStack(spacing: 8) {
                                            Text(selectedModelDisplayName)
                                            Spacer(minLength: 8)
                                            Image(systemName: "chevron.up.chevron.down")
                                                .font(.system(size: 10))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .menuStyle(.borderlessButton)
                                .buttonStyle(.plain)
                            } else {
                                Picker("Default model", selection: $selectedTranscriptionModelName) {
                                    ForEach(availableParakeetModels, id: \.name) { model in
                                        Text(model.displayName).tag(model.name)
                                    }
                                }
                                .pickerStyle(.menu)
                            }

                            if let currentModel = currentParakeetModel {
                                Text(currentModel.description)
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
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
                            if colorScheme == .dark {
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
                                .buttonStyle(NeutralControlButtonStyle())

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
                                .buttonStyle(NeutralControlButtonStyle())
                            } else {
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
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, LayoutMetrics.horizontalInset)
                .padding(.bottom, LayoutMetrics.horizontalInset)
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            transcriptionState.refreshAllAvailableModels()
            syncSelectedModelName()
        }
        .onChange(of: transcriptionState.currentTranscriptionModel?.name) { _ in
            syncSelectedModelName()
        }
        .onChange(of: selectedTranscriptionModelName) { newValue in
            applySelectedTranscriptionModel(named: newValue)
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
                if colorScheme == .dark {
                    controlSurface {
                        HStack(spacing: 8) {
                            Text(binding.wrappedValue.displayName)
                            Spacer(minLength: 8)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    HStack(spacing: 8) {
                        Text(binding.wrappedValue.displayName)
                        Spacer(minLength: 8)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .menuStyle(.borderlessButton)
            .buttonStyle(.plain)
            .frame(width: 200, alignment: .trailing)

            if binding.wrappedValue == .custom {
                Group {
                    if colorScheme == .dark {
                        controlSurface {
                            KeyboardShortcuts.Recorder(for: name)
                                .controlSize(.small)
                        }
                    } else {
                        KeyboardShortcuts.Recorder(for: name)
                            .controlSize(.small)
                    }
                }
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
            Group {
                if colorScheme == .dark {
                    controlSurface {
                        KeyboardShortcuts.Recorder(for: name)
                            .controlSize(.small)
                    }
                } else {
                    KeyboardShortcuts.Recorder(for: name)
                        .controlSize(.small)
                }
            }
        }
    }

    private func sectionBlock(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.textBackgroundColor).opacity(0.9))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(NSColor.separatorColor).opacity(0.45), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 3, x: 0, y: 1)
        }
    }

    private var availableParakeetModels: [ParakeetModel] {
        transcriptionState.allAvailableModels.compactMap { $0 as? ParakeetModel }
    }

    private var currentParakeetModel: ParakeetModel? {
        if let currentName = transcriptionState.currentTranscriptionModel?.name,
           let currentModel = availableParakeetModels.first(where: { $0.name == currentName }) {
            return currentModel
        }

        return availableParakeetModels.first(where: { $0.name == selectedTranscriptionModelName })
    }

    private var selectedModelDisplayName: String {
        availableParakeetModels.first(where: { $0.name == selectedTranscriptionModelName })?.displayName ?? "Select model"
    }

    @ViewBuilder
    private func controlSurface<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(StyleConstants.activeTabFill)
            )
    }

    private func syncSelectedModelName() {
        if let currentName = transcriptionState.currentTranscriptionModel?.name,
           availableParakeetModels.contains(where: { $0.name == currentName }) {
            selectedTranscriptionModelName = currentName
            return
        }

        if selectedTranscriptionModelName.isEmpty, let firstModel = availableParakeetModels.first {
            selectedTranscriptionModelName = firstModel.name
        }
    }

    private func applySelectedTranscriptionModel(named modelName: String) {
        guard let selectedModel = availableParakeetModels.first(where: { $0.name == modelName }) else {
            return
        }
        guard transcriptionState.currentTranscriptionModel?.name != selectedModel.name else {
            return
        }

        transcriptionState.setDefaultTranscriptionModel(selectedModel)
        Task {
            await transcriptionState.prewarmModel()
        }
    }
}
