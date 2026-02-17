# NoteScribe build/sign/notarize commands

## Overview
The unified build script handles everything: build, sign, notarize, staple, and validate.

## Prereqs (one-time)
```bash
# Store notarization credentials in Keychain
xcrun notarytool store-credentials notescribe-notary \
  --apple-id "YOUR_APPLE_ID" \
  --team-id "YOUR_TEAM_ID" \
  --password
```

## Environment Setup (per shell session)
```bash
export SIGNING_IDENTITY="Developer ID Application: Your Name (TEAMID)"
export NOTARY_PROFILE="your-notary-profile"
```

---

## Command Variants

### Unsigned Build (for local testing)
```bash
# v2 - English only
./build_notescribe.sh --model v2

# v3 - Multilingual
./build_notescribe.sh --model v3
```
**Does:** Build only (no signing, no DMG, no notarization)

---

### Signed Build (creates DMG, no notarization)
```bash
# v2
SIGNING_IDENTITY="$SIGNING_IDENTITY" ./build_notescribe.sh --model v2 --signed

# v3
SIGNING_IDENTITY="$SIGNING_IDENTITY" ./build_notescribe.sh --model v3 --signed
```
**Does:** Build → Sign → Create DMG

---

### Full Pipeline (build + sign + notarize + staple + validate)
```bash
# v2 - Full pipeline
SIGNING_IDENTITY="$SIGNING_IDENTITY" NOTARY_PROFILE="$NOTARY_PROFILE" NOTARIZE=1 \
  ./build_notescribe.sh --model v2 --signed

# v3 - Full pipeline
SIGNING_IDENTITY="$SIGNING_IDENTITY" NOTARY_PROFILE="$NOTARY_PROFILE" NOTARIZE=1 \
  ./build_notescribe.sh --model v3 --signed
```
**Does:** Build → Sign → Create DMG → Upload to Apple → Wait → Staple → Validate

---

## Quick Reference Table

| Command | Build | Sign | DMG | Notarize | Staple | Validate |
|---------|-------|------|-----|----------|--------|----------|
| `--model v3` | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `--model v3 --signed` | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| `--model v3 --signed` + `NOTARIZE=1` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

---

## Output Locations
- v2 app: `/Users/swaylen/dev/NoteScribe/_releases/NoteScribe-v2/NoteScribe.app`
- v2 DMG: `/Users/swaylen/dev/NoteScribe/_releases/NoteScribe-v2.dmg`
- v3 app: `/Users/swaylen/dev/NoteScribe/_releases/NoteScribe-v3/NoteScribe.app`
- v3 DMG: `/Users/swaylen/dev/NoteScribe/_releases/NoteScribe-v3.dmg`

---

## Manual Staple/Validate (if needed separately)
```bash
# Staple
xcrun stapler staple "/Users/swaylen/dev/NoteScribe/_releases/NoteScribe-v2.dmg"
xcrun stapler staple "/Users/swaylen/dev/NoteScribe/_releases/NoteScribe-v3.dmg"

# Validate
xcrun stapler validate "/Users/swaylen/dev/NoteScribe/_releases/NoteScribe-v2.dmg"
xcrun stapler validate "/Users/swaylen/dev/NoteScribe/_releases/NoteScribe-v3.dmg"
```

---

## Install from DMG
1. Open the DMG
2. Drag `NoteScribe.app` into `/Applications`
3. Eject the DMG

### Fresh Install (clean slate)
```bash
# Run uninstall script first
/Users/swaylen/dev/NoteScribe/uninstall_notescribe.sh
```

---

## Models Directory
External models stored in `models/` (NOT in git):
```
models/
├── parakeet-v2/parakeet-tdt-0.6b-v2-coreml/   # ~443MB - English only
├── parakeet-v3/parakeet-tdt-0.6b-v3-coreml/   # ~461MB - Multilingual
└── vad/silero-vad-coreml/                      # ~1MB - Voice Activity Detection
```

---

## Script Location
```
/Users/swaylen/dev/NoteScribe/build_notescribe.sh
```

## Archived Scripts
Old v2/v3 specific scripts (no longer needed):
- `archive/build_notescribe_v2.sh.archived`
- `archive/build_notescribe_v3.sh.archived`

---

## Release Packaging Notes (Feb 2026)

### FluidAudio Qwen3 compile fix (Xcode + script builds)
Both Xcode projects now pin FluidAudio to revision:
`99220bc49f085235998b9937172618399deb4412`

This revision already contains the Qwen3 arm64 guard in:
`Sources/FluidAudio/ASR/Qwen3/Qwen3AsrModels.swift`

What this does:
- Wraps the `Float16` embedding decode path in `#if arch(arm64)`.
- Adds a non-arm64 fallback (`fatalError`) so x86_64 compile no longer fails with ambiguous type inference.
- Fixes the direct Xcode Release build path (not just scripted packaging).

Related build behavior:
- `build_notescribe.sh` still includes an idempotent compatibility patch as a safety net.
- Build uses `-disableAutomaticPackageResolution` in script mode to avoid package churn during release packaging.

### Current release-package status
- `./build_notescribe.sh --model v3 --unsigned` now succeeds end-to-end.
- Export path confirmed: `/Users/swaylen/dev/NoteScribe/_releases/NoteScribe-v3/NoteScribe.app`
- Direct `xcodebuild` Release builds now pass for both:
  - `/Users/swaylen/dev/NoteScribe/base/NoteScribe.xcodeproj`
  - `/Users/swaylen/dev/NoteScribe/NoteScribe.xcodeproj`

### Direct Xcode Build Notes
- Placeholder bundle paths are now kept in repo:
  - `NoteScribe/Resources/BundledModels/Parakeet/`
  - `NoteScribe/Resources/BundledModels/VAD/silero-vad-coreml/`
- This allows compile/link even when full models are not copied.
- Runtime transcription still requires real models from `models/`.

### Direct Xcode Run (Debug) model loading
- App now falls back to repo models in local Debug runs when bundled resources are placeholders.
- Optional explicit override in Xcode Scheme environment:
  - `NOTESCRIBE_MODELS_DIR=/Users/swaylen/dev/NoteScribe/models`
- If transcription still says model not loaded:
  1. `Product -> Clean Build Folder`
  2. In Xcode: `Product -> Scheme -> Edit Scheme... -> Run -> Build Configuration = Debug`
     (preferred for local iteration)
  3. In the same Run settings, confirm env var:
     `NOTESCRIBE_MODELS_DIR=/Users/swaylen/dev/NoteScribe/models`
  4. Quit app
  5. Remove cache: `~/Library/Application Support/FluidAudio/Models`
  6. Remove old container cache if present:
     `~/Library/Containers/com.swaylenhayes.apps.notescribe/Data/Library/Application Support/FluidAudio/Models`
  7. Run again

### Permission error: `"parakeet-tdt-0.6b-v3-coreml" couldn't be copied ... access "Models"`
This usually indicates stale cache paths or an older sandboxed build still being launched.

Use this fix for local development:
1. `Product -> Scheme -> Edit Scheme...`
2. Select `Run`
3. Set `Build Configuration` to `Debug`
4. Add/verify env var `NOTESCRIBE_MODELS_DIR=/Users/swaylen/dev/NoteScribe/models`
5. Clean build folder, clear cache, relaunch

Note:
- App Sandbox is now disabled for both `Debug` and `Release` in this repo to avoid model path access failures during local/package testing.
- Use `Debug` for local Xcode transcription testing from external `models/`.

### Resume Checklist (after break)
```bash
# 1) Restore signing env for this shell
export SIGNING_IDENTITY="Developer ID Application: Your Name (TEAMID)"
export NOTARY_PROFILE="notescribe-notary"

# 2) Signed release package build
./build_notescribe.sh --model v3 --signed

# 3) Optional notarization pipeline
NOTARIZE=1 ./build_notescribe.sh --model v3 --signed
```

### Release Publish Checklist
```bash
# 0) Ensure local git is clean and pushed
git status
git push origin main

# 1) Build/sign/notarize/staple/validate both release variants
SIGNING_IDENTITY="$SIGNING_IDENTITY" NOTARY_PROFILE="$NOTARY_PROFILE" NOTARIZE=1 \
  ./build_notescribe.sh --model v2 --signed

SIGNING_IDENTITY="$SIGNING_IDENTITY" NOTARY_PROFILE="$NOTARY_PROFILE" NOTARIZE=1 \
  ./build_notescribe.sh --model v3 --signed

# 2) Gatekeeper checks on final DMGs
spctl -a -vv -t open "/Users/swaylen/dev/NoteScribe/_releases/NoteScribe-v2.dmg"
spctl -a -vv -t open "/Users/swaylen/dev/NoteScribe/_releases/NoteScribe-v3.dmg"
```

### Verified on Feb 16, 2026
All of the following completed successfully on local machine:
```bash
./build_notescribe.sh --model v3 --unsigned

SIGNING_IDENTITY="Developer ID Application: Shane Wasley (LVKMA4S3V6)" \
  ./build_notescribe.sh --model v3 --signed

SIGNING_IDENTITY="Developer ID Application: Shane Wasley (LVKMA4S3V6)" \
NOTARY_PROFILE="notescribe-notary" NOTARIZE=1 \
  ./build_notescribe.sh --model v3 --signed
```

DMG signing behavior:
- `build_notescribe.sh` now signs the DMG container before notarization (`codesign --timestamp --sign "$SIGNING_IDENTITY" "$DMG_PATH"`).
- This ensures `spctl` accepts the DMG itself as `Notarized Developer ID` (not just the app inside).
