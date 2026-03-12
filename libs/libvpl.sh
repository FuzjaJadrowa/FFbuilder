#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

if ! command -v cmake >/dev/null 2>&1; then
    echo "Skipping oneVPL: missing cmake." >&2
    exit 0
fi

LIBVPL_VERSION="${LIBVPL_VERSION:-2.10.1}"
LIBVPL_URL="${LIBVPL_URL:-https://github.com/oneapi-src/oneVPL/archive/refs/tags/v${LIBVPL_VERSION}.tar.gz}"

srcdir="$SRC/oneVPL-$LIBVPL_VERSION"
tarball="$SRC/oneVPL-$LIBVPL_VERSION.tar.gz"
ensure_tarball "$LIBVPL_URL" "$tarball" "$srcdir" 1

builddir="$BUILD/libvpl"
rm -rf "$builddir"
mkdir -p "$builddir"

cmake_args=(
    -S "$srcdir"
    -B "$builddir"
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_INSTALL_PREFIX="$PREFIX"
    -DCMAKE_INSTALL_LIBDIR=lib
    -DBUILD_SHARED_LIBS=OFF
    -DBUILD_TESTS=OFF
    -DBUILD_TOOLS=OFF
    -DCMAKE_C_COMPILER="$(tool_path "$CC")"
    -DCMAKE_CXX_COMPILER="$(tool_path "$CXX")"
    -DCMAKE_AR="$(tool_path "$AR")"
    -DCMAKE_RANLIB="$(tool_path "$RANLIB")"
)

if command -v ninja >/dev/null 2>&1; then
    cmake_args=(-G "Ninja" "${cmake_args[@]}")
fi

if [[ "$TARGET_INPUT" == "windows" ]]; then
    cmake_args+=(-DCMAKE_SYSTEM_NAME=Windows)
fi

cmake "${cmake_args[@]}"
cmake --build "$builddir" --config Release -j "$NPROC"
cmake --install "$builddir"