# NoteScribe

NoteScribe is a focused macOS voice transcription app for automatic speech recognition. It runs fully offline using Frontier Core ML audio models from [Fluid Inference](https://github.com/FluidInference/FluidAudio) (Nvidia Parakeet TDT [v2](https://huggingface.co/FluidInference/parakeet-tdt-0.6b-v2-coreml) and [v3](https://huggingface.co/FluidInference/parakeet-tdt-0.6b-v3-coreml)) and is designed for fast dictation into any text field or for transcribing audio/video files.

There are two builds with identical features:

- **Parakeet V2** (English-only)
- **Parakeet V3** (Multilingual - 25 European languages)

If you only need English, choose V2 since it has a slightly lower WER for English than V3. If you need multilingual transcription, choose V3.

## Latest Release

- **Version:** `v1.3.3` (February 18, 2026)
- **Highlights:** refreshed start/stop/paste/escape sounds, and a fix for unintended Escape cue playback during normal stop.
- **Release notes:** `/Users/swaylen/dev/NoteScribe/_docs/RELEASE_NOTES_v1.3.3.md`
- **Downloads:** [GitHub Releases](https://github.com/swaylenhayes/NoteScribe/releases)

## Model performance (M-series optimized)

Both models are Core ML models optimized for Apple silicon. In practice, Parakeet V2/V3 Core ML runs among the fastest offline ASR options on Mac today. Compared to Whisper GGML (base / large-v3 / turbo), these models show minimal extra RAM overhead, similar CPU thread usage, and a clear shift of work to the Neural Engine, leaving the rest of the system more responsive.

<img width="1400" height="1200" alt="benchmark_graph_paraCoreML_vs_whisperGGML_harvard100_swaylenhayes_12-10-2025" src="https://github.com/user-attachments/assets/f9957af1-d240-4fdd-a949-04a497a8338e" />

Compared to GGML models, the CoreML models use:
- ~50% less RAM,
- ~50% less energy draw,
- ~30-40% less CPU load (at peak)

## What it does

- Hotkey dictation that pastes into the frontmost app
- Scratchpad tab for dumping and editing text
- File transcription (audio/video)
- History and replacements

## Install

1. Download the DMG for **v2** or **v3** from GitHub Releases.
2. Open the DMG and drag `NoteScribe.app` into **Applications**.
3. Launch the app and grant microphone (and accessibility for paste) when prompted.

## Uninstall

An uninstall helper script is included in this repo: `uninstall_notescribe.sh`.

## Requirements

- macOS 14+
- Apple silicon (M-series). Intel Macs are not supported.

## Developer Notes

- Build/sign/notarize commands: `/Users/swaylen/dev/NoteScribe/_docs/DEV_BUILD_COMMANDS.md`
- Current implementation + release packaging status: `/Users/swaylen/dev/NoteScribe/_docs/CURRENT_STATE.md`
