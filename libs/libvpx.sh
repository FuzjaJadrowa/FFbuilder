#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

LIBVPX_REPO="${LIBVPX_REPO:-https://chromium.googlesource.com/webm/libvpx.git}"
LIBVPX_BRANCH="${LIBVPX_BRANCH:-main}"

srcdir="$SRC/libvpx"
ensure_clone "$srcdir" "$LIBVPX_REPO"
git_checkout "$srcdir" "$LIBVPX_BRANCH"

cd "$srcdir"
make distclean >/dev/null 2>&1 || true

config_args=(
    --prefix="$PREFIX"
    --disable-examples
    --disable-unit-tests
    --disable-tools
    --disable-docs
    --enable-vp9-highbitdepth
    --enable-static
    --disable-shared
)

if [[ -n "${LIBVPX_TARGET:-}" ]]; then
    config_args+=(--target="$LIBVPX_TARGET")
elif [[ "$TARGET_INPUT" == "windows" ]]; then
    config_args+=(--target="x86_64-win64-gcc")
fi

if [[ "$TARGET_INPUT" == "windows" ]]; then
    if is_cross_windows; then
        config_args+=(--cross-prefix="${CROSS_PREFIX:-x86_64-w64-mingw32-}")
    fi
else
    config_args+=(--enable-pic)
fi

./configure "${config_args[@]}"
make -j"$NPROC"
make install