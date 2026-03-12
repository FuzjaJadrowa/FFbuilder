#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

TWOLAME_VERSION="${TWOLAME_VERSION:-0.4.0}"
TWOLAME_URL="${TWOLAME_URL:-https://downloads.sourceforge.net/project/twolame/twolame/${TWOLAME_VERSION}/twolame-${TWOLAME_VERSION}.tar.gz}"

srcdir="$SRC/twolame-$TWOLAME_VERSION"
tarball="$SRC/twolame-$TWOLAME_VERSION.tar.gz"
ensure_tarball "$TWOLAME_URL" "$tarball" "$srcdir"

cd "$srcdir"
make distclean >/dev/null 2>&1 || true

if [[ ! -x "./configure" ]]; then
    autotools_prepare
fi

config_args=(
    --prefix="$PREFIX"
    --disable-shared
    --enable-static
    --disable-frontend
)

if [[ "$TARGET_INPUT" == "windows" ]]; then
    config_args+=(--host=x86_64-w64-mingw32)
fi

./configure "${config_args[@]}"
make -j"$NPROC"
make install