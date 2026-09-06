<p align="center">
  <img src=".github/logo.svg" alt="FFbuilder logo" width="300"/>
</p>

<p align="center">
<img src="https://github.com/fuzjajadrowa/FFbuilder/actions/workflows/build-ffmpeg.yml/badge.svg" alt="Build FFmpeg">
</p>

---

FFbuilder is a repository for automated FFmpeg package distribution for Windows, macOS (Apple Silicon), and Linux. Downloads use trusted upstreams, and the outputs are minimal packages that contain only `ffmpeg` with original binary signatures intact.

**What it packages**
- Windows (win64, release 9.0.1) via trusted pre-built static packages (`Tyrrrz/FFmpegBin`)
- Linux (linux64, release 9.0.1) via trusted pre-built static packages (`Tyrrrz/FFmpegBin`)
- macOS (Apple Silicon, arm64, release 9.0.1) via trusted pre-built static packages (`Tyrrrz/FFmpegBin`)

**Final artifacts**
- `ffmpeg-windows.zip` (only `ffmpeg.exe`)
- `ffmpeg-macos.tar.xz` (only `ffmpeg`)
- `ffmpeg-linux.tar.xz` (only `ffmpeg`)

**Release**
If a push is a tag starting with `ffmpeg`, the workflow creates a release named after the tag and attaches the three artifacts above.

**Local / Runner**
- Windows + Linux: `bash winlinux/build.sh`
- macOS (Apple Silicon): `bash macos/build.sh`