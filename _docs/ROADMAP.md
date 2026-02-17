# Roadmap

Last updated: Feb 17, 2026

## Completed in current cycle
- Tab/workspace restructure:
  - `Scratch Pad`, `Transcription`, `Replacements`, `Settings`
  - merged file transcription + history into one Transcription workspace
- Header system unification via shared section header layout.
- Window sizing polish (minimum width set to `650`, default opens compact and resizable).
- Dark mode readability and contrast polish across scratch pad, transcription list/search, replacements, and settings controls.
- V2/V3 model switching UI in Settings with in-session warmup behavior.
- Release build pipeline hardening:
  - signing, notarization, stapling, validation
  - DMG container signing before notarization
  - FluidAudio universal compile compatibility patch path

## Near-term remaining
- **Filler word module**: configurable filler-word cleanup in transcription pipeline.
- **Recording pause/resume**: safe segmented recording flow to avoid data loss.
- **Playback streaming**: stream long files during playback to reduce memory spikes.
- **Release QA checklist**: formal smoke checklist for v2 and v3 DMGs prior to publishing.

## Mid-term
- **Scratch pad workflow polish**: faster capture/edit flow for rapid notes.
- **Large-history UX**: improve navigation and filtering performance for high-volume history.
- **Settings clarity pass**: simplify copy and control grouping without regressing macOS-native feel.

## Long-term / ideas
- **Filler profiles**: shareable cleanup profiles/templates.
- **Text normalization upgrades**: punctuation and formatting refinements.
- **Performance baseline suite**: repeatable profiling benchmark for each release candidate.
