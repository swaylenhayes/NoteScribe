# NoteScribe v1.3.3 Release Notes

**Release Date:** February 18, 2026

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

## Requirements
- macOS 14+
- Apple Silicon (M-series)
