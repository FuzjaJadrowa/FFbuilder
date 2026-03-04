#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

DAV1D_REPO="${DAV1D_REPO:-https://code.videolan.org/videolan/dav1d.git}"
DAV1D_BRANCH="${DAV1D_BRANCH:-master}"

srcdir="$SRC/dav1d"
builddir="$BUILD/dav1d"
ensure_clone "$srcdir" "$DAV1D_REPO"
git_checkout "$srcdir" "$DAV1D_BRANCH"

rm -rf "$builddir"
mkdir -p "$builddir"

meson_args=(
    "$builddir"
    "$srcdir"
    --prefix="$PREFIX"
    --libdir=lib
    --default-library=static
    -Denable_tools=false
    -Denable_tests=false
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