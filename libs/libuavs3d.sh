#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

if ! command -v cmake >/dev/null 2>&1; then
    echo "Skipping uavs3d: missing cmake." >&2
    exit 0
fi

UAVS3D_REPO="${UAVS3D_REPO:-https://github.com/uavs3/uavs3d.git}"
UAVS3D_BRANCH="${UAVS3D_BRANCH:-master}"

srcdir="$SRC/uavs3d"
ensure_clone "$srcdir" "$UAVS3D_REPO"
git_checkout "$srcdir" "$UAVS3D_BRANCH"

if [[ ! -f "$srcdir/CMakeLists.txt" ]]; then
    echo "Skipping uavs3d: CMakeLists.txt not found." >&2
    exit 0
fi

builddir="$BUILD/uavs3d"
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