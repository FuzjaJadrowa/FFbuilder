#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

X265_REPO="${X265_REPO:-https://bitbucket.org/multicoreware/x265_git.git}"
X265_BRANCH="${X265_BRANCH:-master}"

srcdir="$SRC/x265"
builddir="$BUILD/x265"
ensure_clone "$srcdir" "$X265_REPO"
git_checkout "$srcdir" "$X265_BRANCH"

rm -rf "$builddir"
mkdir -p "$builddir"

cmake_args=(
    -G "Ninja"
    -S "$srcdir/source"
    -B "$builddir"
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_INSTALL_PREFIX="$PREFIX"
    -DCMAKE_INSTALL_LIBDIR=lib
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON
    -DENABLE_SHARED=OFF
    -DENABLE_CLI=OFF
    -DENABLE_PIC=ON
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