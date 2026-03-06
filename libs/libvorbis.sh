#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

VORBIS_REPO="${VORBIS_REPO:-https://github.com/xiph/vorbis.git}"
VORBIS_BRANCH="${VORBIS_BRANCH:-master}"

srcdir="$SRC/vorbis"
ensure_clone "$srcdir" "$VORBIS_REPO"
git_checkout "$srcdir" "$VORBIS_BRANCH"

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
    --with-ogg="$PREFIX"
    --disable-oggtest
    --disable-vorbistest
    --disable-examples
    --disable-asm
    --disable-spec
)

if [[ "$TARGET_INPUT" == "windows" ]]; then
    config_args+=(--host=x86_64-w64-mingw32)
fi

./configure "${config_args[@]}"
make -j"$NPROC"
make install