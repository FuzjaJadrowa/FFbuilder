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
PATCH_SKIP_FONTCONFIG="${PATCH_SKIP_FONTCONFIG:-1}"

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

rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR" "$BUILD_DIR"

git clone --depth=1 --branch "$REPO_BRANCH" "$REPO_URL" "$CLONE_DIR"

patch_libbluray_libxml_path() {
    local libbluray_script="$CLONE_DIR/build/build-libbluray.sh"
    local patched_script="$CLONE_DIR/build/build-libbluray.sh.patched"

    awk '
      /LIBXML2_CFLAGS=.*\.\.\/\$\{SOFTWARE\}\/configure --prefix="\$3" --enable-shared=no --disable-bdjava-jar/ {
        print "  SDK_PATH=\"$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)\""
        print "  if [[ -n \"$SDK_PATH\" && -d \"$SDK_PATH/usr/include/libxml2\" ]]; then"
        print "    LIBXML2_CFLAGS=\"-I$SDK_PATH/usr/include/libxml2\" LIBXML2_LIBS=\"-lxml2\" ../${SOFTWARE}/configure --prefix=\"$3\" --enable-shared=no --disable-bdjava-jar"
        print "  else"
        print "    LIBXML2_CFLAGS=\"-I/usr/include/libxml2\" LIBXML2_LIBS=\"-lxml2\" ../${SOFTWARE}/configure --prefix=\"$3\" --enable-shared=no --disable-bdjava-jar"
        print "  fi"
        next
      }
      { print }
    ' "$libbluray_script" > "$patched_script"

    mv "$patched_script" "$libbluray_script"
    chmod +x "$libbluray_script"
}

patch_libbluray_libxml_path

if [[ "$PATCH_SKIP_FONTCONFIG" == "1" ]]; then
    # libass in this toolchain is configured with --disable-fontconfig and ffmpeg is
    # not built with --enable-libfontconfig, so fontconfig is not required.
    PATCHED_BUILD_SH="$CLONE_DIR/build.sh.patched"
    awk '
      /echoSection "compile fontconfig"/ {
        skip=1
        print "START_TIME=$(currentTimeInSeconds)"
        print "echoSection \"skip fontconfig (not required by FFbuilder)\""
        print "echo \"fontconfig step skipped by wrapper\""
        print "echoDurationInSections $START_TIME"
        next
      }
      skip && /echoDurationInSections \$START_TIME/ { skip=0; next }
      skip { next }
      { print }
    ' "$CLONE_DIR/build.sh" > "$PATCHED_BUILD_SH"
    mv "$PATCHED_BUILD_SH" "$CLONE_DIR/build.sh"
    chmod +x "$CLONE_DIR/build.sh"
fi

(
    cd "$BUILD_DIR"
    "$CLONE_DIR/build.sh"
)

mkdir -p "$OUTPUT_DIR"

if [[ -d "$BUILD_DIR/out" ]]; then
    rm -rf "$OUTPUT_DIR/out"
    cp -R "$BUILD_DIR/out" "$OUTPUT_DIR/out"
fi

echo "Artifacts written to: $OUTPUT_DIR"