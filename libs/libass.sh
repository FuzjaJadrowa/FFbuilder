#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

LIBASS_VERSION="${LIBASS_VERSION:-0.17.1}"
LIBASS_URL="${LIBASS_URL:-https://github.com/libass/libass/releases/download/${LIBASS_VERSION}/libass-${LIBASS_VERSION}.tar.xz}"

srcdir="$SRC/libass-$LIBASS_VERSION"
tarball="$SRC/libass-$LIBASS_VERSION.tar.xz"
ensure_tarball "$LIBASS_URL" "$tarball" "$srcdir"

builddir="$BUILD/libass"
rm -rf "$builddir"
mkdir -p "$builddir"

meson_args=(
    "$builddir"
    "$srcdir"
    --prefix="$PREFIX"
    --libdir=lib
    --default-library=static
    -Dtest=false
    -Ddocs=false
)

if is_cross_windows; then
    cross_file="$builddir/meson-cross.txt"
    cat >"$cross_file" <<EOF
[binaries]
c = '$CC'
cpp = '$CXX'
ar = '$AR'
strip = '$STRIP'
windres = '${WINDRES:-x86_64-w64-mingw32-windres}'
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