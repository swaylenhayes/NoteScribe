# NoteScribe v1.3.3 Release Notes

**Release Date:** February 18, 2026
**Release Update:** February 21, 2026 (combined V2+V3 bundle added)

## Highlights
- Refreshed recording and interaction sounds for a cleaner, more distinct audible workflow.
- Fixed an issue where the Escape cue could play when stopping recording, even when Escape was not pressed.
- Improved cancel/stop sound-path separation so normal stop now consistently plays only the stop cue.

## Improvements
- Updated bundled sound assets for:
  - Recording start
  - Recording stop
  - Paste confirmation
  - Escape/cancel cue

## Fixes
- Removed unintended Escape sound playback from non-cancel stop paths.
- Prevented error notifications from triggering Escape audio feedback.
- Hardened Escape shortcut behavior when Escape is also configured as a recording toggle shortcut.
- Ensured stop/finalize flows use UI cleanup without invoking cancel audio cues.

## Build & Release
- Signed, notarized, stapled, and validated DMG artifacts produced for:
  - `NoteScribe-v2.dmg`
  - `NoteScribe-v3.dmg`
  - `NoteScribe-v2v3.dmg` (combined payload with both Parakeet V2 and V3 in one app)

## Combined Bundle
- `NoteScribe-v2v3.dmg` includes both Parakeet V2 and Parakeet V3 model folders in the app bundle.
- This enables model switching in Settings without installing a separate build.
- Download size is larger than the single-model variants.

## Requirements
- macOS 14+
- Apple Silicon (M-series)
