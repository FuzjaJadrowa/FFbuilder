#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

XAVS2_REPO="${XAVS2_REPO:-https://github.com/pkuvcl/xavs2.git}"
XAVS2_BRANCH="${XAVS2_BRANCH:-master}"

srcdir="$SRC/xavs2"
ensure_clone "$srcdir" "$XAVS2_REPO"
git_checkout "$srcdir" "$XAVS2_BRANCH"

if [[ "$TARGET_INPUT" == "macos" ]]; then
    echo "Skipping xavs2 on macOS: upstream build uses x86 toolchain assumptions." >&2
    exit 0
fi

if [[ "$TARGET_INPUT" == "windows" ]]; then
    export CFLAGS="${CFLAGS:-} -Wno-error=incompatible-pointer-types"
fi

buildroot="$srcdir/build/linux"
if [[ -x "$buildroot/configure" ]]; then
    cd "$buildroot"
    make distclean >/dev/null 2>&1 || true
    config_args=(
        --prefix="$PREFIX"
    )
    if [[ "$TARGET_INPUT" == "windows" ]]; then
        config_args+=(--host=x86_64-w64-mingw32)
    fi
    ./configure "${config_args[@]}"
    make -j"$NPROC"
    make install
else
    cd "$srcdir"
    make distclean >/dev/null 2>&1 || true
    if [[ ! -x "./configure" ]]; then
        if [[ -x "./autogen.sh" ]]; then
            NOCONFIGURE=1 ./autogen.sh
        elif [[ -f "configure.ac" || -f "configure.in" ]]; then
            autoreconf -fiv
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
fi