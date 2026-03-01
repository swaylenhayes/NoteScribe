# Roadmap

Last updated: Mar 1, 2026

## Completed in current cycle
- Tab/workspace restructure:
  - `Scratch Pad`, `Transcription`, `Replacements`, `Settings`
  - merged file transcription + history into one Transcription workspace
- Header system unification via shared section header layout.
- Window sizing polish (minimum width set to `650`, default opens compact and resizable).
- Dark mode readability and contrast polish across scratch pad, transcription list/search, replacements, and settings controls.
- V2/V3 model switching UI in Settings with in-session warmup behavior.
- Recording indicator floating pill for visual recording state feedback.
  - Consolidates no-audio and escape-cancel notifications into one top-center status zone.
- Release build pipeline hardening:
  - signing, notarization, stapling, validation
  - DMG container signing before notarization
  - FluidAudio universal compile compatibility patch path

## Pending verification
- Recording indicator manual hardware check on a real microphone/display setup. See `docs/plans/2026-03-01-recording-indicator-implementation-v2.md`.

## Near-term remaining
- **Multi-monitor recording indicator**: follow-active-screen for the recording pill if primary-only proves insufficient.
- **Custom start/stop sounds**: explore different audio cues for recording state changes.
- **Filler word module**: configurable filler-word cleanup in transcription pipeline.
- **Recording pause/resume**: safe segmented recording flow to avoid data loss.
- **Playback streaming**: stream long files during playback to reduce memory spikes.
- **Release QA checklist**: formal smoke checklist for v2 and v3 DMGs prior to publishing.

## Mid-term
- **Scratch pad workflow polish**: faster capture/edit flow for rapid notes.
- **Large-history UX**: improve navigation and filtering performance for high-volume history.
- **Settings clarity pass**: simplify copy and control grouping without regressing macOS-native feel.
- **Always-listening mode**: dead man's trigger with mute punctuation (exploratory).

## Long-term / ideas
- **Filler profiles**: shareable cleanup profiles/templates.
- **Text normalization upgrades**: punctuation and formatting refinements.
- **Performance baseline suite**: repeatable profiling benchmark for each release candidate.
