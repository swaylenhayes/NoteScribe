# Current State (Bookmark)

## Where we are
- **v1.3 release ready** - Built, signed, notarized DMGs for v2 and v3.
- **Single source tree** - `base/` is the only codebase; v2/v3 are build-time model injections.
- Signing + notarization workflow is established and repeatable.
- **First recording reliability fixed** - waits for file finalize + robust audio read fallback.
- **Model warmup implemented** - eliminates cold start delay on first transcription.
- **Enhanced UI removed** - no enhanced tabs/shortcuts in history/results.
- **v2/ and v3/ worktrees archived** - now in `archive/v2-worktree-archived` and `archive/v3-worktree-archived`.

## Model Warmup Feature (Dec 2025)
The app now pre-warms the CoreML model at startup to eliminate cold start delays:

### What It Does
- Pre-loads the Parakeet model into memory immediately after app launch
- Shows full-screen overlay "Loading Local Model" during warmup
- First transcription is now as fast as subsequent ones (~59ms vs 20+ seconds)

### Implementation
- `TranscriptionState+ModelManagement.swift`: `prewarmModel()`
- `NoteScribe.swift`: calls `prewarmModel()` after model init
- `ContentView.swift`: `ModelLoadingOverlay` (no icon)
- `MenuBarView.swift`: shows loading indicator in menu bar dropdown

### User Experience
- On first launch, a full overlay shows "Loading Local Model" and a progress indicator
- Overlay fades out when model is ready
- Warmup typically takes 10-20 seconds on first launch

## Architecture Consolidation (Completed Dec 2025)

### New Build System
```bash
# Build v2 (English only model)
./build_notescribe.sh --model v2 --signed

# Build v3 (Multilingual model)
./build_notescribe.sh --model v3 --signed

# Environment variables required for signed builds:
export SIGNING_IDENTITY="Developer ID Application: Your Name (TEAMID)"
export NOTARY_PROFILE="your-notary-profile"
export NOTARIZE=1
```

### Directory Structure
```
NoteScribe/
├── base/                    # Primary source tree (single codebase)
├── models/                  # External model storage (NOT in git)
│   ├── parakeet-v2/        # ~443MB - English only
│   ├── parakeet-v3/        # ~461MB - Multilingual
│   └── vad/                # ~1MB - Voice Activity Detection
├── build_notescribe.sh     # Unified build script
├── _releases/              # Build outputs
│   ├── NoteScribe-v2/      # v2 app bundle
│   ├── NoteScribe-v2.dmg   # v2 signed/notarized DMG
│   ├── NoteScribe-v3/      # v3 app bundle
│   └── NoteScribe-v3.dmg   # v3 signed/notarized DMG
├── archive/                # Old scripts and worktrees
│   ├── v2-worktree-archived/
│   └── v3-worktree-archived/
└── _branch-filler-words/   # Saved filler word feature (paused)
```

### Key Changes Made
1. **PredefinedModels.swift** - Auto-detects bundled model at runtime
2. **ModelInitializationService.swift** - Dynamic model path resolution
3. **project.pbxproj** - Uses Parakeet folder reference instead of individual models
4. **build_notescribe.sh** - Unified script with `--model v2|v3` parameter
5. **Models cleaned after build** - `base/` stays pristine
6. **Recording finalization** - waits for file finalize before transcription
7. **Offline audio fallback** - uses FluidAudio file-based transcribe if CoreAudio read fails

### How It Works
1. Build script copies selected model from `models/` to `base/NoteScribe/Resources/BundledModels/Parakeet/`
2. Xcode builds using the Parakeet folder reference
3. App auto-detects which model is bundled at runtime
4. Build script cleans up models from source tree after build

## Filler Word Feature (Paused)
- Code preserved in `_branch-filler-words/`
- Ready to implement after architecture is stable
- Files: FillerPatternConfig.swift, FillerWordService.swift, default_filler_patterns.json

## Next Actions
1. ✅ Run functional tests on v2 and v3 builds - DONE
2. ✅ Test signing and notarization flow - DONE
3. ✅ Model warmup feature - DONE
4. ✅ v1.3 release built and notarized - DONE
5. ✅ Archive v2/ and v3/ worktrees - DONE
6. Publish v1.3 to GitHub (base source + v2/v3 DMGs)
7. Resume filler word feature implementation (see ROADMAP.md)

## Roadmap Notes
- See `ROADMAP.md` for current roadmap and backlog.
