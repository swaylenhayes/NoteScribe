# NoteScribe v1.3.2 Release Notes

**Release Date:** February 17, 2026

## Highlights
- New macOS-native UI polish pass across all tabs (`Scratch Pad`, `Transcription`, `Replacements`, `Settings`).
- Unified `Transcription` workspace now combines file import and searchable history in one flow.
- Added side-by-side model support and faster switching behavior for Parakeet V2/V3.
- Release pipeline now consistently signs, notarizes, staples, and validates DMG artifacts.

## New & Improved
- Updated tab structure and section headers for better consistency and clearer navigation.
- Narrower default window behavior with a `650px` minimum width for improved compact layouts.
- Transcription history entries now show text clearly and include both `Copy` and `Save` actions.
- Drag-and-drop transcription UX improved to accept drops throughout the Transcription view.
- Settings polish includes clearer control grouping and default model selection improvements.

## Reliability Fixes
- Migrated model setup to idempotent `ModelBundleManager` loading path.
- Removed legacy one-shot model initialization path.
- Fixed accessibility permission loop behavior:
  - `CursorPaster` now prompts once, then retries silently with cooldown.
  - session-level permission prompt handling was tightened.
- Fixed runtime model-copy failures in local dev/debug flows.

## Build & Release
- FluidAudio package pinned to a known-good revision for universal/release compatibility.
- Build script now handles:
  - signed app packaging
  - signed DMG container
  - notarization submission
  - stapling and staple validation
- Verified signed + notarized artifacts:
  - `NoteScribe-v2.dmg` (English)
  - `NoteScribe-v3.dmg` (Multilingual)

## Downloads
- `NoteScribe-v2.dmg`
- `NoteScribe-v3.dmg`

## Requirements
- macOS 14+
- Apple Silicon (M-series)
