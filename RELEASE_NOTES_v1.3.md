# NoteScribe v1.3 Release Notes

**Release Date:** December 2025

## What's New

### Reliable First Transcription
The first hotkey recording now waits for the audio file to fully finalize before transcription starts. This avoids the "first run failed" case where the transcript appeared in history but did not paste.

### Loading Indicator
The startup overlay now reads "Loading Local Model" and indicates when NoteScribe is ready to transcribe.

### Unified Build System
Internal improvement: Consolidated from multiple source trees to a single codebase with external model injection at build time. This makes maintenance easier and ensures both v2 (English) and v3 (Multilingual) builds stay in sync.

## Downloads

- **NoteScribe-v2.dmg** - English transcription only (~443MB model)
- **NoteScribe-v3.dmg** - Multilingual transcription (English + 25 European languages, ~461MB model)

## Installation

1. Download the appropriate DMG for your needs
2. Open the DMG
3. Drag NoteScribe to your Applications folder
4. Launch NoteScribe
5. Wait for the "Loading Local Model" overlay to disappear
6. Start transcribing with your configured hotkeys!

## Technical Details

- macOS 14.0+ required
- Apple Silicon optimized (M1/M2/M3)
- All transcription runs 100% offline - no data leaves your Mac
- Signed and notarized by Apple

## Changes Since v1.1

### Reliability Improvements
- Wait for recording file finalization before transcription
- More resilient offline audio processing during transcription

### Internal Improvements
- Single source tree architecture (`base/`)
- Unified build script with `--model v2|v3` parameter
- Models stored externally and injected at build time

---

*NoteScribe is a privacy-first transcription app. All processing happens locally on your Mac.*
