#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

SOXR_VERSION="${SOXR_VERSION:-0.1.3}"
SOXR_URL="${SOXR_URL:-https://sourceforge.net/projects/soxr/files/soxr-${SOXR_VERSION}-Source.tar.xz/download}"

srcdir="$SRC/soxr-$SOXR_VERSION"
tarball="$SRC/soxr-$SOXR_VERSION.tar.xz"
ensure_tarball "$SOXR_URL" "$tarball" "$srcdir" 1

builddir="$BUILD/soxr"
rm -rf "$builddir"
mkdir -p "$builddir"

cmake_args=(
    -G "Ninja"
    -S "$srcdir"
    -B "$builddir"
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_INSTALL_PREFIX="$PREFIX"
    -DCMAKE_INSTALL_LIBDIR=lib
    -DBUILD_SHARED_LIBS=OFF
    -DBUILD_TESTS=OFF
    -DWITH_SIMD=ON
    -DCMAKE_C_COMPILER="$(tool_path "$CC")"
    -DCMAKE_CXX_COMPILER="$(tool_path "$CXX")"
    -DCMAKE_AR="$(tool_path "$AR")"
    -DCMAKE_RANLIB="$(tool_path "$RANLIB")"
)

if [[ "$TARGET_INPUT" == "windows" ]]; then
    cmake_args+=(-DCMAKE_SYSTEM_NAME=Windows)
fi

cmake "${cmake_args[@]}"
cmake --build "$builddir" --config Release -j "$NPROC"
cmake --install "$builddir"