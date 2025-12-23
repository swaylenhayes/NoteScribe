# NoteScribe

NoteScribe is a focused macOS voice transcription app for automatic speech recognition. It runs fully offline using bundled Parakeet TDT Core ML models (v2 or v3) and is designed for fast dictation into any text field or for transcribing audio/video files.

There are two builds with identical features:

- **Parakeet V2** (English-only)
- **Parakeet V3** (Multilingual - 25 European languages)

If you only need English, choose V2 since it has a slightly lower WER for English than V3. If you need multilingual transcription, choose V3.

## Model performance (M-series optimized)

Both models are Core ML models optimized for Apple silicon. In practice, Parakeet V2/V3 Core ML runs among the fastest offline ASR options on Mac today. Compared to Whisper GGML (base / large-v3 / turbo), these models show minimal extra RAM overhead, similar CPU thread usage, and a clear shift of work to the Neural Engine, leaving the rest of the system more responsive.

![Benchmark graph placeholder](benchmark_graph.png)
Compared to GGML models, CoreML models are showing they use:
~50% less RAM,
~50% less energy draw,
~30-40% less CPU load (at peak)

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
