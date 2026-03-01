#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DMG_PATH="$SCRIPT_DIR/_releases/NoteScribe-v3.dmg"

xcrun stapler staple "$DMG_PATH"
xcrun stapler validate "$DMG_PATH"

echo "Staple + validate complete: $DMG_PATH"
echo "DMG folder: $(dirname "$DMG_PATH")"
