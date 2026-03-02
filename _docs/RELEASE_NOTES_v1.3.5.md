# NoteScribe v1.3.5 Release Notes

**Release Date:** March 1, 2026

## Highlights
- NoteScribe now uses the new app identity `com.swaylenserves.notescribe` with built-in migration for existing local app data.
- Existing transcripts, recordings, and settings are migrated forward automatically when the app finds legacy data from older installs.
- The uninstall helper now preserves user-created data by default while still clearing app permissions and local state.

## Improvements
- Application Support storage, custom sounds, logger subsystems, and related app identity strings are now centralized for easier maintenance.
- The app migrates legacy defaults and legacy custom-sound locations before SwiftData initializes, reducing upgrade friction.
- Release packaging continues to publish the streamlined `v3` and `v2v3` DMG variants only.

## Fixes
- Prevented upgrades from silently starting fresh when older app data exists under the legacy bundle identifier.
- Added safe conflict handling when both legacy and current app-support folders exist, avoiding destructive overwrites.
- The uninstall flow no longer relocates transcripts and recordings into timestamped Desktop backups unless you explicitly request full data removal.

## Build & Release
- Signed, notarized, stapled, and validated DMG artifacts are provided for:
  - `NoteScribe-v3.dmg`
  - `NoteScribe-v2v3.dmg`

## Requirements
- macOS 14+
- Apple Silicon (M-series)
