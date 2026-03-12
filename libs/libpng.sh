#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

LIBPNG_VERSION="${LIBPNG_VERSION:-1.6.43}"
LIBPNG_URL="${LIBPNG_URL:-https://download.sourceforge.net/libpng/libpng-${LIBPNG_VERSION}.tar.gz}"

srcdir="$SRC/libpng-$LIBPNG_VERSION"
tarball="$SRC/libpng-$LIBPNG_VERSION.tar.gz"
ensure_tarball "$LIBPNG_URL" "$tarball" "$srcdir"

cd "$srcdir"
make distclean >/dev/null 2>&1 || true

if [[ ! -x "./configure" ]]; then
    autotools_prepare
fi

config_args=(
    --prefix="$PREFIX"
    --disable-shared
    --enable-static
    --with-zlib-prefix="$PREFIX"
)

if [[ "$TARGET_INPUT" == "windows" ]]; then
    config_args+=(--host=x86_64-w64-mingw32)
fi

./configure "${config_args[@]}"
make -j"$NPROC"
make install