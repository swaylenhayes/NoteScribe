# GitHub Release Payload (v1.3.3)

## Tag + release title
- Tag: `v1.3.3`
- Title: `NoteScribe v1.3.3`

## Assets to upload
- `/Users/swaylen/dev/NoteScribe/_releases/NoteScribe-v2.dmg`
- `/Users/swaylen/dev/NoteScribe/_releases/NoteScribe-v3.dmg`
- `/Users/swaylen/dev/NoteScribe/_releases/NoteScribe-v2v3.dmg`

## SHA-256
```text
c43feaa3d0850ebe165e2e222e3bda74395eaf77464e8951eb53d1dac1247c74  NoteScribe-v2.dmg
641c130733713c4ba19278d6d719e304bd012b125921cf504a46b3145d1f7bc5  NoteScribe-v3.dmg
a2401f2a3f4c675b574c17e4ba7f208dac2077cbf846a659fc6b0c58098da047  NoteScribe-v2v3.dmg
```

## Notarization submissions (accepted)
- `c0543c71-2862-49c6-b2c9-c7cd9e5a57cf` (`NoteScribe-v2.dmg`)
- `da3ce82b-d9b9-4f10-89e9-b54264129beb` (`NoteScribe-v3.dmg`)
- `67590167-2884-4c19-a47d-6f517d406dde` (`NoteScribe-v2v3.dmg`)

## Release notes file
- `/Users/swaylen/dev/NoteScribe/_docs/RELEASE_NOTES_v1.3.3.md`

## Commands
```bash
cd /Users/swaylen/dev/NoteScribe

# Create tag
git tag v1.3.3
git push origin v1.3.3

# Create GitHub release (draft)
gh release create v1.3.3 \
  /Users/swaylen/dev/NoteScribe/_releases/NoteScribe-v2.dmg \
  /Users/swaylen/dev/NoteScribe/_releases/NoteScribe-v3.dmg \
  /Users/swaylen/dev/NoteScribe/_releases/NoteScribe-v2v3.dmg \
  --title "NoteScribe v1.3.3" \
  --notes-file /Users/swaylen/dev/NoteScribe/_docs/RELEASE_NOTES_v1.3.3.md \
  --draft
```
