# NoteScribe Enhancement Plan

*Created: February 15, 2026*

---

## Part 1: Bug Fix — "Transcription Failed: A server with the specified hostname could not be found"

### Root Cause Analysis

The transcription failure is caused by a chain of events in the FluidAudio SDK's model loading path:

1. **NoteScribe calls** `AsrModels.loadFromCache()` → `load()` → `DownloadUtils.loadModels()`
2. **`DownloadUtils.loadModels()`** has a retry-with-download fallback: if the first `loadModelsOnce()` throws for _any_ reason, it **deletes the entire model cache** and calls `loadModelsOnce()` again
3. **The retry** detects the cache is now empty and calls `downloadRepo()` which tries to download from HuggingFace (`https://huggingface.co`)
4. **The download fails** with `NSURLErrorDomain -1003` ("A server with the specified hostname could not be found") because:
   - macOS 26.2 sandbox restrictions block the network request
   - OR the Mac has no internet / HuggingFace is unreachable
5. **The error propagates** to `TranscriptionState.transcribeAudio()` where it's caught and saved as the error text the user sees in history

**Why the first load fails** (triggering the destructive retry): This needs runtime debugging to pinpoint, but the most likely cause is that the Xcode debug build has an **empty `Parakeet/` folder** in its Resources (confirmed — the build script cleans models after building). If models were previously cached by `ModelInitializationService`, the cache works — but if anything clears it (the retry logic, OS update, etc.), the app can't recover because `NoteScribeModelsInitializedV1` UserDefaults flag is already `true`, so it skips re-copying.

**Confirmed facts:**
- Models exist at `~/Library/Application Support/FluidAudio/Models/parakeet-tdt-0.6b-v3-coreml/` and load successfully from the command line
- The `/Applications/NoteScribe.app` bundle has models; the Xcode debug build does NOT
- Console logs show repeated `DownloadUtils` errors at every transcription attempt
- NoteScribe uses FluidAudio **v0.8.0**; Keeter uses a much newer version pinned to `main`

### Proposed Fix

**Upgrade FluidAudio + adopt Keeter's `ModelBundleManager` pattern:**

1. **Update FluidAudio** from v0.8.0 to the same commit Keeter uses (or a tagged release). Pin to a specific commit SHA for reproducibility — NOT to `main` branch.

2. **Port `ModelBundleManager`** from Keeter into NoteScribe (adapted for macOS):
   - Call `ensureModelsAvailable()` inside `ParakeetTranscriptionService.ensureModelsLoaded()` **before** every `AsrModels.loadFromCache()` call
   - This makes model availability idempotent — if the cache is ever deleted, it gets rebuilt from the bundle automatically

3. **Remove the one-shot UserDefaults flag** from `ModelInitializationService`:
   - Replace `NoteScribeModelsInitializedV1` flag-gated logic with file-existence checks
   - OR remove `ModelInitializationService` entirely and rely on `ModelBundleManager` (which checks every time)

4. **Ensure debug builds have models**: Add a note or check that the `Parakeet/` folder in the Xcode project contains model files when running from Xcode

### Risk: Low
This is the same pattern Keeter already uses successfully. FluidAudio API surface for `loadFromCache` is unchanged between versions.

---

## Part 2: Keeter Feature Parity — Enhancement Plan

### Features to Port from Keeter

After analyzing the Keeter codebase, the following post-transcription processing features are candidates for NoteScribe:

#### Enhancement 1: Comprehensive Filler Word Removal (Tier 1)
**Priority: High | Effort: Low (2-3 hours)**

NoteScribe's current `TranscriptionOutputFilter` has a basic filler list of 11 words:
```
uh, um, uhm, umm, uhh, uhhh, ah, hmm, hm, mmm, mm
```

Keeter's `FillerWordService` has a much more comprehensive Tier 1 list (34 patterns) including:
```
uh, uhh, uhhh, um, umm, ummm, uhm, uhmm,
erm, err, errr, er,
ah, ahh, ahhh,
hmm, hmmm, hm, hmmh, hmph,
mm, mmm, mhm, mhmm, mm-hmm, mm hmm,
uh-huh, uh huh, uh-uh, nuh-uh, nuh uh,
huh, huh huh,
eh, ehh, ehhh, ehm
```

**What to do:**
- Replace `TranscriptionOutputFilter`'s filler word list with Keeter's comprehensive Tier 1 list
- Use precompiled regexes (Keeter's approach) for better performance — NoteScribe currently recompiles regex on every call
- Sort patterns longest-first to prevent partial matches
- Add a user-facing toggle in Settings to enable/disable filler removal

**Key difference from Keeter:** NoteScribe applies filtering destructively at transcription time (the filtered text is what gets saved). Keeter preserves raw text and filters at display time. Both approaches are valid — NoteScribe's is fine because the raw audio is preserved for re-transcription.

#### Enhancement 2: Repetition Removal
**Priority: High | Effort: Low (1-2 hours)**

NoteScribe has **no** repetition removal. Keeter collapses consecutive repeated words:
- "the the" → "the"
- "and and" → "and"
- Generic pattern: any word ≥2 characters repeated immediately

**What to do:**
- Add repetition removal to `TranscriptionOutputFilter` using the same regex pattern as Keeter: `\b(\w{2,}),?\s+\1\b` → `$1`
- Insert this step after filler word removal in the pipeline
- Add a user-facing toggle in Settings

#### Enhancement 3: Tier 2 Filler Phrases
**Priority: Medium | Effort: Low-Medium (2-4 hours)**

Neither NoteScribe nor Keeter has implemented this yet, but both have the spec ready in `_branch-filler-words/default_filler_patterns.json`. 13 phrase-level fillers from corpus analysis:

```
"you know what i mean", "or like kind of", "like you know",
"kind of like", "sort of like", "just kind of", "i mean so",
"you know", "kind of", "sort of", "i guess", "i mean", "or like"
```

**What to do:**
- Add `tier2Patterns` array to the filter
- Same precompiled regex approach, sorted longest-first
- Add independent Settings toggle (off by default — these are more aggressive)

#### Enhancement 4: [UNK] Token Replacement
**Priority: Low | Effort: Minimal (30 min)**

Keeter replaces `[unk]` tokens (from the Parakeet model) with `&` (ampersand). NoteScribe's `TranscriptionOutputFilter` already removes all bracketed text `[.*?]`, which would strip `[unk]` entirely rather than replacing it.

**What to do:**
- Add explicit `[unk]` → `&` replacement **before** the bracketed text removal step
- Low priority since Parakeet V3 rarely outputs `[unk]` anymore

### Implementation Order

```
1. Bug Fix (FluidAudio upgrade + ModelBundleManager)     ← FIRST
2. Enhancement 1: Comprehensive Tier 1 Fillers           ← Quick win
3. Enhancement 2: Repetition Removal                      ← Quick win  
4. Enhancement 3: Tier 2 Filler Phrases                   ← After 1+2 verified
5. Enhancement 4: [UNK] Token Replacement                 ← Optional
```

### What's NOT Being Ported

These Keeter features are **iOS-specific** or not applicable to NoteScribe's architecture:

| Keeter Feature | Why Not Porting |
|---|---|
| `AppCoordinator` pattern | NoteScribe already has `TranscriptionState` as coordinator |
| Non-destructive filtering (display-time) | NoteScribe's destructive approach is fine — raw audio is preserved for re-transcription |
| Filtered/Original toggle UI | NoteScribe already has history with full text; re-transcription serves same purpose |
| Recording service refactor | NoteScribe's `Recorder` already works; no need to change |
| `TranscriptionCoordinator` actor | NoteScribe uses `@MainActor` class pattern which is fine for macOS |
| `ClipboardService` | NoteScribe already has `ClipboardManager` + `CursorPaster` |
| FAB-based recording UI | iOS-specific |

### Files to Modify

| File | Changes |
|---|---|
| `NoteScribe.xcodeproj` | Update FluidAudio package version |
| `NoteScribe/Services/ParakeetTranscriptionService.swift` | Add `ModelBundleManager.ensureModelsAvailable()` call |
| `NoteScribe/Services/ModelBundleManager.swift` | **NEW** — port from Keeter, adapt for macOS paths |
| `NoteScribe/Services/TranscriptionOutputFilter.swift` | Expand filler list, add precompiled regexes, add repetition removal, add Tier 2 |
| `NoteScribe/Services/ModelInitializationService.swift` | Remove UserDefaults flag gating, or delete entirely |
| Settings UI (TBD) | Add toggles for filler removal, repetition removal, Tier 2 fillers |

---

## Decision Points for Review

1. **FluidAudio version**: Pin to Keeter's exact commit (`01f4353`) or a specific tagged release?
2. **Filler removal approach**: Keep destructive (current NoteScribe approach) or switch to non-destructive display-time filtering (Keeter approach)?
3. **Tier 2 fillers**: Include in this round or defer?
4. **Settings UI**: Where should the new toggles go? (Existing Settings view or new "Text Processing" section?)

---

*Awaiting review before implementation begins.*
