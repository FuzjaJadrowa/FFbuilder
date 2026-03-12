#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

LIBVMAF_VERSION="${LIBVMAF_VERSION:-3.0.0}"
LIBVMAF_URL="${LIBVMAF_URL:-https://github.com/Netflix/vmaf/archive/refs/tags/v${LIBVMAF_VERSION}.tar.gz}"

srcroot="$SRC/vmaf-$LIBVMAF_VERSION"
tarball="$SRC/vmaf-$LIBVMAF_VERSION.tar.gz"
ensure_tarball "$LIBVMAF_URL" "$tarball" "$srcroot" 1

srcdir="$srcroot/libvmaf"
builddir="$BUILD/vmaf"
rm -rf "$builddir"
mkdir -p "$builddir"

meson_args=(
    "$builddir"
    "$srcdir"
    --prefix="$PREFIX"
    --libdir=lib
    --default-library=static
    -Denable_tests=false
    -Denable_docs=false
    -Denable_examples=false
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
