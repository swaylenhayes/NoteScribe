#!/usr/bin/env bash
set -u
set -o pipefail

APP_NAME="NoteScribe"
APP_PATH="/Applications/${APP_NAME}.app"
BUNDLE_ID="${BUNDLE_ID_OVERRIDE:-}"
REMOVE_USER_DATA=0

usage() {
  cat <<EOF
Usage: $(basename "$0") [--remove-user-data]

Removes the installed app, resets TCC permissions, and clears app-local state.
By default, transcripts, recordings, and other user-created data are preserved.

Options:
  --remove-user-data   Also remove Application Support and container data.
  -h, --help           Show this help message.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --remove-user-data)
      REMOVE_USER_DATA=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

if [[ -z "$BUNDLE_ID" && -f "$APP_PATH/Contents/Info.plist" ]]; then
  BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP_PATH/Contents/Info.plist" 2>/dev/null || true)"
fi

if [[ -z "$BUNDLE_ID" ]]; then
  echo "Could not determine bundle identifier from ${APP_PATH}." >&2
  echo "Set BUNDLE_ID_OVERRIDE and rerun if the app bundle has already been removed." >&2
  exit 1
fi

CONTAINER_PATH="$HOME/Library/Containers/${BUNDLE_ID}"
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

if [[ "$REMOVE_USER_DATA" -eq 1 ]]; then
  echo "Removing app, local state, and user data..."
else
  echo "Removing app and local state while preserving user data..."
fi

remove_path "$APP_PATH"
remove_path "$HOME/Library/Preferences/${BUNDLE_ID}.plist"
remove_path "$HOME/Library/Caches/${BUNDLE_ID}"
remove_path "$HOME/Library/Saved Application State/${BUNDLE_ID}.savedState"

if [[ "$REMOVE_USER_DATA" -eq 1 ]]; then
  remove_path "$CONTAINER_PATH"
  remove_path "$APP_SUPPORT_PATH"
else
  echo "Preserved user data locations:"
  echo "  $APP_SUPPORT_PATH"
  if [[ -e "$CONTAINER_SUPPORT_PATH" ]]; then
    echo "  $CONTAINER_SUPPORT_PATH"
  fi
fi

echo "Resetting permissions..."
tccutil reset Microphone "${BUNDLE_ID}" || true
tccutil reset Accessibility "${BUNDLE_ID}" || true

echo "Done."
