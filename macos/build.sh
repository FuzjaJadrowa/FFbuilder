#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

OUTPUT_DIR="${OUTPUT_DIR:-$ROOT_DIR/artifacts}"
WORK_DIR="$(mktemp -d)"

cleanup() {
    rm -rf "$WORK_DIR"
}
trap cleanup EXIT

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || { echo "Missing required command: $1" >&2; exit 1; }
}

require_cmd curl
require_cmd unzip

MACOS_URL="${MACOS_URL:-https://github.com/Tyrrrz/FFmpegBin/releases/download/8.1/ffmpeg-osx-arm64.zip}"

echo "Downloading macOS ARM64 FFmpeg package from: $MACOS_URL"
curl -L -sS -f -o "$WORK_DIR/ffmpeg-macos.zip" "$MACOS_URL"

unzip -q "$WORK_DIR/ffmpeg-macos.zip" -d "$WORK_DIR/extracted"

ffmpeg_bin="$(find "$WORK_DIR/extracted" -type f -name 'ffmpeg' -print -quit)"

if [[ -z "$ffmpeg_bin" ]]; then
    echo "ffmpeg binary not found in downloaded archive" >&2
    exit 1
fi

mkdir -p "$OUTPUT_DIR/out/bin"
cp "$ffmpeg_bin" "$OUTPUT_DIR/out/bin/ffmpeg"
chmod +x "$OUTPUT_DIR/out/bin/ffmpeg"

echo "Artifacts written to: $OUTPUT_DIR"