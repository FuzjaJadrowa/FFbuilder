#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

if ! command -v meson >/dev/null 2>&1; then
    echo "Skipping libplacebo: missing meson." >&2
    exit 0
fi
if ! command -v ninja >/dev/null 2>&1; then
    echo "Skipping libplacebo: missing ninja." >&2
    exit 0
fi

LIBPLACEBO_VERSION="${LIBPLACEBO_VERSION:-6.338.2}"
LIBPLACEBO_URL="${LIBPLACEBO_URL:-https://github.com/haasn/libplacebo/archive/refs/tags/v${LIBPLACEBO_VERSION}.tar.gz}"

srcdir="$SRC/libplacebo-$LIBPLACEBO_VERSION"
tarball="$SRC/libplacebo-$LIBPLACEBO_VERSION.tar.gz"
ensure_tarball "$LIBPLACEBO_URL" "$tarball" "$srcdir" 1

builddir="$BUILD/libplacebo"
rm -rf "$builddir"
mkdir -p "$builddir"

meson_args=(
    "$builddir"
    "$srcdir"
    --prefix="$PREFIX"
    --libdir=lib
    --default-library=static
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