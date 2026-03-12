#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

if ! command -v cmake >/dev/null 2>&1; then
    echo "Skipping davs2: missing cmake." >&2
    exit 0
fi

DAVS2_REPO="${DAVS2_REPO:-https://github.com/pkuvcl/davs2.git}"
DAVS2_BRANCH="${DAVS2_BRANCH:-master}"

srcdir="$SRC/davs2"
ensure_clone "$srcdir" "$DAVS2_REPO"
git_checkout "$srcdir" "$DAVS2_BRANCH"

if [[ ! -f "$srcdir/CMakeLists.txt" ]]; then
    echo "Skipping davs2: CMakeLists.txt not found." >&2
    exit 0
fi

builddir="$BUILD/davs2"
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