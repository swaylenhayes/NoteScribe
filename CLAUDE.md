# NoteScribe - Claude Code Configuration

## Project Overview
**NoteScribe** is a macOS menu bar app for fast voice and file transcription using local CoreML models (Parakeet TDT). It captures audio via hotkeys, transcribes fully offline, and intelligently pastes results into foreground apps.

- **Tech Stack**: SwiftUI, AppKit, AVFoundation, CoreML, SwiftData, NaturalLanguage
- **Key Dependencies**: FluidAudio (ASR + VAD), KeyboardShortcuts
- **Models**: Parakeet v2/v3 CoreML bundles (~480MB each), Silero VAD (bundled, offline mode)
- **Privacy-First**: All processing local, no network calls, no telemetry, no model downloads
- **Current Release**: v1.2 (model warmup feature, instant first transcription)

## Repository Structure
```
NoteScribe/
├── base/              # Primary source tree (single codebase)
├── models/            # External model storage (NOT in git)
│   ├── parakeet-v2/  # ~443MB - English only
│   ├── parakeet-v3/  # ~461MB - Multilingual
│   └── vad/          # ~1MB - Voice Activity Detection
├── _releases/         # Built DMGs and notarized artifacts
│   ├── NoteScribe-v2.dmg  # Signed/notarized v2
│   └── NoteScribe-v3.dmg  # Signed/notarized v3
├── archive/           # Retired code, worktrees, large models
├── build_notescribe.sh    # Unified build script (--model v2|v3)
├── uninstall_notescribe.sh  # Clean uninstall helper
├── CURRENT_STATE.md   # Project status (KEEP UPDATED)
├── DEV_BUILD_COMMANDS.md    # Build process reference
└── RELEASE_NOTES_v1.2.md    # Current release notes
```

## Model Assets (Critical Info)

### Model Storage (External)
- **Location**: `models/` directory (NOT in git, stored locally only)
- **Parakeet v2**: `models/parakeet-v2/parakeet-tdt-0.6b-v2-coreml/` (~443MB, English only)
- **Parakeet v3**: `models/parakeet-v3/parakeet-tdt-0.6b-v3-coreml/` (~461MB, Multilingual)
- **VAD**: `models/vad/silero-vad-coreml/` (~1MB, Voice Activity Detection)

### Build-Time Model Injection
- Models are copied from `models/` to `base/NoteScribe/Resources/BundledModels/` at build time
- After build completes, models are cleaned from source tree
- `base/` stays pristine with no large model files

### Archived Items (DO NOT USE)
- `archive/v2-worktree-archived/` - Old v2 worktree
- `archive/v3-worktree-archived/` - Old v3 worktree
- `archive/v2-L/`, `archive/v3-L/` - Legacy large model variants

## Permissions & Autonomy

### ✅ FULL AUTONOMY - No Approval Needed
- **File Operations**: Create, edit, delete files in project directory (except archives)
- **Code Changes**: Modify Swift source, Xcode projects, plists, entitlements
- **Git Operations**: Commit, branch, merge, rebase, tag within local repo
- **Documentation**: Update `.md` files, especially `CURRENT_STATE.md` after significant changes
- **Builds**: Run build scripts, compile in Xcode, code sign locally
- **Dependencies**: Update SPM packages, modify Package.swift
- **Testing**: Run unit tests, integration tests, manual testing
- **Refactoring**: Restructure code, rename files, reorganize directories
- **Asset Management**: Add/modify bundled resources under 10MB

### ⚠️ ASK FIRST - Requires Approval
- **Pushing to GitHub**: Wait for explicit instruction before `git push`
- **Model Changes**: Don't add/remove/modify bundled models without asking
- **Build Script Changes**: Notify before modifying signing/notarization logic
- **Breaking Changes**: Alert before major API or architecture changes that affect multiple files
- **External Network**: Don't add any network calls or telemetry
- **Deleting Releases**: Don't delete items from `_releases/` without asking
- **Archive Operations**: Don't modify or delete archived items (v2-L, v3-L, archive/)

### 🚫 NEVER DO
- Add analytics, telemetry, or network requests (privacy violation)
- Commit secrets, keys, or credentials
- Delete `CURRENT_STATE.md` or core documentation files
- Modify `.git/` directly
- Bundle or unbundle large CoreML models (>100MB) without explicit instruction
- Touch archived directories (v2-L, v3-L, archive/)

## Development Workflow

### Standard Task Flow
1. **Read Context**: Check `CURRENT_STATE.md` and relevant docs for current status
2. **Execute**: Make changes, write tests, build and verify locally
3. **Document**: Update `CURRENT_STATE.md` with changes made and next steps
4. **Commit**: Clear commit message explaining what and why
5. **Report**: Summarize what was done, test results, and any issues encountered

### Branch Strategy
- **main**: Stable, working builds only
- **feature/***: New features, experimental work
- **fix/***: Bug fixes  
- **refactor/***: Code restructuring
- Future: **filler-words** branch for enhanced text cleanup edition

### Documentation Requirements
After significant changes, always update:
- **`CURRENT_STATE.md`** - Most important: current status, next steps, known issues
- **`TRANSCRIPTION_PIPELINE.md`** - If transcription flow changed
- **`ARCHITECTURE_MOVE_UPDATE.md`** - If structure or design patterns changed
- **`DEV_BUILD_COMMANDS.md`** - If build process changed

### Build & Test

#### Environment Setup (Required)
```bash
# Set these in your shell before building
export SIGNING_IDENTITY="Developer ID Application: Your Name (TEAMID)"
export NOTARY_PROFILE="your-notary-profile"
```

#### Quick Build Commands
```bash
# Unified build script - use --model v2 or --model v3

# Full pipeline: build + sign + notarize + staple + validate
SIGNING_IDENTITY="$SIGNING_IDENTITY" NOTARY_PROFILE="$NOTARY_PROFILE" NOTARIZE=1 \
  ./build_notescribe.sh --model v2 --signed

SIGNING_IDENTITY="$SIGNING_IDENTITY" NOTARY_PROFILE="$NOTARY_PROFILE" NOTARIZE=1 \
  ./build_notescribe.sh --model v3 --signed

# Unsigned build (for local testing only)
./build_notescribe.sh --model v3
```

#### Output Locations
- v2 DMG: `/Users/swaylen/dev/NoteScribe/_releases/NoteScribe-v2.dmg`
- v3 DMG: `/Users/swaylen/dev/NoteScribe/_releases/NoteScribe-v3.dmg`
- Apps in respective folders under `_releases/`

#### Testing Protocol
- **Build Test**: Verify successful compilation and signing
- **First-Run Test**: Fresh install → launch → test hotkey transcription immediately
- **Paste Reliability**: Test transcription paste in multiple apps (Notes, TextEdit, browser)
- **File Transcription**: Upload audio/video files, verify VAD behavior
- **Settings**: Test word replacements, output filtering, paragraph formatting

## Code Quality Standards

### Swift Best Practices
- Modern concurrency (async/await) for I/O and long operations
- Proper error handling with typed errors (TranscriptionError)
- Memory safety (avoid retain cycles, proper @MainActor usage)
- Use os.log for logging with consistent subsystem/category pattern

### Performance Considerations
- Keep CoreML operations off main thread
- Minimize UI blocking during transcription
- Efficient audio buffer handling (AVFoundation)
- Respect memory constraints (models are ~480MB each)
- Consider startup time (model loading on first run)

### Architecture Patterns
- **SwiftUI** for UI components
- **AppKit** for menu bar integration and window management
- **SwiftData** for persistence (transcription history)
- **Coordinator pattern** for transcription pipeline orchestration
- **Clear separation**: UI → Manager → Service → Engine → CoreML

### Privacy & Security
- **No network calls** - Everything runs offline
- **No telemetry** - No usage tracking, analytics, or reporting
- **Local models only** - Models are bundled, downloads disabled
- **Keychain-based** - Signing credentials in Keychain, not in code

## Transcription Pipeline (Critical Understanding)

### Pipeline Flow (Sequential)
```
Audio Input → VAD (optional) → CoreML ASR → Output Filter → Trim → 
Text Formatter (optional) → Word Replacement → Save & Paste
```

### Key Processing Details
1. **Model Output**: Raw text from CoreML with NO punctuation or capitalization added by code
2. **VAD (Voice Activity Detection)**: Applied if enabled and audio >= 20s
3. **Output Filter**: Removes bracketed text `[noise]`, filler words (case-insensitive with optional trailing punctuation)
4. **Text Formatter**: Chunks into paragraphs using sentence boundaries (optional)
5. **Word Replacement**: Case-insensitive dictionary replacement (runs LAST)
6. **Paste**: Adds trailing space when pasting to cursor

### Critical Files
- `TranscriptionState.swift` - Main coordination (Line 260 for transcribeAudio)
- `ParakeetTranscriptionService.swift` - CoreML integration (Line 77 for transcribe)
- `TranscriptionOutputFilter.swift` - Filler word removal (Lines 33, 35)
- `TranscriptionTextFormatter.swift` - Paragraph formatting
- `WordReplacementService.swift` - Dictionary replacement (Lines 8, 18, 27, 30, 49)
- `CursorPaster.swift` - Intelligent paste handling

### Known Behaviors
- **No Punctuation**: Model output has no periods, commas, or capitals (model limitation)
- **Filler Words**: Regex handles optional trailing `,` or `.` automatically
- **Case Insensitive**: Both filter and word replacement ignore case
- **Multi-Word Limitation**: Current regex can't handle embedded punctuation in phrases

## Current Focus & Known Issues

### Active Investigation
- **First-run paste reliability**: Some users report first transcription doesn't paste
- **Possible causes**: Model loading delay, permissions timing, initialization race
- **Action**: Sanity check fresh installs with immediate hotkey test
- **Solution ideas**: Add "ready" state indicator, initialization gate, or pre-warm model

### Immediate Next Steps
1. Run fresh uninstall/install test loop for v2 and v3
2. Test first transcription paste within 10 seconds of launch
3. If issues persist, add visible "ready" indicator or pre-load model
4. Document findings in `CURRENT_STATE.md`
5. Cut point release if fixes required

### Roadmap Priorities
1. Resolve first-run paste reliability (highest priority)
2. Create filler-words enhancement branch
3. Refactor to single `base` source tree with external model injection
4. Enhanced punctuation and text formatting
5. Emoji embellishments feature
6. MCP command execution integration

## Context Sharing with Web Project

This repository is actively managed across two Claude interfaces:

### Claude Code (here) - Implementation
- Hands-on coding, building, testing
- File operations, git commits
- Direct command execution
- Update `CURRENT_STATE.md` after changes

### Claude Web (project) - Strategy
- Architecture discussions and decisions
- Code review and design consultation
- Documentation generation and synthesis
- Problem-solving for complex issues

### Handoff Protocol
**From Code → Web**:
1. Complete work and test thoroughly
2. Update `CURRENT_STATE.md` with detailed status
3. Commit changes with clear message
4. Note "Ready for architectural review" or "Need design consultation"
5. Shane uploads docs to web project

**From Web → Code**:
1. Architectural approach defined in web project
2. Implementation plan created with steps
3. Shane passes plan to Code interface
4. Code executes and documents completion

### Sync Points (Always Update Docs)
- After stable builds/releases
- Before starting new feature branches
- When encountering architectural decisions
- After resolving major bugs
- When modifying build/release process

## Quick Reference

### Critical Documentation Files
- **`CURRENT_STATE.md`** - Single source of truth for project status
- **`TRANSCRIPTION_PIPELINE.md`** - How audio → text works (detailed)
- **`ARCHITECTURE_MOVE_UPDATE.md`** - Architectural decisions and future plans
- **`DEV_BUILD_COMMANDS.md`** - Build/sign/notarize process
- **`PROJECT_SUMMARY.md`** - High-level app overview
- **`AGENTS.md`** - Local signing/notarization setup

### Core Source Files
- `TranscriptionState.swift` - Main transcription coordinator
- `ParakeetTranscriptionService.swift` - CoreML integration
- `TranscriptionOutputFilter.swift` - Filler word removal
- `TranscriptionTextFormatter.swift` - Paragraph formatting
- `WordReplacementService.swift` - Dictionary replacement
- `CursorPaster.swift` - Intelligent paste handling
- `AudioCaptureManager.swift` - Live audio capture
- `AudioFileTranscriptionService.swift` - File transcription
- `AppDelegate.swift` - Menu bar lifecycle
- `SettingsView.swift` - User configuration UI

### Model Locations
- **External**: `models/parakeet-v2/`, `models/parakeet-v3/`, `models/vad/`
- **At build time**: Copied to `base/NoteScribe/Resources/BundledModels/`
- **After build**: Cleaned from source tree automatically

### Build Artifacts
- **Source**: `base/` (single source tree)
- **Releases**: `_releases/NoteScribe-v2.dmg`, `_releases/NoteScribe-v3.dmg`
- **Archive**: `archive/` (retired worktrees, don't touch)

### Location of Filler-Word Feature Files
- `_branch-filler-words/`

### Repository Status
- **GitHub**: https://github.com/swaylenhayes/NoteScribe
- **Current Release**: v1.2 (model warmup, instant first transcription)
- **Active Branches**: main (stable), future: filler-words

## Communication Expectations

### When Working (Be Direct)
- Just do the work, minimal preamble
- Show relevant command output and build results
- Flag blockers immediately with what you tried
- Update `CURRENT_STATE.md` after significant changes

### When Reporting Back (Be Complete)
- What was changed (files, features, fixes)
- Build/test results (success/failure, output locations)
- Any issues encountered or blockers hit
- What's documented where (which files updated)
- Suggested next steps or follow-up needed

### When Uncertain (Ask Smart Questions)
- If requirements ambiguous, suggest approach and ask for confirmation
- If making breaking change, explain tradeoffs and alternatives
- If you find better pattern, propose it with rationale
- If stuck on issue, show what you've tried and diagnostics collected

### Logging & Debugging
- Use `os.log` with appropriate subsystem/category
- Check Console.app for runtime logs
- Include relevant log snippets in reports
- Test in both debug and release builds

## Privacy & Security Rules (Non-Negotiable)

### The Prime Directive
**If it phones home, it doesn't ship.**

### Specific Constraints
- ❌ No network calls (except system permissions checks)
- ❌ No analytics or telemetry
- ❌ No model downloads or updates
- ❌ No cloud sync or backup
- ❌ No crash reporting services
- ✅ All processing local
- ✅ Models bundled offline
- ✅ User data stays on device

### Commit Safety
- Never commit API keys, secrets, or credentials
- Signing identity stored in Keychain, not code
- Notary profile stored in Keychain, not code
- Environment variables for build-time references only

---

## Development Machine Context

**Shane's Setup**:
- **Machine**: MacBook Pro M2 Max, 96GB RAM
- **OS**: macOS 15.7.2 (Sequoia)
- **Shell**: zsh + Oh-My-Zsh + Starship
- **Dev Path**: `/Users/swaylen/dev/NoteScribe/`

**Primary IDEs & Tools**:
- **Xcode**: Primary for Swift/macOS development
- **VS Code**: General code editing
- **iTerm2**: Terminal emulator
- **Claude Code**: v2.0.74 (AI coding agent - you)

**Swift Development**:
- swiftformat v0.58.7 (code formatting)
- swiftlint v0.62.2 (linting)
- Copilot for Xcode (AI assistance)
- cocoapods v1.16.2 (dependency management)

**Version Management**:
- **Mise**: Manages dev tool versions (Node 25.2.1, Python 3.11.14, Ruby 3.3.10, Go 1.25.5, Rust 1.92.0)
- **UV**: Python package/tool management
- **Bun**: JavaScript runtime and package manager

**AI/ML Tools**:
- **LMStudio**: Local LLM inference
- **llamabarn**: Model management (Homebrew cask)
- **llama.cpp**: Local inference engine
- **mflux**: ML model training/inference (UV tool, v0.13.3)

**Key CLI Tools**:
- **Git**: v2.50.1 with gh (GitHub CLI v2.83.2), git-lfs, lazygit
- **Build Tools**: cmake v4.2.1, just v1.45.0
- **Text Processing**: ripgrep v15.1.0, jq v1.8.1, yq v4.50.1, bat v0.26.1
- **Media**: ffmpeg (Homebrew), yt-dlp (UV tool)
- **Editor**: helix v25.07.1 (terminal editor)
- **Shell Enhancements**: fzf v0.67.0, zoxide v0.9.8, eza, delta v0.18.2

**Design Tools**:
- Figma (design/prototyping)
- Pixelmator (image editing)
- Draw Things (local AI image generation)

**Workflow Preferences**:
- **Documentation-Driven**: Keep docs updated, systematic approach
- **Clean Separation**: Stable main branch, experimental feature branches
- **Local-First**: Offline models, no cloud dependencies, privacy-focused
- **Tool Automation**: Uses mise for version management, UV for Python tools
- **AI-Augmented**: Multiple AI coding assistants (Claude Code, Copilot)
- **Terminal-Centric**: Heavy CLI usage, custom shell configuration

---

*Last Updated: December 2025*  
*This file evolves with the project. Update as needed.*
