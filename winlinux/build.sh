#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TARGETS="${TARGETS:-win64 linux64}"
OUTPUT_DIR="${OUTPUT_DIR:-$ROOT_DIR/artifacts}"

WIN64_URL="${WIN64_URL:-https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-n8.1-latest-win64-gpl-8.1.zip}"
LINUX64_URL="${LINUX64_URL:-https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-n8.1-latest-linux64-gpl-8.1.tar.xz}"

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || { echo "Missing required command: $1" >&2; exit 1; }
}

require_cmd curl

mkdir -p "$OUTPUT_DIR"

(
    IFS=$' \t\n'
    for tgt in $TARGETS; do
        case "$tgt" in
            win64)
                echo "Downloading Windows (win64) FFmpeg 8.1 package..."
                curl -L -sS -o "$OUTPUT_DIR/ffmpeg-n8.1-latest-win64-gpl-8.1.zip" "$WIN64_URL"
                ;;
            linux64)
                echo "Downloading Linux (linux64) FFmpeg 8.1 package..."
                curl -L -sS -o "$OUTPUT_DIR/ffmpeg-n8.1-latest-linux64-gpl-8.1.tar.xz" "$LINUX64_URL"
                ;;
            *)
                echo "Unknown target: $tgt" >&2
                exit 1
                ;;
        esac
    done
)

echo "Artifacts written to: $OUTPUT_DIR"