# NoteScribe Project Summary

## What the app is
NoteScribe is a macOS menu bar app for fast voice and file transcription. It runs fully offline using bundled Parakeet Core ML models (v2 or v3), and pastes results into the foreground app or keeps them in the clipboard and history.

## Major features (current)
- Hotkey-driven live transcription with menu bar indicator.
- File transcription (audio and video) with history entries and audio playback.
- Word replacements (dictionary) applied after transcription.
- Output filtering for bracketed noise and filler words.
- Optional text formatting (paragraph chunking).
- Scratchpad tab for quick text capture.
- VAD toggles for live and file transcription.
- Import/export of settings and word replacements.

## Tech stack and key dependencies
- SwiftUI + AppKit
- AVFoundation (audio capture, file processing)
- CoreML (model inference)
- SwiftData (history storage)
- NaturalLanguage (sentence tokenization)
- os.log (logging)
- Swift packages: FluidAudio (ASR + VAD), KeyboardShortcuts

## Model assets
- Parakeet Core ML bundles (v2 + v3) live under `NoteScribe/Resources/BundledModels/Parakeet/` in the v2/v3 worktrees.
- Silero VAD bundle under `NoteScribe/Resources/BundledModels/VAD/`.
- Large model variants (v2-L, v3-L) are archived locally and not intended for GitHub.
- Offline mode is used: model downloads are disabled and models are bundled.

## Repo organization (high level)
- `base/`, `v2/`, `v3/` are full source trees with Xcode projects.
- `_releases/` holds DMGs and notarized outputs.
- `archive/` holds retired items: large models, legacy VAD upgrade folders, and DerivedData.
- Active docs:
  - `AGENTS.md`
  - `CURRENT_STATE.md`
  - `ARCHITECTURE_MOVE_UPDATE.md`

## Release state
- Source repo is published on GitHub: https://github.com/swaylenhayes/NoteScribe
- Current public release: **1.1** with v2 and v3 DMGs attached.

## History highlights
- Fixed Xcode project parse errors and synced `Package.resolved` across worktrees.
- Removed legacy accessibility wrapper dependencies.
- Established build/sign/notarize/staple flow and uninstall helper.
- Standardized filler-word filtering and archived large-model branches.

## Known issues / monitoring
- Watch for first-run paste reliability on fresh installs; if it regresses, add a short initialization gate or visible “ready” state.

## Roadmap (short list)
- Refactor to a single `base` source tree with external model assets injected at build time.
- Create a filler-words edition as a separate branch (text filtering focus).
