<p align="center">
  <img src=".github/logo.svg" alt="FFbuilder logo" width="300"/>
</p>

<p align="center">
<img src="https://github.com/fuzjajadrowa/FFbuilder/actions/workflows/build-ffmpeg.yml/badge.svg" alt="Build FFmpeg">
</p>

---

FFbuilder is a repository for automated FFmpeg builds and publishing for Windows, macOS (Apple Silicon), and Linux. Builds use trusted upstreams, and the outputs are minimal packages that contain only `ffmpeg` and `ffprobe`.

**What it builds**
- Windows (win64, GPL, release 8.0) via `BtbN/FFmpeg-Builds`
- Linux (linux64, GPL, release 8.0) via `BtbN/FFmpeg-Builds`
- macOS (Apple Silicon) via `Vargol/ffmpeg-apple-arm64-build`

**Final artifacts**
- `ffmpeg-windows.zip` (only `ffmpeg.exe` and `ffprobe.exe`)
- `ffmpeg-macos.tar.xz` (only `ffmpeg` and `ffprobe`)
- `ffmpeg-linux.tar.xz` (only `ffmpeg` and `ffprobe`)

**Release**
If a push is a tag starting with `ffmpeg`, the workflow creates a release named after the tag and attaches the three artifacts above.

**Local**
- Windows + Linux (via Docker): `bash winlinux/build.sh`
- macOS (Apple Silicon): `bash macos/build.sh`