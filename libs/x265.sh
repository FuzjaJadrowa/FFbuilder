#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT_DIR/common.sh"

require_env SRC BUILD PREFIX NPROC TARGET_INPUT

X265_REPO="${X265_REPO:-https://bitbucket.org/multicoreware/x265_git.git}"

fetch_repo "x265" "$X265_REPO"
src="$SRC/x265"
builddir="$BUILD/x265"
rm -rf "$builddir"

cmake_args=(
    -G "${CMAKE_GENERATOR:-Unix Makefiles}"
    -DCMAKE_INSTALL_PREFIX="$PREFIX"
    -DENABLE_SHARED=OFF
    -DENABLE_CLI=OFF
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON
)

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

cmake -S "$src/source" -B "$builddir" "${cmake_args[@]}"
cmake --build "$builddir" --parallel "$NPROC"
cmake --install "$builddir"