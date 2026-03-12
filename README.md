# FFbuilder

Small, cross-platform build scripts for producing a static FFmpeg toolchain with a curated set of codecs and libraries.

## Quick start

Linux:

```bash
./bootstrap-linux.sh
./build.sh linux
```

macOS:

```bash
./bootstrap-macos.sh
./build.sh macos
```

Windows (MSYS2):

```bash
./bootstrap-windows.sh
./build.sh windows
```

Artifacts are written to `artifacts/`:

- `ffmpeg-linux.tar.xz`
- `ffmpeg-macos.tar.xz`
- `ffmpeg-windows.zip`

## Notes and options

Environment variables you can override:

- `FFMPEG_REPO`, `FFMPEG_BRANCH` (default `release/8.0`)
- `WORKDIR` (default `./ffbuild`), `ARTIFACTS` (default `./artifacts`)
- `ENABLE_VAAPI=1` (Linux VAAPI/libdrm)
- `ENABLE_NVCODEC=1` (Linux NVENC/NVDEC headers)
- `ENABLE_EXTRAS=1` (build extra optional libraries; defaults off)
- `ENABLE_FONTS=1` (fonts stack + libass; defaults to `ENABLE_EXTRAS`)
- `ENABLE_DVD=1` (DVD/BD libraries; defaults to `ENABLE_EXTRAS`)
- `ENABLE_SYSTEM_EXTRAS=1` (use system libs like X11/Vulkan/OpenCL/SDL2; defaults to `ENABLE_EXTRAS`)
- `LINUX_TOOLCHAIN=musl` (static musl builds)
- `MINGW_STATIC_RUNTIME=0` (Windows static runtime toggle)
- `BUNDLE_MINGW_RUNTIME_DLLS=1` (bundle MinGW runtime DLLs)
- `FFMPEG_AUTODETECT=1` (remove `--disable-autodetect`)

The build script assembles common libraries (x264/x265, libvpx, libsvtav1, dav1d, libfdk-aac, libopus, libvorbis, libtheora, libwebp, libzimg, libxml2, libiconv) and outputs `ffmpeg` and `ffprobe`.