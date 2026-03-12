#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

ZLIB_VERSION="${ZLIB_VERSION:-1.3.1}"
ZLIB_URL="${ZLIB_URL:-https://zlib.net/zlib-${ZLIB_VERSION}.tar.gz}"

srcdir="$SRC/zlib-$ZLIB_VERSION"
tarball="$SRC/zlib-$ZLIB_VERSION.tar.gz"
ensure_tarball "$ZLIB_URL" "$tarball" "$srcdir"

cd "$srcdir"
make distclean >/dev/null 2>&1 || true

if [[ "$TARGET_INPUT" == "windows" ]]; then
    CHOST="${CHOST:-x86_64-w64-mingw32}" \
    CC="$CC" AR="$AR" RANLIB="$RANLIB" \
    ./configure --static --prefix="$PREFIX"
else
    CFLAGS="${CFLAGS:-} -fPIC" \
    ./configure --static --prefix="$PREFIX"
fi

make -j"$NPROC"
make install