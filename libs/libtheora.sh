#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

THEORA_REPO="${THEORA_REPO:-https://github.com/xiph/theora.git}"
THEORA_BRANCH="${THEORA_BRANCH:-master}"

srcdir="$SRC/theora"
ensure_clone "$srcdir" "$THEORA_REPO"
git_checkout "$srcdir" "$THEORA_BRANCH"

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
    --with-vorbis="$PREFIX"
    --disable-examples
    --disable-doc
)

if [[ "$TARGET_INPUT" == "windows" ]]; then
    config_args+=(--host=x86_64-w64-mingw32)
fi

./configure "${config_args[@]}"
make -j"$NPROC"
make install