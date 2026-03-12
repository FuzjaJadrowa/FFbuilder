#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

LIBDVDCSS_REPO="${LIBDVDCSS_REPO:-https://code.videolan.org/videolan/libdvdcss.git}"
LIBDVDCSS_BRANCH="${LIBDVDCSS_BRANCH:-master}"

srcdir="$SRC/libdvdcss"
ensure_clone "$srcdir" "$LIBDVDCSS_REPO"
git_checkout "$srcdir" "$LIBDVDCSS_BRANCH"

cd "$srcdir"
make distclean >/dev/null 2>&1 || true

if [[ ! -x "./configure" ]]; then
    if [[ -x "./bootstrap" ]]; then
        ./bootstrap
    else
        autotools_prepare
    fi
fi

config_args=(
    --prefix="$PREFIX"
    --disable-shared
    --enable-static
)

if [[ "$TARGET_INPUT" == "windows" ]]; then
    config_args+=(--host=x86_64-w64-mingw32)
fi

./configure "${config_args[@]}"
make -j"$NPROC"
make install