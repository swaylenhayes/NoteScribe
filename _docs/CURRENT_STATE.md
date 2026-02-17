# Current State (Bookmark)

Last updated: Feb 17, 2026

## Current snapshot
- FluidAudio is pinned to revision `99220bc49f085235998b9937172618399deb4412` and release/universal builds now compile cleanly.
- Model loading is fully migrated to `ModelBundleManager` and is idempotent.
- Accessibility permission loop issues are fixed (`CursorPaster` prompt cooldown + one-time session request path).
- Debug run path is stable end-to-end: record -> transcribe -> paste.
- Shared schemes use `Debug` for local runs and set `NOTESCRIBE_MODELS_DIR=/Users/swaylen/dev/NoteScribe/models`.
- App Sandbox is disabled for local Debug/Release builds in this repo to prevent external model copy failures.

## UI state (latest polish pass)
- Top tab bar now uses: `Scratch Pad`, `Transcription`, `Replacements`, `Settings`.
- File transcription and history are merged in `Transcription`:
  - Header row contains drag/drop guidance and `Choose File`.
  - Drop target supports dropping anywhere in the Transcription view.
  - Search appears above history entries.
- Transcription cards now expose visible text and include both `Copy` and `Save`.
- Section headers are normalized across views via shared `AppSectionHeader`.
- Main window minimum width is `650` (resizable wider).
- Light and dark mode both have dedicated styling paths; dark mode contrast and readability issues are resolved.

## Model switching behavior (V2/V3)
- Switching models does not unload the previously loaded model manager.
- `ParakeetTranscriptionService` keeps `AsrManager` instances in-memory per version (`v2`, `v3`) for the app session.
- Startup warmup preloads the selected model, and alternative warmup can preload the other model to make switching near-instant.

## Release packaging status
- `build_notescribe.sh` supports full pipeline: build -> sign -> DMG -> notarize -> staple -> validate.
- DMG container signing is enabled before notarization.
- Prior verified pipeline status:
  - `./build_notescribe.sh --model v3 --unsigned` succeeds.
  - `./build_notescribe.sh --model v3 --signed` succeeds.
  - `NOTARIZE=1 ./build_notescribe.sh --model v3 --signed` succeeds with Apple notarization acceptance.

## Resume commands
```bash
# Signed + notarized v3 release
export SIGNING_IDENTITY="Developer ID Application: Your Name (TEAMID)"
export NOTARY_PROFILE="notescribe-notary"
NOTARIZE=1 ./build_notescribe.sh --model v3 --signed

# Signed + notarized v2 release
NOTARIZE=1 ./build_notescribe.sh --model v2 --signed
```

## Local run troubleshooting
- If you see:
  `"parakeet-tdt-0.6b-v3-coreml" couldn't be copied because you don't have permission to access "Models"`
- Typical cause: stale FluidAudio cache path or launching an older app/container build.
- Fix:
  1. `Product -> Clean Build Folder`
  2. Ensure scheme `Run` is `Debug`
  3. Ensure env var: `NOTESCRIBE_MODELS_DIR=/Users/swaylen/dev/NoteScribe/models`
  4. Quit app
  5. Clear caches:
     - `~/Library/Application Support/FluidAudio/Models`
     - `~/Library/Containers/com.swaylenhayes.apps.notescribe/Data/Library/Application Support/FluidAudio/Models`
