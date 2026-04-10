#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

REPO_URL="${REPO_URL:-https://github.com/Vargol/ffmpeg-apple-arm64-build.git}"
REPO_BRANCH="${REPO_BRANCH:-master}"

WORK_DIR="${WORK_DIR:-$ROOT_DIR/.vargol-work}"
CLONE_DIR="${CLONE_DIR:-$WORK_DIR/ffmpeg-apple-arm64-build}"
BUILD_DIR="${BUILD_DIR:-$WORK_DIR/work}"
OUTPUT_DIR="${OUTPUT_DIR:-$ROOT_DIR/artifacts}"
KEEP_WORKDIR="${KEEP_WORKDIR:-0}"
FFMPEG_VERSION="${FFMPEG_VERSION:-7.1.1}"

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || { echo "Missing required command: $1" >&2; exit 1; }
}

cleanup() {
    if [[ "$KEEP_WORKDIR" != "1" ]]; then
        rm -rf "$WORK_DIR"
    fi
}
trap cleanup EXIT

require_cmd git
require_cmd curl
require_cmd tar
require_cmd make
require_cmd bunzip2
require_cmd zip

rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR" "$BUILD_DIR"

git clone --depth=1 --branch "$REPO_BRANCH" "$REPO_URL" "$CLONE_DIR"

SCRIPT_DIR="$CLONE_DIR/build"
TEST_DIR="$CLONE_DIR/test"
TOOL_DIR="$BUILD_DIR/tool"
OUT_DIR="$BUILD_DIR/out"

echo "base directory is $CLONE_DIR"
echo "script directory is $SCRIPT_DIR"
echo "test directory is $TEST_DIR"
echo "working directory is $BUILD_DIR"
echo "tool directory is $TOOL_DIR"
echo "output directory is $OUT_DIR"

. "$SCRIPT_DIR/functions.sh"

echoSection "prepare workspace"
mkdir -p "$TOOL_DIR"
checkStatusAndAction $? "unable to create tool directory"
PATH="$TOOL_DIR/bin:$PATH"
export PATH
mkdir -p "$OUT_DIR"
checkStatusAndAction $? "unable to create output directory"
export PKG_CONFIG_PATH="$TOOL_DIR/lib/pkgconfig"

CPUS=1
if command -v nproc >/dev/null 2>&1; then
    CPUS="$(nproc)"
elif command -v sysctl >/dev/null 2>&1; then
    CPUS="$(sysctl -n hw.ncpu 2>/dev/null || echo 1)"
fi
echo "use ${CPUS} cpu threads"

COMPILATION_START_TIME="$(currentTimeInSeconds)"

START_TIME="$(currentTimeInSeconds)"
echoSection "compile cmake"
"$SCRIPT_DIR/build-cmake.sh" "$SCRIPT_DIR" "$BUILD_DIR" "$TOOL_DIR" "$CPUS" "3.31" "3.31.6" > "$BUILD_DIR/build-cmake.log" 2>&1
checkStatus $? "build cmake"
echoDurationInSections "$START_TIME"

START_TIME="$(currentTimeInSeconds)"
echoSection "compile pkg-config"
"$SCRIPT_DIR/build-pkg-config.sh" "$SCRIPT_DIR" "$BUILD_DIR" "$TOOL_DIR" "0.29.2" > "$BUILD_DIR/build-pkg-config.log" 2>&1
checkStatus $? "build pkg-config"
echoDurationInSections "$START_TIME"

START_TIME="$(currentTimeInSeconds)"
echoSection "compile FriBidi"
"$SCRIPT_DIR/build-fribidi.sh" "$SCRIPT_DIR" "$BUILD_DIR" "$TOOL_DIR" "$CPUS" "1.0.10" > "$BUILD_DIR/build-fribidi.log" 2>&1
checkStatus $? "build FriBidi"
echoDurationInSections "$START_TIME"

START_TIME="$(currentTimeInSeconds)"
echoSection "compile zlib"
"$SCRIPT_DIR/build-zlib.sh" "$SCRIPT_DIR" "$BUILD_DIR" "$TOOL_DIR" "$CPUS" "v1.3.1" > "$BUILD_DIR/build-zlib.log" 2>&1
checkStatus $? "build zlib"
echoDurationInSections "$START_TIME"

START_TIME="$(currentTimeInSeconds)"
echoSection "compile libpng"
"$SCRIPT_DIR/build-libpng.sh" "$SCRIPT_DIR" "$BUILD_DIR" "$TOOL_DIR" "$CPUS" "xxxxxx" > "$BUILD_DIR/build-libpng.log" 2>&1
checkStatus $? "build libpng"
echoDurationInSections "$START_TIME"

START_TIME="$(currentTimeInSeconds)"
echoSection "compile brotli"
"$SCRIPT_DIR/build-brotli.sh" "$SCRIPT_DIR" "$BUILD_DIR" "$TOOL_DIR" "$CPUS" "xxxxxx" > "$BUILD_DIR/build-brotli.log" 2>&1
checkStatus $? "build brotli"
echoDurationInSections "$START_TIME"

START_TIME="$(currentTimeInSeconds)"
echoSection "compile freetype"
"$SCRIPT_DIR/build-freetype.sh" "$SCRIPT_DIR" "$BUILD_DIR" "$TOOL_DIR" "$CPUS" "VER-2-11-1" > "$BUILD_DIR/build-freetype.log" 2>&1
checkStatus $? "build freetype"
echoDurationInSections "$START_TIME"

START_TIME="$(currentTimeInSeconds)"
echoSection "compile harfbuzz"
"$SCRIPT_DIR/build-harfbuzz.sh" "$SCRIPT_DIR" "$BUILD_DIR" "$TOOL_DIR" "$CPUS" "xxxx" > "$BUILD_DIR/build-harfbuzz.log" 2>&1
checkStatus $? "build harfbuzz"
echoDurationInSections "$START_TIME"

START_TIME="$(currentTimeInSeconds)"
echoSection "compile libass"
"$SCRIPT_DIR/build-libass.sh" "$SCRIPT_DIR" "$BUILD_DIR" "$TOOL_DIR" "$CPUS" "0.15.1" > "$BUILD_DIR/build-libass.log" 2>&1
checkStatus $? "build libass"
echoDurationInSections "$START_TIME"

START_TIME="$(currentTimeInSeconds)"
echoSection "compile fdk-aac"
"$SCRIPT_DIR/build-fdk-aac.sh" "$SCRIPT_DIR" "$BUILD_DIR" "$TOOL_DIR" "2.0.2" > "$BUILD_DIR/build-fdk-aac.log" 2>&1
checkStatus $? "build fdk-aac"
echoDurationInSections "$START_TIME"

START_TIME="$(currentTimeInSeconds)"
echoSection "compile x265"
"$SCRIPT_DIR/build-x265.sh" "$SCRIPT_DIR" "$BUILD_DIR" "$TOOL_DIR" "$CPUS" "4.1" > "$BUILD_DIR/build-x265.log" 2>&1
checkStatus $? "build x265"
echoDurationInSections "$START_TIME"

START_TIME="$(currentTimeInSeconds)"
echoSection "compile svt-av1"
"$SCRIPT_DIR/build-svt-av1.sh" "$SCRIPT_DIR" "$BUILD_DIR" "$TOOL_DIR" "$CPUS" "v2.3.0" > "$BUILD_DIR/build-svt-av1.log" 2>&1
checkStatus $? "build svt-av1"
echoDurationInSections "$START_TIME"

START_TIME="$(currentTimeInSeconds)"
echoSection "compile ogg"
"$SCRIPT_DIR/build-ogg.sh" "$SCRIPT_DIR" "$BUILD_DIR" "$TOOL_DIR" "$CPUS" "xxxx" > "$BUILD_DIR/build-ogg.log" 2>&1
checkStatus $? "build ogg"
echoDurationInSections "$START_TIME"

START_TIME="$(currentTimeInSeconds)"
echoSection "compile vorbis"
"$SCRIPT_DIR/build-vorbis.sh" "$SCRIPT_DIR" "$BUILD_DIR" "$TOOL_DIR" "$CPUS" "xxxx" > "$BUILD_DIR/build-vorbis.log" 2>&1
checkStatus $? "build vorbis"
echoDurationInSections "$START_TIME"

START_TIME="$(currentTimeInSeconds)"
echoSection "compile aom"
"$SCRIPT_DIR/build-aom.sh" "$SCRIPT_DIR" "$BUILD_DIR" "$TOOL_DIR" "$CPUS" "2.0.0" > "$BUILD_DIR/build-aom.log" 2>&1
checkStatus $? "build aom"
echoDurationInSections "$START_TIME"

START_TIME="$(currentTimeInSeconds)"
echoSection "compile openh264"
"$SCRIPT_DIR/build-openh264.sh" "$SCRIPT_DIR" "$BUILD_DIR" "$TOOL_DIR" "$CPUS" "2.3.0" > "$BUILD_DIR/build-openh264.log" 2>&1
checkStatus $? "build openh264"
echoDurationInSections "$START_TIME"

START_TIME="$(currentTimeInSeconds)"
echoSection "compile x264"
"$SCRIPT_DIR/build-x264.sh" "$SCRIPT_DIR" "$BUILD_DIR" "$TOOL_DIR" "$CPUS" > "$BUILD_DIR/build-x264.log" 2>&1
checkStatus $? "build x264"
echoDurationInSections "$START_TIME"

START_TIME="$(currentTimeInSeconds)"
echoSection "compile vpx"
"$SCRIPT_DIR/build-vpx.sh" "$SCRIPT_DIR" "$BUILD_DIR" "$TOOL_DIR" "$CPUS" "1.9.0" > "$BUILD_DIR/build-vpx.log" 2>&1
checkStatus $? "build vpx"
echoDurationInSections "$START_TIME"

START_TIME="$(currentTimeInSeconds)"
echoSection "compile lame (mp3)"
"$SCRIPT_DIR/build-lame.sh" "$SCRIPT_DIR" "$BUILD_DIR" "$TOOL_DIR" "3.100" > "$BUILD_DIR/build-lame.log" 2>&1
checkStatus $? "build lame"
echoDurationInSections "$START_TIME"

START_TIME="$(currentTimeInSeconds)"
echoSection "compile opus"
"$SCRIPT_DIR/build-opus.sh" "$SCRIPT_DIR" "$BUILD_DIR" "$TOOL_DIR" "$CPUS" "v1.5.1" > "$BUILD_DIR/build-opus.log" 2>&1
checkStatus $? "build opus"
echoDurationInSections "$START_TIME"

START_TIME="$(currentTimeInSeconds)"
echoSection "compile fontconfig"
"$SCRIPT_DIR/build-fontconfig.sh" "$SCRIPT_DIR" "$BUILD_DIR" "$TOOL_DIR" "$CPUS" "xxx" > "$BUILD_DIR/build-fontconfig.log" 2>&1
checkStatus $? "build fontconfig"
echoDurationInSections "$START_TIME"

START_TIME="$(currentTimeInSeconds)"
echoSection "skip libbluray (disabled by FFbuilder wrapper)"
echoDurationInSections "$START_TIME"

START_TIME="$(currentTimeInSeconds)"
echoSection "compile libwebp"
"$SCRIPT_DIR/build-libwebp.sh" "$SCRIPT_DIR" "$BUILD_DIR" "$TOOL_DIR" "$CPUS" "xxx" > "$BUILD_DIR/build-libwebp.log" 2>&1
checkStatus $? "build libwebp"
echoDurationInSections "$START_TIME"

START_TIME="$(currentTimeInSeconds)"
echoSection "compile openssl"
"$SCRIPT_DIR/build-openssl.sh" "$SCRIPT_DIR" "$BUILD_DIR" "$TOOL_DIR" "$CPUS" "xxx" > "$BUILD_DIR/build-openssl.log" 2>&1
checkStatus $? "build openssl"
echoDurationInSections "$START_TIME"

START_TIME="$(currentTimeInSeconds)"
echoSection "compile libsrt"
"$SCRIPT_DIR/build-libsrt.sh" "$SCRIPT_DIR" "$BUILD_DIR" "$TOOL_DIR" "$CPUS" "xxx" > "$BUILD_DIR/build-libsrt.log" 2>&1
checkStatus $? "build srt"
echoDurationInSections "$START_TIME"

START_TIME="$(currentTimeInSeconds)"
echoSection "compile ffmpeg (libbluray disabled)"
(
    cd "$BUILD_DIR"
    rm -rf ffmpeg
    mkdir -p ffmpeg
    cd ffmpeg
    curl -O "https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.bz2"
    checkStatus $? "download of ffmpeg failed"
    bunzip2 "ffmpeg-${FFMPEG_VERSION}.tar.bz2"
    checkStatus $? "decompress ffmpeg failed"
    tar -xf "ffmpeg-${FFMPEG_VERSION}.tar"
    checkStatus $? "extract ffmpeg failed"
    cd "ffmpeg-${FFMPEG_VERSION}"

    FF_FLAGS="-L${TOOL_DIR}/lib -I${TOOL_DIR}/include"
    export LDFLAGS="$FF_FLAGS"
    export CFLAGS="$FF_FLAGS"

    ./configure --prefix="$OUT_DIR" --enable-gpl --pkg-config-flags="--static" --pkg-config="$TOOL_DIR/bin/pkg-config" \
        --enable-libaom --enable-libopenh264 --enable-libx264 --enable-libx265 --enable-libvpx \
        --enable-libmp3lame --enable-libopus --enable-neon --enable-runtime-cpudetect \
        --enable-audiotoolbox --enable-videotoolbox --enable-libvorbis \
        --enable-libsrt --enable-libwebp --disable-libbluray --enable-libsvtav1 \
        --enable-libass --enable-nonfree --enable-libfdk-aac --enable-opencl
    checkStatus $? "configuration of ffmpeg failed"
    make clean
    checkStatus $? "make clean for ffmpeg failed"
    make -j "$CPUS"
    checkStatus $? "build of ffmpeg failed"
    make install
    checkStatus $? "installation of ffmpeg failed"
) > "$BUILD_DIR/build-ffmpeg.log" 2>&1
echoDurationInSections "$START_TIME"

echo "compilation finished successfully"
echoDurationInSections "$COMPILATION_START_TIME"

echoSection "bundle result"
(
    cd "$OUT_DIR/bin/"
    checkStatus $? "change directory"
    zip -9 -r "$BUILD_DIR/ffmpeg-success.zip" *
)

echoSection "run tests"
"$TEST_DIR/test.sh" "$SCRIPT_DIR" "$TEST_DIR" "$BUILD_DIR" "$OUT_DIR" > "$BUILD_DIR/test.log" 2>&1
checkStatus $? "test"
echo "tests executed successfully"

mkdir -p "$OUTPUT_DIR"

if [[ -d "$BUILD_DIR/out" ]]; then
    rm -rf "$OUTPUT_DIR/out"
    cp -R "$BUILD_DIR/out" "$OUTPUT_DIR/out"
fi

echo "Artifacts written to: $OUTPUT_DIR"