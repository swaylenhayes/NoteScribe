# GitHub Release Payload (v1.3.5)

## Tag + release title
- Tag: `v1.3.5`
- Title: `NoteScribe v1.3.5`
- App build commit: `ca2f073a3a2e`
- Release URL: `https://github.com/swaylenhayes/NoteScribe/releases/tag/v1.3.5`

## Assets uploaded
- `$REPO_ROOT/_releases/NoteScribe-v3.dmg`
- `$REPO_ROOT/_releases/NoteScribe-v2v3.dmg`

## SHA-256
```text
e0716bf88fac6255488ab30d9995f2d74ac5dc0b42cef9809203c17f5d1a34c4  NoteScribe-v3.dmg
438922c5fa21f35fc6ad4e08a6ec172ccfa6103e39310c2cd862de5fcb980246  NoteScribe-v2v3.dmg
```

## Notarization submissions (accepted)
- `377a7a20-fd9a-432f-921d-e1b059dec01a` (`NoteScribe-v3.dmg`)
- `e08517c7-4686-44c5-bb19-cbd1ccd79391` (`NoteScribe-v2v3.dmg`)

## Release notes file
- `$REPO_ROOT/_docs/RELEASE_NOTES_v1.3.5.md`

## Publish command
```bash
cd $REPO_ROOT

gh release create v1.3.5 \
  $REPO_ROOT/_releases/NoteScribe-v3.dmg \
  $REPO_ROOT/_releases/NoteScribe-v2v3.dmg \
  --title "NoteScribe v1.3.5" \
  --notes-file $REPO_ROOT/_docs/RELEASE_NOTES_v1.3.5.md \
  --latest
```
