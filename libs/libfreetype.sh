#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

FREETYPE_VERSION="${FREETYPE_VERSION:-2.13.2}"
FREETYPE_URL="${FREETYPE_URL:-https://download.savannah.gnu.org/releases/freetype/freetype-${FREETYPE_VERSION}.tar.gz}"

srcdir="$SRC/freetype-$FREETYPE_VERSION"
tarball="$SRC/freetype-$FREETYPE_VERSION.tar.gz"
ensure_tarball "$FREETYPE_URL" "$tarball" "$srcdir"

cd "$srcdir"
make distclean >/dev/null 2>&1 || true

if [[ ! -x "./configure" ]]; then
    autotools_prepare
fi

config_args=(
    --prefix="$PREFIX"
    --disable-shared
    --enable-static
    --with-zlib=yes
    --with-png=yes
    --with-bzip2=no
    --with-brotli=no
)

if [[ "$TARGET_INPUT" == "windows" ]]; then
    config_args+=(--host=x86_64-w64-mingw32)
fi

./configure "${config_args[@]}"
make -j"$NPROC"
make install