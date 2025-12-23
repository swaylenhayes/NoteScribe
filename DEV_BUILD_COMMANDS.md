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
