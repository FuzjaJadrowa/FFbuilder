#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

LIBSSH_VERSION="${LIBSSH_VERSION:-0.11.0}"
LIBSSH_URL="${LIBSSH_URL:-https://www.libssh.org/files/0.11/libssh-${LIBSSH_VERSION}.tar.xz}"

srcdir="$SRC/libssh-$LIBSSH_VERSION"
tarball="$SRC/libssh-$LIBSSH_VERSION.tar.xz"
ensure_tarball "$LIBSSH_URL" "$tarball" "$srcdir"

builddir="$BUILD/libssh"
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
    -DWITH_EXAMPLES=OFF
    -DWITH_TESTING=OFF
    -DWITH_SERVER=OFF
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