#!/usr/bin/env bash
set -euo pipefail

DMG_PATH="/Users/swaylen/dev/NoteScribe/_releases/NoteScribe-v3.dmg"

xcrun stapler staple "$DMG_PATH"
xcrun stapler validate "$DMG_PATH"

echo "Staple + validate complete: $DMG_PATH"
echo "DMG folder: $(dirname "$DMG_PATH")"
