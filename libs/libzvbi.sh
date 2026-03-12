#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

ZVBI_VERSION="${ZVBI_VERSION:-0.2.44}"
ZVBI_URL="${ZVBI_URL:-https://downloads.sourceforge.net/project/zapping/zvbi/${ZVBI_VERSION}/zvbi-${ZVBI_VERSION}.tar.bz2}"

srcdir="$SRC/zvbi-$ZVBI_VERSION"
tarball="$SRC/zvbi-$ZVBI_VERSION.tar.bz2"
ensure_tarball "$ZVBI_URL" "$tarball" "$srcdir"

cd "$srcdir"
make distclean >/dev/null 2>&1 || true

if [[ ! -x "./configure" ]]; then
    autotools_prepare
fi

config_args=(
    --prefix="$PREFIX"
    --disable-shared
    --enable-static
    --without-x
    --without-xv
    --without-gtk
)

if [[ "$TARGET_INPUT" == "windows" ]]; then
    config_args+=(--host=x86_64-w64-mingw32)
fi

./configure "${config_args[@]}"
make -j"$NPROC"
make install