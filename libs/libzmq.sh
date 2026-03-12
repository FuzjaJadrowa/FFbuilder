#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

if ! command -v cmake >/dev/null 2>&1; then
    echo "Skipping libzmq: missing cmake." >&2
    exit 0
fi

LIBZMQ_VERSION="${LIBZMQ_VERSION:-4.3.5}"
LIBZMQ_URL="${LIBZMQ_URL:-https://github.com/zeromq/libzmq/archive/refs/tags/v${LIBZMQ_VERSION}.tar.gz}"

srcdir="$SRC/libzmq-$LIBZMQ_VERSION"
tarball="$SRC/libzmq-$LIBZMQ_VERSION.tar.gz"
ensure_tarball "$LIBZMQ_URL" "$tarball" "$srcdir" 1

builddir="$BUILD/libzmq"
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
    -DWITH_LIBSODIUM=OFF
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