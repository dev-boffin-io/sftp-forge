# SFTP Forge — Android

Flutter port of the desktop `sftp-forge.py` PyQt6 app (see the
[repo root README](../README.md) for the desktop app). Same profile
model (name/user/host/port/key/path), same GitHub-Dark palette.

Desktop-only actions (`xdg-open sftp://…`, `sshfs` mount, external
terminal emulator) don't map to Android, so they're replaced with:

| Desktop                | Android                                  |
|---|---|
| Open SFTP (xdg-open)   | in-app SFTP browser (`dartssh2` SftpClient) |
| Open Terminal          | in-app terminal (`dartssh2` shell + `xterm2`) |
| Mount (sshfs)          | dropped — no FUSE without root            |
| `~/.config/sftp-forge.json` | JSON file in app documents dir      |

## Local dev (first run)

`android/` isn't checked in — `gradle-wrapper.jar` is a binary and
shouldn't be hand-maintained in git. Generate it once, from inside
this `mobile/` folder:

```bash
cd mobile
flutter create --platforms=android --org io.github.devboffin --project-name sftp_forge .
flutter pub get
flutter run
```

## CI

[`../.github/workflows/android-release.yml`](../.github/workflows/android-release.yml):
- triggers only on changes under `mobile/**` (desktop-only commits
  don't rebuild the APK)
- runs on every push to `master` touching `mobile/**` → build artifact only
- runs on `v*` tags → build + attach split-per-abi APKs to a GitHub Release
- can also be triggered manually (`workflow_dispatch`)
- also generates the launcher icon from `assets/icon/icon.png` via
  `flutter_launcher_icons`, and patches the generated Gradle project
  for `compileSdk 36` and the release `INTERNET` permission — see
  inline comments in the workflow for why each patch is needed

Tag a commit to cut a release:

```bash
git tag v0.1.0
git push origin v0.1.0
```
