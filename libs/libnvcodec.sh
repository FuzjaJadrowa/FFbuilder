#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

NV_CODEC_HEADERS_REPO="${NV_CODEC_HEADERS_REPO:-https://github.com/FFmpeg/nv-codec-headers.git}"
NV_CODEC_HEADERS_BRANCH="${NV_CODEC_HEADERS_BRANCH:-master}"

if [[ "$TARGET_INPUT" == "macos" ]]; then
    echo "Skipping nv-codec-headers on macOS: NVIDIA drivers are not supported." >&2
    exit 0
fi

srcdir="$SRC/nv-codec-headers"
ensure_clone "$srcdir" "$NV_CODEC_HEADERS_REPO"
git_checkout "$srcdir" "$NV_CODEC_HEADERS_BRANCH"

make -C "$srcdir" PREFIX="$PREFIX" install
