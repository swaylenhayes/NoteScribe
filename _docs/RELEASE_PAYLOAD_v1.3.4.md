# GitHub Release Payload (v1.3.4)

## Tag + release title
- Tag: `v1.3.4`
- Title: `NoteScribe v1.3.4`
- Commit: `241d9c7b2daefdb4f91c5cb9cd2290e1db7ab9c2`
- Release URL: `https://github.com/swaylenhayes/NoteScribe/releases/tag/v1.3.4`

## Assets uploaded
- `$REPO_ROOT/_releases/NoteScribe-v3.dmg`
- `$REPO_ROOT/_releases/NoteScribe-v2v3.dmg`

## SHA-256
```text
e1afa53e7d0b581a1992e81ed98a923f3e7a1c3b692fe9f5dce23a888436b48d  NoteScribe-v3.dmg
8a8bf9d598664d7b1d308cdeeaf7ffc0a21f37a0783fc08c4d2c8f0902e0d21c  NoteScribe-v2v3.dmg
```

## Notarization submissions (accepted)
- `6efbd1df-b950-4f65-99e4-53e9f944aa9b` (`NoteScribe-v3.dmg`)
- `552a98b1-5e8f-4885-aa87-5a5d07e37523` (`NoteScribe-v2v3.dmg`)

## Release notes file
- `$REPO_ROOT/_docs/RELEASE_NOTES_v1.3.4.md`

## Publish command
```bash
cd $REPO_ROOT

gh release create v1.3.4 \
  $REPO_ROOT/_releases/NoteScribe-v3.dmg \
  $REPO_ROOT/_releases/NoteScribe-v2v3.dmg \
  --title "NoteScribe v1.3.4" \
  --notes-file $REPO_ROOT/_docs/RELEASE_NOTES_v1.3.4.md \
  --latest
```
