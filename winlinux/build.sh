#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

REPO_URL="${REPO_URL:-https://github.com/BtbN/FFmpeg-Builds.git}"
REPO_BRANCH="${REPO_BRANCH:-master}"
TARGETS="${TARGETS:-win64 linux64}"

WORK_DIR="${WORK_DIR:-$ROOT_DIR/.btbn-work}"
CLONE_DIR="${CLONE_DIR:-$WORK_DIR/FFmpeg-Builds}"
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
require_cmd docker

rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"

git clone --depth=1 --branch "$REPO_BRANCH" "$REPO_URL" "$CLONE_DIR"

export DOCKER_BUILDKIT=1

build_one() {
    local target="$1"
    local variant="$2"
    local addin="$3"
    (
        cd "$CLONE_DIR"
        ./makeimage.sh "$target" "$variant" "$addin"
        ./build.sh "$target" "$variant" "$addin"
    )
}

# Build only the requested variants:
# - n8.0-latest-win64-gpl-8.0
# - n8.0-latest-linux64-gpl-8.0
for tgt in $TARGETS; do
    build_one "$tgt" gpl 8.0
done

LATEST_DIR="$WORK_DIR/latest_artifacts"
mkdir -p "$LATEST_DIR"

(
    cd "$CLONE_DIR"
    shopt -s nullglob
    ./util/repack_latest.sh "$LATEST_DIR" artifacts/*.{zip,tar.xz}
)

# Rename to keep the "n8.0-latest" prefix if repack_latest removed it.
shopt -s nullglob
for f in "$LATEST_DIR"/ffmpeg-8.0-latest-*; do
    mv "$f" "${f/ffmpeg-8.0-latest-/ffmpeg-n8.0-latest-}"
done

mkdir -p "$OUTPUT_DIR"
cp -f "$LATEST_DIR"/* "$OUTPUT_DIR"/

echo "Artifacts written to: $OUTPUT_DIR"