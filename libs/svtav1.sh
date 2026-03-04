#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT_DIR/common.sh"

require_env SRC BUILD PREFIX NPROC TARGET_INPUT

SVTAV1_REPO="${SVTAV1_REPO:-https://github.com/AOMediaCodec/SVT-AV1.git}"

fetch_repo "svt-av1" "$SVTAV1_REPO"
src="$SRC/svt-av1"
builddir="$BUILD/svt-av1"
rm -rf "$builddir"

cmake_args=(
    -G "${CMAKE_GENERATOR:-Unix Makefiles}"
    -DCMAKE_INSTALL_PREFIX="$PREFIX"
    -DBUILD_SHARED_LIBS=OFF
    -DBUILD_APPS=OFF
    -DBUILD_TESTING=OFF
)

if command -v nasm >/dev/null 2>&1; then
    cmake_args+=(-DENABLE_NASM=ON)
fi

if [[ "${IS_CROSS_WINDOWS:-0}" == "1" ]]; then
    cmake_args+=(
        -DCMAKE_SYSTEM_NAME=Windows
        -DCMAKE_C_COMPILER="$CC"
        -DCMAKE_CXX_COMPILER="$CXX"
    )
    if command -v "${CROSS_PREFIX}windres" >/dev/null 2>&1; then
        cmake_args+=(-DCMAKE_RC_COMPILER="${CROSS_PREFIX}windres")
    fi
fi

cmake -S "$src" -B "$builddir" "${cmake_args[@]}"
cmake --build "$builddir" --parallel "$NPROC"
cmake --install "$builddir"