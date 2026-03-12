#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

LIBUDFREAD_REPO="${LIBUDFREAD_REPO:-https://code.videolan.org/videolan/libudfread.git}"
LIBUDFREAD_BRANCH="${LIBUDFREAD_BRANCH:-master}"

srcdir="$SRC/libudfread"
ensure_clone "$srcdir" "$LIBUDFREAD_REPO"
git_checkout "$srcdir" "$LIBUDFREAD_BRANCH"

builddir="$BUILD/libudfread"
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
    -DBUILD_TESTING=OFF
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