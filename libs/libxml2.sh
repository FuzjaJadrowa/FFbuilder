#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

LIBXML2_REPO="${LIBXML2_REPO:-https://gitlab.gnome.org/GNOME/libxml2.git}"
LIBXML2_BRANCH="${LIBXML2_BRANCH:-master}"

srcdir="$SRC/libxml2"
ensure_clone "$srcdir" "$LIBXML2_REPO"
git_checkout "$srcdir" "$LIBXML2_BRANCH"

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
    --without-python
    --without-lzma
    --without-zlib
    --with-iconv="$PREFIX"
)

if [[ "$TARGET_INPUT" == "windows" ]]; then
    config_args+=(--host=x86_64-w64-mingw32)
fi

./configure "${config_args[@]}"
make -j"$NPROC"
make install