# SFTP Forge — Android

Flutter port of the desktop `sftp-forge.py` PyQt6 app. Same profile
model (name/user/host/port/key/path), same GitHub-Dark palette.

Desktop-only actions (`xdg-open sftp://…`, `sshfs` mount, external
terminal emulator) don't map to Android, so they're replaced with:

| Desktop                | Android                                  |
|---|---|
| Open SFTP (xdg-open)   | in-app SFTP browser (`dartssh2` SftpClient) |
| Open Terminal          | in-app terminal (`dartssh2` shell + `xterm`) |
| Mount (sshfs)          | dropped — no FUSE without root            |
| `~/.config/sftp-forge.json` | JSON file in app documents dir      |

## Local dev (first run)

`android/` isn't checked in — `gradle-wrapper.jar` is a binary and
shouldn't be hand-maintained in git. Generate it once:

```bash
flutter create --platforms=android --org io.github.devboffin --project-name sftp_forge .
flutter pub get
flutter run
```

## CI

`.github/workflows/android-release.yml`:
- runs on every push to the `android` branch → build artifact only
- runs on `v*` tags → build + attach split-per-abi APKs to a GitHub Release
- can also be triggered manually (`workflow_dispatch`)

Tag a commit to cut a release:

```bash
git tag v0.1.0
git push origin v0.1.0
```
