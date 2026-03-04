#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT_DIR/common.sh"

require_env SRC BUILD PREFIX NPROC TARGET_INPUT

VPX_REPO="${VPX_REPO:-https://chromium.googlesource.com/webm/libvpx}"

fetch_repo "libvpx" "$VPX_REPO"
src="$SRC/libvpx"
builddir="$BUILD/libvpx"
rm -rf "$builddir"
mkdir -p "$builddir"

cfg=(
    "$src/configure"
    --prefix="$PREFIX"
    --disable-examples
    --disable-unit-tests
    --enable-vp9-highbitdepth
    --disable-shared
    --enable-static
    --as=yasm
)

if [[ "$TARGET_INPUT" == "windows" ]]; then
    cfg+=(--target=x86_64-win64-gcc --cross-prefix="$CROSS_PREFIX")
fi

(cd "$builddir" && CFLAGS="${COMMON_CFLAGS:-}" "${cfg[@]}")
make -C "$builddir" -j"$NPROC"
make -C "$builddir" install