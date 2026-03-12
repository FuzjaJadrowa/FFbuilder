#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

HARFBUZZ_VERSION="${HARFBUZZ_VERSION:-8.5.0}"
HARFBUZZ_URL="${HARFBUZZ_URL:-https://github.com/harfbuzz/harfbuzz/releases/download/${HARFBUZZ_VERSION}/harfbuzz-${HARFBUZZ_VERSION}.tar.xz}"

srcdir="$SRC/harfbuzz-$HARFBUZZ_VERSION"
tarball="$SRC/harfbuzz-$HARFBUZZ_VERSION.tar.xz"
ensure_tarball "$HARFBUZZ_URL" "$tarball" "$srcdir"

builddir="$BUILD/harfbuzz"
rm -rf "$builddir"
mkdir -p "$builddir"

meson_args=(
    "$builddir"
    "$srcdir"
    --prefix="$PREFIX"
    --libdir=lib
    --default-library=static
    -Dtests=disabled
    -Ddocs=disabled
    -Dglib=disabled
    -Dgobject=disabled
    -Dicu=disabled
    -Dgraphite=disabled
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