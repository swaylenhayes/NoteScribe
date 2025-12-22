#!/usr/bin/env bash
set -u
set -o pipefail

APP_NAME="NoteScribe"
BUNDLE_ID="com.swaylenhayes.apps.notescribe"
APP_PATH="/Applications/${APP_NAME}.app"
TIMESTAMP="$(date +"%Y%m%d-%H%M%S")"
BACKUP_DIR="$HOME/Desktop/${APP_NAME}-backup-${TIMESTAMP}"
CONTAINER_SUPPORT_PATH="$HOME/Library/Containers/${BUNDLE_ID}/Data/Library/Application Support/${BUNDLE_ID}"
APP_SUPPORT_PATH="$HOME/Library/Application Support/${BUNDLE_ID}"

echo "Stopping ${APP_NAME}..."
pkill -x "${APP_NAME}" >/dev/null 2>&1 || true

remove_path() {
  local path="$1"
  if [[ -e "$path" ]]; then
    if rm -rf "$path"; then
      echo "Removed: $path"
    else
      echo "Failed to remove: $path (try: sudo rm -rf \"$path\")" >&2
    fi
  else
    echo "Not found: $path"
  fi
}

echo "Saving transcripts and recordings..."
mkdir -p "$BACKUP_DIR"

backup_dir() {
  local src="$1"
  local label="$2"
  if [[ -d "$src" ]]; then
    local dest="$BACKUP_DIR/$label"
    if mv "$src" "$dest" 2>/dev/null; then
      echo "Moved to: $dest"
    else
      if cp -R "$src" "$dest"; then
        echo "Copied to: $dest"
      else
        echo "Failed to back up: $src" >&2
      fi
    fi
  else
    echo "Not found: $src"
  fi
}

backup_dir "$CONTAINER_SUPPORT_PATH" "Application Support (Container)"
backup_dir "$APP_SUPPORT_PATH" "Application Support"

echo "Removing app and local data..."
remove_path "$APP_PATH"
remove_path "$HOME/Library/Containers/${BUNDLE_ID}"
remove_path "$HOME/Library/Preferences/${BUNDLE_ID}.plist"
remove_path "$HOME/Library/Caches/${BUNDLE_ID}"
remove_path "$HOME/Library/Saved Application State/${BUNDLE_ID}.savedState"

echo "Resetting permissions..."
tccutil reset Microphone "${BUNDLE_ID}" || true
tccutil reset Accessibility "${BUNDLE_ID}" || true

echo "Done."
