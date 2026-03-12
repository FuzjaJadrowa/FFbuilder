#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

FFTW3_VERSION="${FFTW3_VERSION:-3.3.10}"
FFTW3_URL="${FFTW3_URL:-https://www.fftw.org/fftw-${FFTW3_VERSION}.tar.gz}"

srcdir="$SRC/fftw-$FFTW3_VERSION"
tarball="$SRC/fftw-$FFTW3_VERSION.tar.gz"
ensure_tarball "$FFTW3_URL" "$tarball" "$srcdir"

cd "$srcdir"
make distclean >/dev/null 2>&1 || true

if [[ ! -x "./configure" ]]; then
    autotools_prepare
fi

config_args=(
    --prefix="$PREFIX"
    --disable-shared
    --enable-static
    --enable-threads
    --with-combined-threads
)

if [[ "$TARGET_INPUT" == "windows" ]]; then
    config_args+=(--host=x86_64-w64-mingw32)
fi

./configure "${config_args[@]}"
make -j"$NPROC"
make install