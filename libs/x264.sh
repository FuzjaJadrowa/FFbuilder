#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT_DIR/common.sh"

require_env SRC BUILD PREFIX NPROC TARGET_INPUT

X264_REPO="${X264_REPO:-https://code.videolan.org/videolan/x264.git}"

fetch_repo "x264" "$X264_REPO"
src="$SRC/x264"
ensure_configure "$src"

builddir="$BUILD/x264"
rm -rf "$builddir"
mkdir -p "$builddir"

cfg=(
    "$src/configure"
    --prefix="$PREFIX"
    --enable-static
    --disable-cli
    --disable-opencl
    --enable-pic
)

if [[ "$TARGET_INPUT" == "windows" ]]; then
    cfg+=(--host="$HOST_TRIPLET" --cross-prefix="$CROSS_PREFIX")
fi

(cd "$builddir" && CFLAGS="${COMMON_CFLAGS:-}" "${cfg[@]}")
make -C "$builddir" -j"$NPROC"
make -C "$builddir" install