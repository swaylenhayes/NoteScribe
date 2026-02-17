# Architecture Move Update (High-Level)

This note summarizes the current `base` / `v2` / `v3` structure and a future layout that separates source from model assets.

## Current layout (today)

### base
base/
- NoteScribe.xcodeproj
- NoteScribe/
  - AppDelegate.swift
  - AppIntents/
    - AppShortcuts.swift
    - DismissMiniRecorderIntent.swift
    - ToggleMiniRecorderIntent.swift
  - Assets.xcassets/
    - AccentColor.colorset/
      - Contents.json
    - AppIcon.appiconset/
      - 1024-mac.png
      - 128-mac.png
      - 16-mac.png
      - 256-mac.png
      - 32-mac.png
      - 512-mac.png
      - 64-mac.png
      - Contents.json
    - Contents.json
    - menuBarIcon.imageset/
      - Contents.json
      - menuBarIcon.png
  - ClipboardManager.swift
  - CursorPaster.swift
  - CustomSoundManager.swift
  - HotkeyManager.swift
  - Info.plist
  - MediaController.swift
  - MenuBarManager.swift
  - MiniRecorderShortcutManager.swift
  - Models/
    - DictionaryItem.swift
    - PredefinedModels.swift
    - Transcription.swift
    - TranscriptionModel.swift
    - TranscriptionPrompt.swift
  - NoteScribe.entitlements
  - NoteScribe.entitlements.release.plist
  - NoteScribe.swift
  - Notifications/
    - AnnouncementManager.swift
    - AnnouncementView.swift
    - AppNotificationView.swift
    - AppNotifications.swift
    - NotificationManager.swift
  - PlaybackController.swift
  - Preview Content/
    - Preview Assets.xcassets/
      - Contents.json
  - Recorder.swift
  - Resources/
    - BundledModels/
      - Parakeet/
      - VAD/
    - Sounds/
      - esc.wav
      - pastess.mp3
      - recstart.mp3
      - recstop.mp3
  - Services/
    - AudioDeviceConfiguration.swift
    - AudioDeviceManager.swift
    - AudioFileProcessor.swift
    - AudioFileTranscriptionManager.swift
    - AudioFileTranscriptionService.swift
    - DictionaryImportExportService.swift
    - ImportExportService.swift
    - LastTranscriptionService.swift
    - ModelInitializationService.swift
    - NoteScribeCSVExportService.swift
    - Obfuscator.swift
    - ParakeetTranscriptionService.swift
    - SupportedMedia.swift
    - SystemInfoService.swift
    - TranscriptionAutoCleanupService.swift
    - TranscriptionOutputFilter.swift
    - TranscriptionService.swift
    - UserDefaultsManager.swift
    - WordReplacementService.swift
  - SoundManager.swift
  - Transcription/
    - TranscriptionError.swift
    - TranscriptionPrompt.swift
    - TranscriptionState+ModelManagement.swift
    - TranscriptionState+ModelQueries.swift
    - TranscriptionState+Parakeet.swift
    - TranscriptionState+UI.swift
    - TranscriptionState.swift
    - TranscriptionTextFormatter.swift
    - VADModelManager.swift
  - Views/
    - AI Models/
      - LanguageSelectionView.swift
      - ModelCardRowView.swift
      - ParakeetModelCardRowView.swift
    - AudioPlayerView.swift
    - AudioTranscribeView.swift
    - Common/
      - AnimatedCopyButton.swift
      - AnimatedSaveButton.swift
      - AppIconView.swift
      - CardBackground.swift
      - View+Placeholder.swift
    - Components/
      - InfoTip.swift
    - ContentView.swift
    - Dictionary/
      - DictionarySettingsView.swift
      - EditReplacementSheet.swift
      - WordReplacementView.swift
    - KeyboardShortcutView.swift
    - KeyboardShortcutsListView.swift
    - MenuBarView.swift
    - ModelSettingsView.swift
    - Recorder/
      - AudioVisualizerView.swift
      - MiniRecorderPanel.swift
      - MiniRecorderView.swift
      - MiniWindowManager.swift
      - NotchRecorderPanel.swift
      - NotchRecorderView.swift
      - NotchShape.swift
      - NotchWindowManager.swift
      - RecorderComponents.swift
    - ScratchpadView.swift
    - Settings/
      - AudioCleanupManager.swift
      - AudioCleanupSettingsView.swift
      - CustomSoundSettingsView.swift
      - ExperimentalFeaturesSection.swift
      - PermissionManager.swift
      - SettingsView.swift
    - TranscriptionCard.swift
    - TranscriptionHistoryView.swift
    - TranscriptionResultView.swift
  - WindowManager.swift
- README.md
- RELEASE_NOTES.md

Notes:
- Model bundles live under `NoteScribe/Resources/BundledModels/Parakeet/` and `NoteScribe/Resources/BundledModels/VAD/`.

### v2
- Same as base, except bundled Parakeet assets differ under `NoteScribe/Resources/BundledModels/Parakeet/`:
  - `parakeet-tdt-0.6b-v2-coreml/`: full CoreML bundle (contains *.mlmodelc)
  - `parakeet-tdt-0.6b-v3-coreml/`: metadata only (no *.mlmodelc)
- `NoteScribe/Resources/BundledModels/VAD/` matches base.

### v3
- Same as base, except bundled Parakeet assets differ under `NoteScribe/Resources/BundledModels/Parakeet/`:
  - `parakeet-tdt-0.6b-v2-coreml/`: full CoreML bundle (contains *.mlmodelc)
  - `parakeet-tdt-0.6b-v3-coreml/`: full CoreML bundle (contains *.mlmodelc)
- `NoteScribe/Resources/BundledModels/VAD/` matches base.

Relationship summary: `base` is the shared source. `v2` and `v3` mirror the same source tree and differ primarily in the bundled Parakeet assets.

## Future layout (proposed)
Goal: keep source code in one place and keep model assets in a separate directory, then bundle the chosen model at build time.

### Proposed folder structure
```
NoteScribe/
  worktrees/
    base/                # main source
    filler-words/        # branch worktree (optional)
  models/                # external model assets
    parakeet-v2/
    parakeet-v3/
    vad/
  _releases/             # DMGs, apps, notarized outputs
    v2/
    v3/
  scripts/               # build/sign/notarize helpers
  archive/               # optional storage for retired variants
```

### Proposed branching model (high-level)
- `main` (base source of truth)
- `filler-words` (branch for filler-word edition)
- optional release branches/tags for v2/v3 builds

Build concept: checkout the source branch (`main` or `filler-words`), point scripts at `models/`, and inject the selected model into the app bundle during build. This yields v2 or v3 builds without duplicating source trees.

## Filler-words edition (future)
High-level idea:
- Base code stays in `main`.
- A `filler-words` branch changes only text-filtering related files (for example `TranscriptionOutputFilter`).
- Build flow uses:
  1) source from `worktrees/filler-words/`
  2) model assets from `models/`
  3) build scripts output to `_releases/`
