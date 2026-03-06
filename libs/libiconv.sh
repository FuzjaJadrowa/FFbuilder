#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

ICONV_REPO="${ICONV_REPO:-https://git.savannah.gnu.org/git/libiconv.git}"
ICONV_BRANCH="${ICONV_BRANCH:-master}"

srcdir="$SRC/libiconv"
ensure_clone "$srcdir" "$ICONV_REPO"
git_checkout "$srcdir" "$ICONV_BRANCH"

cd "$srcdir"
make distclean >/dev/null 2>&1 || true

if [[ ! -x "./configure" ]]; then
    if [[ -x "./gitsub.sh" ]]; then
        ./gitsub.sh pull
    fi
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