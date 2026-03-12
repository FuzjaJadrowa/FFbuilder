#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

FRIBIDI_VERSION="${FRIBIDI_VERSION:-1.0.13}"
FRIBIDI_URL="${FRIBIDI_URL:-https://github.com/fribidi/fribidi/releases/download/v${FRIBIDI_VERSION}/fribidi-${FRIBIDI_VERSION}.tar.xz}"

srcdir="$SRC/fribidi-$FRIBIDI_VERSION"
tarball="$SRC/fribidi-$FRIBIDI_VERSION.tar.xz"
ensure_tarball "$FRIBIDI_URL" "$tarball" "$srcdir"

builddir="$BUILD/fribidi"
rm -rf "$builddir"
mkdir -p "$builddir"

meson_args=(
    "$builddir"
    "$srcdir"
    --prefix="$PREFIX"
    --libdir=lib
    --default-library=static
    -Ddocs=false
    -Dtests=false
)

if is_cross_windows; then
    cross_file="$builddir/meson-cross.txt"
    cat >"$cross_file" <<EOF
[binaries]
c = '$CC'
cpp = '$CXX'
ar = '$AR'
strip = '$STRIP'
pkgconfig = 'pkg-config'

[host_machine]
system = 'windows'
cpu_family = 'x86_64'
cpu = 'x86_64'
endian = 'little'
EOF
    meson_args+=(--cross-file "$cross_file")
fi

meson setup "${meson_args[@]}"
meson compile -C "$builddir" -j "$NPROC"
meson install -C "$builddir"