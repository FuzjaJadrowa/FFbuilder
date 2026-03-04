#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

SVTAV1_REPO="${SVTAV1_REPO:-https://gitlab.com/AOMediaCodec/SVT-AV1.git}"
SVTAV1_BRANCH="${SVTAV1_BRANCH:-master}"

srcdir="$SRC/SVT-AV1"
builddir="$BUILD/svtav1"
ensure_clone "$srcdir" "$SVTAV1_REPO"
git_checkout "$srcdir" "$SVTAV1_BRANCH"

rm -rf "$builddir"
mkdir -p "$builddir"

cmake_args=(
    -G "Ninja"
    -S "$srcdir"
    -B "$builddir"
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_INSTALL_PREFIX="$PREFIX"
    -DCMAKE_INSTALL_LIBDIR=lib
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON
    -DBUILD_SHARED_LIBS=OFF
    -DBUILD_TESTING=OFF
    -DENABLE_NASM=ON
    -DCMAKE_C_COMPILER="$CC"
    -DCMAKE_CXX_COMPILER="$CXX"
    -DCMAKE_AR="$AR"
    -DCMAKE_RANLIB="$RANLIB"
)

if [[ "$TARGET_INPUT" == "windows" ]]; then
    cmake_args+=(-DCMAKE_SYSTEM_NAME=Windows)
fi

cmake "${cmake_args[@]}"
cmake --build "$builddir" --config Release -j "$NPROC"
cmake --install "$builddir"