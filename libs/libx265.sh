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

pcfile="$PREFIX/lib/pkgconfig/x265.pc"
if [[ ! -f "$pcfile" ]]; then
    mkdir -p "$(dirname "$pcfile")"
    version="$(grep -E '^#define X265_VERSION' "$srcdir/source/x265.h" | awk '{print $3}' | tr -d '"')"
    if [[ -z "$version" ]]; then
        version="0.0"
    fi
    cat >"$pcfile" <<EOF
prefix=$PREFIX
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: x265
Description: H.265/HEVC encoder
Version: $version
Libs: -L\${libdir} -lx265
Cflags: -I\${includedir}
EOF
fi