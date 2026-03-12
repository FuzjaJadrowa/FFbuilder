#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

SRT_VERSION="${SRT_VERSION:-1.5.3}"
SRT_URL="${SRT_URL:-https://github.com/Haivision/srt/archive/refs/tags/v${SRT_VERSION}.tar.gz}"

srcdir="$SRC/srt-$SRT_VERSION"
tarball="$SRC/srt-$SRT_VERSION.tar.gz"
ensure_tarball "$SRT_URL" "$tarball" "$srcdir" 1

builddir="$BUILD/srt"
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
    -DENABLE_APPS=OFF
    -DENABLE_TESTING=OFF
    -DENABLE_UNITTESTS=OFF
    -DENABLE_ENCRYPTION=ON
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