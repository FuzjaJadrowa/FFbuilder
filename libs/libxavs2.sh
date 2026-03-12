#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

if ! command -v cmake >/dev/null 2>&1; then
    echo "Skipping xavs2: missing cmake." >&2
    exit 0
fi

XAVS2_REPO="${XAVS2_REPO:-https://github.com/pkuvcl/xavs2.git}"
XAVS2_BRANCH="${XAVS2_BRANCH:-master}"

srcdir="$SRC/xavs2"
ensure_clone "$srcdir" "$XAVS2_REPO"
git_checkout "$srcdir" "$XAVS2_BRANCH"

if [[ ! -f "$srcdir/CMakeLists.txt" ]]; then
    echo "Skipping xavs2: CMakeLists.txt not found." >&2
    exit 0
fi

builddir="$BUILD/xavs2"
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