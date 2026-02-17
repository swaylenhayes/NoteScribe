# GitHub Release Payload (v1.3.2)

## Tag + release title
- Tag: `v1.3.2`
- Title: `NoteScribe v1.3.2`

## Assets to upload
- `/Users/swaylen/dev/NoteScribe/_releases/NoteScribe-v2.dmg`
- `/Users/swaylen/dev/NoteScribe/_releases/NoteScribe-v3.dmg`

## SHA-256
```text
c75ed515c09ec2d3ef2b636c604d8f1adfbf88d87b0a1abe06ddf848c33d3e03  NoteScribe-v2.dmg
2c1562f05d3d0979cc114db6840d1de5e627dabafecb4195ceb44bf4609341dd  NoteScribe-v3.dmg
```

## Notarization submissions (accepted)
- `6114d78b-b06b-4dc1-b9d1-4871f248a171` (`NoteScribe-v2.dmg`)
- `b3826332-8210-4a34-ad64-efa2bcf70062` (`NoteScribe-v3.dmg`)

## Release notes file
- `/Users/swaylen/dev/NoteScribe/_docs/RELEASE_NOTES_v1.3.2.md`

## Commands
```bash
cd /Users/swaylen/dev/NoteScribe

# Create tag
git tag v1.3.2
git push origin v1.3.2

# Create GitHub release (draft)
gh release create v1.3.2 \
  /Users/swaylen/dev/NoteScribe/_releases/NoteScribe-v2.dmg \
  /Users/swaylen/dev/NoteScribe/_releases/NoteScribe-v3.dmg \
  --title "NoteScribe v1.3.2" \
  --notes-file /Users/swaylen/dev/NoteScribe/_docs/RELEASE_NOTES_v1.3.2.md \
  --draft
```
