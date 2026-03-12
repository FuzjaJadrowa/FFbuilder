#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

GMP_VERSION="${GMP_VERSION:-6.3.0}"
GMP_URL="${GMP_URL:-https://ftp.gnu.org/gnu/gmp/gmp-${GMP_VERSION}.tar.xz}"

srcdir="$SRC/gmp-$GMP_VERSION"
tarball="$SRC/gmp-$GMP_VERSION.tar.xz"
ensure_tarball "$GMP_URL" "$tarball" "$srcdir"

cd "$srcdir"
make distclean >/dev/null 2>&1 || true

if [[ ! -x "./configure" ]]; then
    autotools_prepare
fi

config_args=(
    --prefix="$PREFIX"
    --disable-shared
    --enable-static
)

if [[ "$TARGET_INPUT" == "windows" ]]; then
    config_args+=(--host=x86_64-w64-mingw32 --disable-assembly)
fi

./configure "${config_args[@]}"
make -j"$NPROC"
make install
