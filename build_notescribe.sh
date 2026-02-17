#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# NoteScribe Unified Build Script
# ============================================================================
# Builds NoteScribe with specified model version (v2 or v3)
# Usage: ./build_notescribe.sh --model v2|v3 [--signed|--unsigned]
#
# Environment variables:
#   SIGNING_IDENTITY - Required for --signed (e.g., "Developer ID Application: ...")
#   NOTARY_PROFILE   - Keychain profile for notarization (optional)
#   NOTARIZE         - Set to 1 to enable notarization (requires --signed)
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/base"
MODELS_DIR="$SCRIPT_DIR/models"
SCHEME="NoteScribe"
CONFIG="Release"
RELEASES_DIR="$SCRIPT_DIR/_releases"

# Model paths in source code
BUNDLED_MODELS_DIR="$ROOT_DIR/NoteScribe/Resources/BundledModels"
PARAKEET_DIR="$BUNDLED_MODELS_DIR/Parakeet"
VAD_DIR="$BUNDLED_MODELS_DIR/VAD"

# Parse arguments
MODEL_VERSION=""
SIGNED=0

print_usage() {
    echo "Usage: $0 --model v2|v3 [--signed|--unsigned]"
    echo ""
    echo "Options:"
    echo "  --model v2|v3    Select model version (required)"
    echo "  --signed         Sign and create DMG (requires SIGNING_IDENTITY)"
    echo "  --unsigned       Build without signing (default)"
    echo ""
    echo "Environment variables:"
    echo "  SIGNING_IDENTITY  Developer ID for signing (required for --signed)"
    echo "  NOTARY_PROFILE    Keychain profile for notarization"
    echo "  NOTARIZE=1        Enable notarization after signing"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --model)
            shift
            if [[ $# -eq 0 ]]; then
                echo "Error: --model requires an argument (v2 or v3)" >&2
                exit 1
            fi
            MODEL_VERSION="$1"
            ;;
        --signed)
            SIGNED=1
            ;;
        --unsigned)
            SIGNED=0
            ;;
        --help|-h)
            print_usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            print_usage
            exit 1
            ;;
    esac
    shift
done

# Validate model version
if [[ -z "$MODEL_VERSION" ]]; then
    echo "Error: --model is required" >&2
    print_usage
    exit 1
fi

if [[ "$MODEL_VERSION" != "v2" && "$MODEL_VERSION" != "v3" ]]; then
    echo "Error: --model must be 'v2' or 'v3'" >&2
    exit 1
fi

# Set paths based on model version
MODEL_NAME="parakeet-tdt-0.6b-${MODEL_VERSION}-coreml"
MODEL_SOURCE_DIR="$MODELS_DIR/parakeet-${MODEL_VERSION}/$MODEL_NAME"
VAD_SOURCE_DIR="$MODELS_DIR/vad/silero-vad-coreml"

EXPORT_PATH="$RELEASES_DIR/NoteScribe-${MODEL_VERSION}"
DMG_PATH="$RELEASES_DIR/NoteScribe-${MODEL_VERSION}.dmg"
ENTITLEMENTS_PATH="$ROOT_DIR/NoteScribe/NoteScribe.entitlements.release.plist"

# Validate model exists
if [[ ! -d "$MODEL_SOURCE_DIR" ]]; then
    echo "Error: Model not found at: $MODEL_SOURCE_DIR" >&2
    echo "Please ensure the models directory is set up correctly." >&2
    exit 1
fi

if [[ ! -d "$VAD_SOURCE_DIR" ]]; then
    echo "Error: VAD model not found at: $VAD_SOURCE_DIR" >&2
    exit 1
fi

echo "============================================"
echo "NoteScribe Build - Model: $MODEL_VERSION"
echo "============================================"
echo "Model source: $MODEL_SOURCE_DIR"
echo "Output: $EXPORT_PATH"
echo ""

mkdir -p "$RELEASES_DIR"

# ============================================================================
# Model Copy Functions
# ============================================================================

copy_models() {
    echo "Copying models to build location..."

    # Clear existing Parakeet models (keep directory structure)
    echo "  Clearing existing Parakeet models..."
    rm -rf "$PARAKEET_DIR"/*

    # Copy selected Parakeet model
    echo "  Copying $MODEL_NAME..."
    cp -R "$MODEL_SOURCE_DIR" "$PARAKEET_DIR/"

    # Copy VAD model (clear and recopy to ensure completeness)
    echo "  Copying VAD model..."
    rm -rf "$VAD_DIR"/*
    cp -R "$VAD_SOURCE_DIR" "$VAD_DIR/"

    echo "Models copied successfully."
}

cleanup_models() {
    echo "Cleaning up models from source tree..."

    # Remove full models, restore to metadata-only state
    # Keep the directory structure but remove .mlmodelc folders

    # For Parakeet - remove everything
    rm -rf "$PARAKEET_DIR"/*

    # For VAD - remove everything
    rm -rf "$VAD_DIR"/*

    # Restore placeholder directories so direct Xcode builds still resolve folder refs.
    mkdir -p "$PARAKEET_DIR" "$VAD_DIR/silero-vad-coreml"
    touch "$BUNDLED_MODELS_DIR/.gitkeep"
    touch "$PARAKEET_DIR/.gitkeep"
    touch "$VAD_DIR/.gitkeep"
    touch "$VAD_DIR/silero-vad-coreml/.gitkeep"

    echo "Cleanup complete - source tree restored to clean state."
}

# ============================================================================
# Signing Functions
# ============================================================================

sign_item() {
    local target="$1"
    codesign --force --options runtime --timestamp --sign "$SIGNING_IDENTITY" "$target"
}

sign_app() {
    local target="$1"
    if [[ -f "$ENTITLEMENTS_PATH" ]]; then
        codesign --force --options runtime --timestamp --entitlements "$ENTITLEMENTS_PATH" --sign "$SIGNING_IDENTITY" "$target"
    else
        codesign --force --options runtime --timestamp --sign "$SIGNING_IDENTITY" "$target"
    fi
}

sign_dmg() {
    local target="$1"
    # DMG containers should be signed as a distribution artifact before notarization.
    codesign --force --timestamp --sign "$SIGNING_IDENTITY" "$target"
}

sign_embedded() {
    local app_path="$1"
    local frameworks_dir="$app_path/Contents/Frameworks"

    if [[ -d "$frameworks_dir" ]]; then
        while IFS= read -r item; do
            sign_item "$item"
        done < <(find "$frameworks_dir" -type d -name "*.framework" -prune)

        while IFS= read -r item; do
            sign_item "$item"
        done < <(find "$frameworks_dir" -type f \( -name "*.dylib" -o -name "*.so" \))
    fi

    for dir in "$app_path/Contents/PlugIns" "$app_path/Contents/Library/LoginItems"; do
        if [[ -d "$dir" ]]; then
            while IFS= read -r item; do
                sign_item "$item"
            done < <(find "$dir" -type d \( -name "*.app" -o -name "*.xpc" -o -name "*.appex" \) -prune)
        fi
    done
}

# ============================================================================
# Package Compatibility Patch
# ============================================================================

resolve_derived_data_dir() {
    local build_settings build_dir

    build_settings=$(xcodebuild \
        -project "$ROOT_DIR/NoteScribe.xcodeproj" \
        -scheme "$SCHEME" \
        -configuration "$CONFIG" \
        -showBuildSettings)

    build_dir=$(echo "$build_settings" | awk -F ' = ' '/ BUILD_DIR = / {print $2; exit}')
    if [[ -z "$build_dir" ]]; then
        echo ""
        return
    fi

    echo "${build_dir%/Build/Products}"
}

patch_fluidaudio_qwen3_for_universal_build() {
    local derived_data_dir qwen3_file

    derived_data_dir="$(resolve_derived_data_dir)"
    if [[ -z "$derived_data_dir" ]]; then
        echo "Warning: Could not determine DerivedData path; skipping FluidAudio compatibility patch."
        return
    fi

    qwen3_file="$derived_data_dir/SourcePackages/checkouts/FluidAudio/Sources/FluidAudio/ASR/Qwen3/Qwen3AsrModels.swift"

    if [[ ! -f "$qwen3_file" ]]; then
        echo "Resolving packages before compatibility patch..."
        xcodebuild \
            -project "$ROOT_DIR/NoteScribe.xcodeproj" \
            -scheme "$SCHEME" \
            -configuration "$CONFIG" \
            -resolvePackageDependencies >/dev/null
    fi

    if [[ ! -f "$qwen3_file" ]]; then
        echo "Warning: FluidAudio Qwen3 source file not found; skipping compatibility patch."
        return
    fi

    if grep -q '#if arch(arm64)' "$qwen3_file"; then
        echo "FluidAudio universal compatibility patch already present."
        return
    fi

    if ! grep -q 'data.withUnsafeBytes { ptr in' "$qwen3_file"; then
        echo "Warning: Unexpected FluidAudio source format; skipping compatibility patch."
        return
    fi

    perl -0777 -i'' -pe 's@        data.withUnsafeBytes \{ ptr in\n            let f16Ptr = ptr.baseAddress!\.advanced\(by: offset\)\n                \.assumingMemoryBound\(to: Float16\.self\)\n\n            for i in 0\.\.<hiddenSize \{\n                result\[i\] = Float\(f16Ptr\[i\]\)\n            \}\n        \}@        #if arch(arm64)\n        data.withUnsafeBytes { ptr in\n            let f16Ptr = ptr.baseAddress!.advanced(by: offset)\n                .assumingMemoryBound(to: Float16.self)\n\n            for i in 0..<hiddenSize {\n                result[i] = Float(f16Ptr[i])\n            }\n        }\n        #else\n        // Float16 embedding decode requires Apple Silicon.\n        fatalError(\"Qwen3-ASR requires Apple Silicon (arm64)\")\n        #endif@g' "$qwen3_file"

    if grep -q '#if arch(arm64)' "$qwen3_file"; then
        echo "Applied FluidAudio universal compatibility patch."
    else
        echo "Error: Failed to apply FluidAudio universal compatibility patch." >&2
        exit 1
    fi
}

# ============================================================================
# Build Function
# ============================================================================

build_app() {
    local signed_flag="$1"

    # Copy models before build
    copy_models

    # Set up trap to cleanup on exit (success or failure)
    trap cleanup_models EXIT

    # Apply fallback compatibility patch for FluidAudio universal compilation.
    patch_fluidaudio_qwen3_for_universal_build

    if [[ "$signed_flag" -eq 1 ]]; then
        if [[ -z "${SIGNING_IDENTITY:-}" ]]; then
            echo "Error: SIGNING_IDENTITY is required for --signed." >&2
            exit 1
        fi
        echo "Building app (unsigned) for manual signing..."
        xcodebuild \
            -project "$ROOT_DIR/NoteScribe.xcodeproj" \
            -scheme "$SCHEME" \
            -configuration "$CONFIG" \
            -disableAutomaticPackageResolution \
            CODE_SIGNING_ALLOWED=NO \
            CODE_SIGNING_REQUIRED=NO \
            build
    else
        echo "Building unsigned app..."
        xcodebuild \
            -project "$ROOT_DIR/NoteScribe.xcodeproj" \
            -scheme "$SCHEME" \
            -configuration "$CONFIG" \
            -disableAutomaticPackageResolution \
            CODE_SIGNING_ALLOWED=NO \
            CODE_SIGNING_REQUIRED=NO \
            build
    fi

    # Get build output location
    BUILD_SETTINGS=$(xcodebuild \
        -project "$ROOT_DIR/NoteScribe.xcodeproj" \
        -scheme "$SCHEME" \
        -configuration "$CONFIG" \
        -showBuildSettings)

    TARGET_BUILD_DIR=$(echo "$BUILD_SETTINGS" | awk -F ' = ' '/TARGET_BUILD_DIR/ {print $2; exit}')
    WRAPPER_NAME=$(echo "$BUILD_SETTINGS" | awk -F ' = ' '/WRAPPER_NAME/ {print $2; exit}')

    if [[ -z "$TARGET_BUILD_DIR" || -z "$WRAPPER_NAME" ]]; then
        echo "Error: Failed to locate built app from build settings." >&2
        exit 1
    fi

    APP_PATH="$TARGET_BUILD_DIR/$WRAPPER_NAME"
    if [[ ! -d "$APP_PATH" ]]; then
        echo "Error: Built app not found at: $APP_PATH" >&2
        exit 1
    fi

    # Copy to release location
    rm -rf "$EXPORT_PATH"
    mkdir -p "$EXPORT_PATH"
    cp -R "$APP_PATH" "$EXPORT_PATH/"

    APP_OUT_PATH="$EXPORT_PATH/$WRAPPER_NAME"
    echo "Copied app to: $APP_OUT_PATH"

    if [[ "$signed_flag" -eq 1 ]]; then
        echo "Signing embedded frameworks and helpers..."
        sign_embedded "$APP_OUT_PATH"

        echo "Signing app..."
        sign_app "$APP_OUT_PATH"

        echo "Creating DMG..."
        rm -f "$DMG_PATH"
        DMG_SOURCE_DIR=$(mktemp -d)
        cp -R "$APP_OUT_PATH" "$DMG_SOURCE_DIR/"

        UNINSTALL_SCRIPT_SOURCE="$SCRIPT_DIR/uninstall_notescribe.sh"
        if [[ -f "$UNINSTALL_SCRIPT_SOURCE" ]]; then
            cp "$UNINSTALL_SCRIPT_SOURCE" "$DMG_SOURCE_DIR/Uninstall-NoteScribe.sh"
            chmod +x "$DMG_SOURCE_DIR/Uninstall-NoteScribe.sh"
        fi

        ln -s /Applications "$DMG_SOURCE_DIR/Applications"
        hdiutil create -volname NoteScribe \
            -srcfolder "$DMG_SOURCE_DIR" \
            -ov -format UDZO "$DMG_PATH"
        rm -rf "$DMG_SOURCE_DIR"
        echo "DMG created at: $DMG_PATH"

        echo "Signing DMG..."
        sign_dmg "$DMG_PATH"

        echo "Verifying DMG signature..."
        codesign --verify --verbose=2 "$DMG_PATH"

        if [[ "${NOTARIZE:-0}" -eq 1 ]]; then
            echo "Submitting DMG for notarization..."
            if [[ -n "${NOTARY_PROFILE:-}" ]]; then
                xcrun notarytool submit "$DMG_PATH" \
                    --keychain-profile "$NOTARY_PROFILE" --wait
            else
                if [[ -z "${APPLE_ID:-}" || -z "${TEAM_ID:-}" || -z "${APP_PASSWORD:-}" ]]; then
                    echo "Error: NOTARY_PROFILE or APPLE_ID/TEAM_ID/APP_PASSWORD required for notarization." >&2
                    exit 1
                fi
                xcrun notarytool submit "$DMG_PATH" \
                    --apple-id "$APPLE_ID" --team-id "$TEAM_ID" --password "$APP_PASSWORD" --wait
            fi
            xcrun stapler staple "$DMG_PATH"
            echo "Stapled notarization ticket to DMG."

            echo "Validating notarization..."
            xcrun stapler validate "$DMG_PATH"
            echo "Notarization validated successfully."
        fi

        echo ""
        echo "============================================"
        echo "Build complete!"
        echo "  App: $APP_OUT_PATH"
        echo "  DMG: $DMG_PATH"
        echo "============================================"
    else
        echo ""
        echo "============================================"
        echo "Build complete (unsigned)!"
        echo "  App: $APP_OUT_PATH"
        echo "============================================"
    fi
}

# ============================================================================
# Main
# ============================================================================

build_app "$SIGNED"
