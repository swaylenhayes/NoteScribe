# NoteScribe (fork of LowKeet)

Minimal macOS transcription app using Parakeet V3 only. This directory is a clean fork of LowKeet, trimmed to the NoteScribe feature set and rebranded so it can live in its own repository.

## Build
- Open `NoteScribe/NoteScribe.xcodeproj`.
- Select the `NoteScribe` scheme/target and build/run on macOS 14+.
- The app stores data under `~/Library/Application Support/com.swaylenhayes.apps.notescribe`.

## Differences vs. LowKeet
- Only Parakeet V3 transcription (no Whisper, no legacy local-model UI).
- Tabbed navigation with a scratchpad home, file transcription, history, replacements, and settings.
- Menu bar–only experience; enhancement/online features removed.
- Branding, bundle ID, and update feed changed to NoteScribe.

## Next steps for release
- Point `SUFeedURL` in `NoteScribe/Info.plist` to your final appcast.
- Update signing team/profiles as needed.
- Initialize a new git repo from this `NoteScribe` directory before publishing.
