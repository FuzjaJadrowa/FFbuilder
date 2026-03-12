#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

GME_VERSION="${GME_VERSION:-0.6.3}"
GME_URL="${GME_URL:-https://github.com/libgme/game-music-emu/archive/refs/tags/${GME_VERSION}.tar.gz}"

srcdir="$SRC/game-music-emu-$GME_VERSION"
tarball="$SRC/game-music-emu-$GME_VERSION.tar.gz"
ensure_tarball "$GME_URL" "$tarball" "$srcdir" 1

builddir="$BUILD/gme"
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