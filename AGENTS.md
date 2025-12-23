# Agents Notes (Local Setup)

## Purpose
This file documents local-only setup details for code signing/notarization and how secrets are handled. It is intentionally brief and avoids storing any secret values.

## Code signing + notarization (local-only)
- **Signing identity**: stored in your Keychain as a Developer ID Application certificate.
- **Notary credentials**: stored in Keychain via `notarytool` as a named profile.
- **Environment variables**: used at runtime in your shell (not committed).

### Keychain items (expected)
- Developer ID Application certificate for signing (visible via `security find-identity -p codesigning -v`).
- Notary profile stored by `xcrun notarytool store-credentials`, e.g. `notescribe-notary`.

### Environment variables (per-shell)
These are safe to export in your local shell because they are not committed and not visible to tools unless you paste them:
- `SIGNING_IDENTITY` (e.g. `Developer ID Application: Your Name (TEAMID)`)
- `NOTARY_PROFILE` (e.g. `notescribe-notary`)

### Where secrets live
- **Keychain**: stores the Developer ID cert + notary credentials.
- **Shell environment**: holds only non-secret identifiers like `SIGNING_IDENTITY` and `NOTARY_PROFILE`.
- **Repo**: does **not** store secrets. Build scripts reference env vars and keychain profiles only.

## Repo layout (high-level)
- `NoteScribe/` app source
- `NoteScribe.xcodeproj/` project
- `_releases/` DMGs (local)
- `DEV_BUILD_COMMANDS.md` build/sign/notarize instructions
- `uninstall_notescribe.sh` uninstall helper

## Notes
- If a new machine is used, you must install the Developer ID certificate and recreate the notary profile in Keychain.
- If a new notary profile name is used, update `NOTARY_PROFILE` accordingly.
