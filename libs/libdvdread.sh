#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

LIBDVDREAD_REPO="${LIBDVDREAD_REPO:-https://code.videolan.org/videolan/libdvdread.git}"
LIBDVDREAD_BRANCH="${LIBDVDREAD_BRANCH:-master}"

srcdir="$SRC/libdvdread"
ensure_clone "$srcdir" "$LIBDVDREAD_REPO"
git_checkout "$srcdir" "$LIBDVDREAD_BRANCH"

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