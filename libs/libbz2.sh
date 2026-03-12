#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

BZIP2_VERSION="${BZIP2_VERSION:-1.0.8}"
BZIP2_URL="${BZIP2_URL:-https://sourceware.org/pub/bzip2/bzip2-${BZIP2_VERSION}.tar.gz}"

srcdir="$SRC/bzip2-$BZIP2_VERSION"
tarball="$SRC/bzip2-$BZIP2_VERSION.tar.gz"
ensure_tarball "$BZIP2_URL" "$tarball" "$srcdir"

cd "$srcdir"
make clean >/dev/null 2>&1 || true

make -j"$NPROC" CC="$CC" AR="$AR" RANLIB="$RANLIB"
make install PREFIX="$PREFIX"