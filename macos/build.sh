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