import Foundation
import AppKit
import UniformTypeIdentifiers
import KeyboardShortcuts
import LaunchAtLogin

struct GeneralSettings: Codable {
    let toggleRecordingShortcut: KeyboardShortcuts.Shortcut?
    let toggleRecordingShortcut2: KeyboardShortcuts.Shortcut?
    let cancelRecorderShortcut: KeyboardShortcuts.Shortcut?
    let pasteLastTranscriptionShortcut: KeyboardShortcuts.Shortcut?
    let selectedHotkey1RawValue: String?
    let selectedHotkey2RawValue: String?
    let selectedLanguage: String?
    let launchAtLoginEnabled: Bool?
    let isMenuBarOnly: Bool?
    let isTranscriptionCleanupEnabled: Bool?
    let transcriptionRetentionMinutes: Int?
    let isAudioCleanupEnabled: Bool?
    let audioRetentionPeriod: Int?

    let isSoundFeedbackEnabled: Bool?
    let isSystemMuteEnabled: Bool?
    let isPauseMediaEnabled: Bool?
    let isTextFormattingEnabled: Bool?
    let isExperimentalFeaturesEnabled: Bool?
    let isVADEnabledLive: Bool?
    let isVADEnabledFile: Bool?
    let preserveTranscriptInClipboard: Bool?
    let isMiddleClickToggleEnabled: Bool?
    let middleClickActivationDelay: Int?
    let appendTrailingSpace: Bool?

    init(
        toggleRecordingShortcut: KeyboardShortcuts.Shortcut?,
        toggleRecordingShortcut2: KeyboardShortcuts.Shortcut?,
        cancelRecorderShortcut: KeyboardShortcuts.Shortcut?,
        pasteLastTranscriptionShortcut: KeyboardShortcuts.Shortcut?,
        selectedHotkey1RawValue: String?,
        selectedHotkey2RawValue: String?,
        selectedLanguage: String?,
        launchAtLoginEnabled: Bool?,
        isMenuBarOnly: Bool?,
        isTranscriptionCleanupEnabled: Bool?,
        transcriptionRetentionMinutes: Int?,
        isAudioCleanupEnabled: Bool?,
        audioRetentionPeriod: Int?,
        isSoundFeedbackEnabled: Bool?,
        isSystemMuteEnabled: Bool?,
        isPauseMediaEnabled: Bool?,
        isTextFormattingEnabled: Bool?,
        isExperimentalFeaturesEnabled: Bool?,
        isVADEnabledLive: Bool?,
        isVADEnabledFile: Bool?,
        preserveTranscriptInClipboard: Bool?,
        isMiddleClickToggleEnabled: Bool?,
        middleClickActivationDelay: Int?,
        appendTrailingSpace: Bool?
    ) {
        self.toggleRecordingShortcut = toggleRecordingShortcut
        self.toggleRecordingShortcut2 = toggleRecordingShortcut2
        self.cancelRecorderShortcut = cancelRecorderShortcut
        self.pasteLastTranscriptionShortcut = pasteLastTranscriptionShortcut
        self.selectedHotkey1RawValue = selectedHotkey1RawValue
        self.selectedHotkey2RawValue = selectedHotkey2RawValue
        self.selectedLanguage = selectedLanguage
        self.launchAtLoginEnabled = launchAtLoginEnabled
        self.isMenuBarOnly = isMenuBarOnly
        self.isTranscriptionCleanupEnabled = isTranscriptionCleanupEnabled
        self.transcriptionRetentionMinutes = transcriptionRetentionMinutes
        self.isAudioCleanupEnabled = isAudioCleanupEnabled
        self.audioRetentionPeriod = audioRetentionPeriod
        self.isSoundFeedbackEnabled = isSoundFeedbackEnabled
        self.isSystemMuteEnabled = isSystemMuteEnabled
        self.isPauseMediaEnabled = isPauseMediaEnabled
        self.isTextFormattingEnabled = isTextFormattingEnabled
        self.isExperimentalFeaturesEnabled = isExperimentalFeaturesEnabled
        self.isVADEnabledLive = isVADEnabledLive
        self.isVADEnabledFile = isVADEnabledFile
        self.preserveTranscriptInClipboard = preserveTranscriptInClipboard
        self.isMiddleClickToggleEnabled = isMiddleClickToggleEnabled
        self.middleClickActivationDelay = middleClickActivationDelay
        self.appendTrailingSpace = appendTrailingSpace
    }

    private enum CodingKeys: String, CodingKey {
        case toggleRecordingShortcut
        case toggleRecordingShortcut2
        case cancelRecorderShortcut
        case pasteLastTranscriptionShortcut
        case selectedHotkey1RawValue
        case selectedHotkey2RawValue
        case selectedLanguage
        case launchAtLoginEnabled
        case isMenuBarOnly
        case isTranscriptionCleanupEnabled
        case transcriptionRetentionMinutes
        case isAudioCleanupEnabled
        case audioRetentionPeriod
        case isSoundFeedbackEnabled
        case isSystemMuteEnabled
        case isPauseMediaEnabled
        case isTextFormattingEnabled
        case isExperimentalFeaturesEnabled
        case isVADEnabledLive
        case isVADEnabledFile
        case preserveTranscriptInClipboard
        case isMiddleClickToggleEnabled
        case middleClickActivationDelay
        case appendTrailingSpace
        case toggleMiniRecorderShortcut
        case toggleMiniRecorderShortcut2
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        toggleRecordingShortcut = try container.decodeIfPresent(KeyboardShortcuts.Shortcut.self, forKey: .toggleRecordingShortcut)
            ?? container.decodeIfPresent(KeyboardShortcuts.Shortcut.self, forKey: .toggleMiniRecorderShortcut)
        toggleRecordingShortcut2 = try container.decodeIfPresent(KeyboardShortcuts.Shortcut.self, forKey: .toggleRecordingShortcut2)
            ?? container.decodeIfPresent(KeyboardShortcuts.Shortcut.self, forKey: .toggleMiniRecorderShortcut2)
        cancelRecorderShortcut = try container.decodeIfPresent(KeyboardShortcuts.Shortcut.self, forKey: .cancelRecorderShortcut)
        pasteLastTranscriptionShortcut = try container.decodeIfPresent(KeyboardShortcuts.Shortcut.self, forKey: .pasteLastTranscriptionShortcut)
        selectedHotkey1RawValue = try container.decodeIfPresent(String.self, forKey: .selectedHotkey1RawValue)
        selectedHotkey2RawValue = try container.decodeIfPresent(String.self, forKey: .selectedHotkey2RawValue)
        selectedLanguage = try container.decodeIfPresent(String.self, forKey: .selectedLanguage)
        launchAtLoginEnabled = try container.decodeIfPresent(Bool.self, forKey: .launchAtLoginEnabled)
        isMenuBarOnly = try container.decodeIfPresent(Bool.self, forKey: .isMenuBarOnly)
        isTranscriptionCleanupEnabled = try container.decodeIfPresent(Bool.self, forKey: .isTranscriptionCleanupEnabled)
        transcriptionRetentionMinutes = try container.decodeIfPresent(Int.self, forKey: .transcriptionRetentionMinutes)
        isAudioCleanupEnabled = try container.decodeIfPresent(Bool.self, forKey: .isAudioCleanupEnabled)
        audioRetentionPeriod = try container.decodeIfPresent(Int.self, forKey: .audioRetentionPeriod)
        isSoundFeedbackEnabled = try container.decodeIfPresent(Bool.self, forKey: .isSoundFeedbackEnabled)
        isSystemMuteEnabled = try container.decodeIfPresent(Bool.self, forKey: .isSystemMuteEnabled)
        isPauseMediaEnabled = try container.decodeIfPresent(Bool.self, forKey: .isPauseMediaEnabled)
        isTextFormattingEnabled = try container.decodeIfPresent(Bool.self, forKey: .isTextFormattingEnabled)
        isExperimentalFeaturesEnabled = try container.decodeIfPresent(Bool.self, forKey: .isExperimentalFeaturesEnabled)
        isVADEnabledLive = try container.decodeIfPresent(Bool.self, forKey: .isVADEnabledLive)
        isVADEnabledFile = try container.decodeIfPresent(Bool.self, forKey: .isVADEnabledFile)
        preserveTranscriptInClipboard = try container.decodeIfPresent(Bool.self, forKey: .preserveTranscriptInClipboard)
        isMiddleClickToggleEnabled = try container.decodeIfPresent(Bool.self, forKey: .isMiddleClickToggleEnabled)
        middleClickActivationDelay = try container.decodeIfPresent(Int.self, forKey: .middleClickActivationDelay)
        appendTrailingSpace = try container.decodeIfPresent(Bool.self, forKey: .appendTrailingSpace)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(toggleRecordingShortcut, forKey: .toggleRecordingShortcut)
        try container.encodeIfPresent(toggleRecordingShortcut2, forKey: .toggleRecordingShortcut2)
        try container.encodeIfPresent(cancelRecorderShortcut, forKey: .cancelRecorderShortcut)
        try container.encodeIfPresent(pasteLastTranscriptionShortcut, forKey: .pasteLastTranscriptionShortcut)
        try container.encodeIfPresent(selectedHotkey1RawValue, forKey: .selectedHotkey1RawValue)
        try container.encodeIfPresent(selectedHotkey2RawValue, forKey: .selectedHotkey2RawValue)
        try container.encodeIfPresent(selectedLanguage, forKey: .selectedLanguage)
        try container.encodeIfPresent(launchAtLoginEnabled, forKey: .launchAtLoginEnabled)
        try container.encodeIfPresent(isMenuBarOnly, forKey: .isMenuBarOnly)
        try container.encodeIfPresent(isTranscriptionCleanupEnabled, forKey: .isTranscriptionCleanupEnabled)
        try container.encodeIfPresent(transcriptionRetentionMinutes, forKey: .transcriptionRetentionMinutes)
        try container.encodeIfPresent(isAudioCleanupEnabled, forKey: .isAudioCleanupEnabled)
        try container.encodeIfPresent(audioRetentionPeriod, forKey: .audioRetentionPeriod)
        try container.encodeIfPresent(isSoundFeedbackEnabled, forKey: .isSoundFeedbackEnabled)
        try container.encodeIfPresent(isSystemMuteEnabled, forKey: .isSystemMuteEnabled)
        try container.encodeIfPresent(isPauseMediaEnabled, forKey: .isPauseMediaEnabled)
        try container.encodeIfPresent(isTextFormattingEnabled, forKey: .isTextFormattingEnabled)
        try container.encodeIfPresent(isExperimentalFeaturesEnabled, forKey: .isExperimentalFeaturesEnabled)
        try container.encodeIfPresent(isVADEnabledLive, forKey: .isVADEnabledLive)
        try container.encodeIfPresent(isVADEnabledFile, forKey: .isVADEnabledFile)
        try container.encodeIfPresent(preserveTranscriptInClipboard, forKey: .preserveTranscriptInClipboard)
        try container.encodeIfPresent(isMiddleClickToggleEnabled, forKey: .isMiddleClickToggleEnabled)
        try container.encodeIfPresent(middleClickActivationDelay, forKey: .middleClickActivationDelay)
        try container.encodeIfPresent(appendTrailingSpace, forKey: .appendTrailingSpace)
    }
}

// OFFLINE MODE: Removed customCloudModels field (not supported)
struct NoteScribeExportedSettings: Codable {
    let version: String
    let dictionaryItems: [DictionaryItem]?
    let wordReplacements: [String: String]?
    let generalSettings: GeneralSettings?
    let customLanguagePrompts: [String: String]?
    let customEmojis: [String]?
}

class ImportExportService {
    static let shared = ImportExportService()
    private let currentSettingsVersion: String
    private let dictionaryItemsKey = "CustomVocabularyItems"
    private let wordReplacementsKey = "wordReplacements"


    private let keyIsMenuBarOnly = "IsMenuBarOnly"
    private let keyRecorderType = "RecorderType"
    private let keyIsAudioCleanupEnabled = "IsAudioCleanupEnabled"
    private let keyIsTranscriptionCleanupEnabled = "IsTranscriptionCleanupEnabled"
    private let keyTranscriptionRetentionMinutes = "TranscriptionRetentionMinutes"
    private let keyAudioRetentionPeriod = "AudioRetentionPeriod"

    private let keyIsSoundFeedbackEnabled = "isSoundFeedbackEnabled"
    private let keyIsSystemMuteEnabled = "isSystemMuteEnabled"
    private let keyIsTextFormattingEnabled = "IsTextFormattingEnabled"
    private let keySelectedLanguage = "SelectedLanguage"
    private let keyIsVADEnabledLive = "IsVADEnabledLive"
    private let keyIsVADEnabledFile = "IsVADEnabledFile"
    private let keyPreserveTranscriptInClipboard = "preserveTranscriptInClipboard"
    private let keyIsMiddleClickToggleEnabled = "isMiddleClickToggleEnabled"
    private let keyMiddleClickActivationDelay = "middleClickActivationDelay"
    private let keyAppendTrailingSpace = "AppendTrailingSpace"
    private let keyCustomLanguagePrompts = "CustomLanguagePrompts"

    private init() {
        if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            self.currentSettingsVersion = version
        } else {
            self.currentSettingsVersion = "0.0.0"
        }
    }

    @MainActor
    func exportSettings(transcriptionPrompt: TranscriptionPrompt, hotkeyManager: HotkeyManager, menuBarManager: MenuBarManager, mediaController: MediaController, playbackController: PlaybackController, soundManager: SoundManager, transcriptionState: TranscriptionState) {

        var exportedDictionaryItems: [DictionaryItem]? = nil
        if let data = UserDefaults.standard.data(forKey: dictionaryItemsKey),
           let items = try? JSONDecoder().decode([DictionaryItem].self, from: data) {
            exportedDictionaryItems = items
        }

        let exportedWordReplacements = UserDefaults.standard.dictionary(forKey: wordReplacementsKey) as? [String: String]
        let customLanguagePrompts = UserDefaults.standard.dictionary(forKey: keyCustomLanguagePrompts) as? [String: String]

        let generalSettingsToExport = GeneralSettings(
            toggleRecordingShortcut: KeyboardShortcuts.getShortcut(for: .toggleRecording),
            toggleRecordingShortcut2: KeyboardShortcuts.getShortcut(for: .toggleRecording2),
            cancelRecorderShortcut: KeyboardShortcuts.getShortcut(for: .cancelRecorder),
            pasteLastTranscriptionShortcut: KeyboardShortcuts.getShortcut(for: .pasteLastTranscription),
            selectedHotkey1RawValue: hotkeyManager.selectedHotkey1.rawValue,
            selectedHotkey2RawValue: hotkeyManager.selectedHotkey2.rawValue,
            selectedLanguage: UserDefaults.standard.string(forKey: keySelectedLanguage),
            launchAtLoginEnabled: LaunchAtLogin.isEnabled,
            isMenuBarOnly: menuBarManager.isMenuBarOnly,
            isTranscriptionCleanupEnabled: UserDefaults.standard.bool(forKey: keyIsTranscriptionCleanupEnabled),
            transcriptionRetentionMinutes: UserDefaults.standard.integer(forKey: keyTranscriptionRetentionMinutes),
            isAudioCleanupEnabled: UserDefaults.standard.bool(forKey: keyIsAudioCleanupEnabled),
            audioRetentionPeriod: UserDefaults.standard.integer(forKey: keyAudioRetentionPeriod),

            isSoundFeedbackEnabled: soundManager.isEnabled,
            isSystemMuteEnabled: mediaController.isSystemMuteEnabled,
            isPauseMediaEnabled: playbackController.isPauseMediaEnabled,
            isTextFormattingEnabled: UserDefaults.standard.object(forKey: keyIsTextFormattingEnabled) as? Bool ?? true,
            isExperimentalFeaturesEnabled: UserDefaults.standard.bool(forKey: "isExperimentalFeaturesEnabled"),
            isVADEnabledLive: UserDefaults.standard.object(forKey: keyIsVADEnabledLive) as? Bool ?? true,
            isVADEnabledFile: UserDefaults.standard.object(forKey: keyIsVADEnabledFile) as? Bool ?? true,
            preserveTranscriptInClipboard: UserDefaults.standard.object(forKey: keyPreserveTranscriptInClipboard) as? Bool ?? true,
            isMiddleClickToggleEnabled: hotkeyManager.isMiddleClickToggleEnabled,
            middleClickActivationDelay: hotkeyManager.middleClickActivationDelay,
            appendTrailingSpace: UserDefaults.standard.object(forKey: keyAppendTrailingSpace) as? Bool ?? true
        )

        // OFFLINE MODE: No custom cloud models to export
        let exportedSettings = NoteScribeExportedSettings(
            version: currentSettingsVersion,
            dictionaryItems: exportedDictionaryItems,
            wordReplacements: exportedWordReplacements,
            generalSettings: generalSettingsToExport,
            customLanguagePrompts: customLanguagePrompts,
            customEmojis: nil
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        do {
            let jsonData = try encoder.encode(exportedSettings)

            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = [UTType.json]
            savePanel.nameFieldStringValue = "NoteScribe_Settings_Backup.json"
            savePanel.title = "Export NoteScribe Settings"
            savePanel.message = "Choose a location to save your settings."

            DispatchQueue.main.async {
                if savePanel.runModal() == .OK {
                    if let url = savePanel.url {
                        do {
                            try jsonData.write(to: url)
                            self.showAlert(title: "Export Successful", message: "Your settings have been successfully exported to \(url.lastPathComponent).")
                        } catch {
                            self.showAlert(title: "Export Error", message: "Could not save settings to file: \(error.localizedDescription)")
                        }
                    }
                } else {
                    self.showAlert(title: "Export Canceled", message: "The settings export operation was canceled.")
                }
            }
        } catch {
            self.showAlert(title: "Export Error", message: "Could not encode settings to JSON: \(error.localizedDescription)")
        }
    }

    @MainActor
    func importSettings(transcriptionPrompt: TranscriptionPrompt, hotkeyManager: HotkeyManager, menuBarManager: MenuBarManager, mediaController: MediaController, playbackController: PlaybackController, soundManager: SoundManager, transcriptionState: TranscriptionState) {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [UTType.json]
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.title = "Import NoteScribe Settings"
        openPanel.message = "Choose a settings file to import. This will overwrite ALL settings (prompts, power modes, dictionary, general app settings)."

        DispatchQueue.main.async {
            if openPanel.runModal() == .OK {
                guard let url = openPanel.url else {
                    self.showAlert(title: "Import Error", message: "Could not get the file URL from the open panel.")
                    return
                }

                do {
                    let jsonData = try Data(contentsOf: url)
                    let decoder = JSONDecoder()
                    let importedSettings = try decoder.decode(NoteScribeExportedSettings.self, from: jsonData)
                    
                    if importedSettings.version != self.currentSettingsVersion {
                        self.showAlert(title: "Version Mismatch", message: "The imported settings file (version \(importedSettings.version)) is from a different version than your application (version \(self.currentSettingsVersion)). Proceeding with import, but be aware of potential incompatibilities.")
                    }

                    var importedSelectedLanguage: String? = nil

                
                    
        

                    if let itemsToImport = importedSettings.dictionaryItems {
                        if let encoded = try? JSONEncoder().encode(itemsToImport) {
                            UserDefaults.standard.set(encoded, forKey: "CustomVocabularyItems")
                        }
                    } else {
                        print("No custom vocabulary items (for spelling) found in the imported file. Existing items remain unchanged.")
                    }

                    if let replacementsToImport = importedSettings.wordReplacements {
                        UserDefaults.standard.set(replacementsToImport, forKey: self.wordReplacementsKey)
                    } else {
                        print("No word replacements found in the imported file. Existing replacements remain unchanged.")
                    }

                    if let general = importedSettings.generalSettings {
                        if let shortcut = general.toggleRecordingShortcut {
                            KeyboardShortcuts.setShortcut(shortcut, for: .toggleRecording)
                        }
                        if let shortcut2 = general.toggleRecordingShortcut2 {
                            KeyboardShortcuts.setShortcut(shortcut2, for: .toggleRecording2)
                        }
                        if let cancelShortcut = general.cancelRecorderShortcut {
                            KeyboardShortcuts.setShortcut(cancelShortcut, for: .cancelRecorder)
                        }
                        if let pasteShortcut = general.pasteLastTranscriptionShortcut {
                            KeyboardShortcuts.setShortcut(pasteShortcut, for: .pasteLastTranscription)
                        }
                        if let hotkeyRaw = general.selectedHotkey1RawValue,
                           let hotkey = HotkeyManager.HotkeyOption(rawValue: hotkeyRaw) {
                            hotkeyManager.selectedHotkey1 = hotkey
                        }
                        if let hotkeyRaw2 = general.selectedHotkey2RawValue,
                           let hotkey2 = HotkeyManager.HotkeyOption(rawValue: hotkeyRaw2) {
                            hotkeyManager.selectedHotkey2 = hotkey2
                        }
                        if let selectedLanguage = general.selectedLanguage {
                            importedSelectedLanguage = selectedLanguage
                            UserDefaults.standard.set(selectedLanguage, forKey: self.keySelectedLanguage)
                        }
                        if let launch = general.launchAtLoginEnabled {
                            LaunchAtLogin.isEnabled = launch
                        }
                        if let menuOnly = general.isMenuBarOnly {
                            menuBarManager.isMenuBarOnly = menuOnly
                        }
                        
                        if let transcriptionCleanup = general.isTranscriptionCleanupEnabled {
                            UserDefaults.standard.set(transcriptionCleanup, forKey: self.keyIsTranscriptionCleanupEnabled)
                        }
                        if let transcriptionMinutes = general.transcriptionRetentionMinutes {
                            UserDefaults.standard.set(transcriptionMinutes, forKey: self.keyTranscriptionRetentionMinutes)
                        }
                        if let audioCleanup = general.isAudioCleanupEnabled {
                            UserDefaults.standard.set(audioCleanup, forKey: self.keyIsAudioCleanupEnabled)
                        }
                        if let audioRetention = general.audioRetentionPeriod {
                            UserDefaults.standard.set(audioRetention, forKey: self.keyAudioRetentionPeriod)
                        }

                        if let soundFeedback = general.isSoundFeedbackEnabled {
                            soundManager.isEnabled = soundFeedback
                        }
                        if let muteSystem = general.isSystemMuteEnabled {
                            mediaController.isSystemMuteEnabled = muteSystem
                        }
                        if let pauseMedia = general.isPauseMediaEnabled {
                            playbackController.isPauseMediaEnabled = pauseMedia
                        }
                        if let experimentalEnabled = general.isExperimentalFeaturesEnabled {
                            UserDefaults.standard.set(experimentalEnabled, forKey: "isExperimentalFeaturesEnabled")
                            if experimentalEnabled == false {
                                playbackController.isPauseMediaEnabled = false
                            }
                        }
                        if let textFormattingEnabled = general.isTextFormattingEnabled {
                            UserDefaults.standard.set(textFormattingEnabled, forKey: self.keyIsTextFormattingEnabled)
                        }
                        if let vadLive = general.isVADEnabledLive {
                            UserDefaults.standard.set(vadLive, forKey: self.keyIsVADEnabledLive)
                        }
                        if let vadFile = general.isVADEnabledFile {
                            UserDefaults.standard.set(vadFile, forKey: self.keyIsVADEnabledFile)
                        }
                        if let preserveClipboard = general.preserveTranscriptInClipboard {
                            UserDefaults.standard.set(preserveClipboard, forKey: self.keyPreserveTranscriptInClipboard)
                        }
                        if let middleClickEnabled = general.isMiddleClickToggleEnabled {
                            hotkeyManager.isMiddleClickToggleEnabled = middleClickEnabled
                        }
                        if let middleClickDelay = general.middleClickActivationDelay {
                            hotkeyManager.middleClickActivationDelay = middleClickDelay
                        }
                        if let appendTrailingSpace = general.appendTrailingSpace {
                            UserDefaults.standard.set(appendTrailingSpace, forKey: self.keyAppendTrailingSpace)
                        }
                    }

                    if let customPrompts = importedSettings.customLanguagePrompts {
                        transcriptionPrompt.replaceCustomPrompts(customPrompts)
                    } else if importedSelectedLanguage != nil {
                        transcriptionPrompt.updateTranscriptionPrompt()
                    }

                    if importedSelectedLanguage != nil {
                        NotificationCenter.default.post(name: .languageDidChange, object: nil)
                        NotificationCenter.default.post(name: .AppSettingsDidChange, object: nil)
                    }

                    self.showRestartAlert(message: "Settings imported successfully from \(url.lastPathComponent). All settings (including general app settings) have been applied.")

                } catch {
                    self.showAlert(title: "Import Error", message: "Error importing settings: \(error.localizedDescription). The file might be corrupted or not in the correct format.")
                }
            } else {
                self.showAlert(title: "Import Canceled", message: "The settings import operation was canceled.")
            }
        }
    }

    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = message
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    private func showRestartAlert(message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Import Successful"
            alert.informativeText = message + "\n\nIt is recommended to restart NoteScribe for all changes to take full effect."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
}
