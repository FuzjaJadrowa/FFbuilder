#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

FONTCONFIG_VERSION="${FONTCONFIG_VERSION:-2.15.0}"
FONTCONFIG_URL="${FONTCONFIG_URL:-https://www.freedesktop.org/software/fontconfig/release/fontconfig-${FONTCONFIG_VERSION}.tar.gz}"

srcdir="$SRC/fontconfig-$FONTCONFIG_VERSION"
tarball="$SRC/fontconfig-$FONTCONFIG_VERSION.tar.gz"
ensure_tarball "$FONTCONFIG_URL" "$tarball" "$srcdir"

cd "$srcdir"
make distclean >/dev/null 2>&1 || true

if [[ ! -x "./configure" ]]; then
    autotools_prepare
fi

config_args=(
    --prefix="$PREFIX"
    --disable-shared
    --enable-static
    --with-expat="$PREFIX"
    --with-iconv="$PREFIX"
)

if [[ -x "$PREFIX/bin/freetype-config" ]]; then
    config_args+=(--with-freetype-config="$PREFIX/bin/freetype-config")
fi

if [[ "$TARGET_INPUT" == "windows" ]]; then
    config_args+=(--host=x86_64-w64-mingw32)
fi

./configure "${config_args[@]}"
make -j"$NPROC"
make install