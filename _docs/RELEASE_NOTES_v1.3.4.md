# NoteScribe v1.3.4 Release Notes

**Release Date:** March 1, 2026

## Highlights
- Added a floating recording indicator with a live timer so it is easier to see when NoteScribe is actively listening.
- Recording feedback now stays in one place, including no-audio warnings and Escape-to-cancel status.
- Simplified packaged downloads to the two builds that matter now: `v3` and combined `v2v3`.

## Improvements
- The recording indicator has been tuned for better visibility on busy screens and dark mode.
- The app now defaults into the transcription workflow more directly with the scratchpad removed from the main surface.
- Release packaging now builds from the active root app project instead of the stale alternate tree.

## Fixes
- Fixed a crash that could happen when model prewarming and live transcription tried to initialize the same Parakeet model at the same time.
- Hardened model and VAD initialization so repeated recordings are more stable.
- Fixed the Escape pending-cancel pill so it re-centers instead of expanding awkwardly to one side.

## Build & Release
- Signed, notarized, stapled, and validated DMG artifacts are provided for:
  - `NoteScribe-v3.dmg`
  - `NoteScribe-v2v3.dmg`

## Requirements
- macOS 14+
- Apple Silicon (M-series)
