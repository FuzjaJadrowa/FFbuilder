#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

LIBARIBB24_REPO="${LIBARIBB24_REPO:-https://github.com/nkoriyama/aribb24.git}"
LIBARIBB24_BRANCH="${LIBARIBB24_BRANCH:-master}"

srcdir="$SRC/aribb24"
ensure_clone "$srcdir" "$LIBARIBB24_REPO"
git_checkout "$srcdir" "$LIBARIBB24_BRANCH"

if [[ -f "$srcdir/CMakeLists.txt" ]]; then
    builddir="$BUILD/aribb24"
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
        -DBUILD_TESTING=OFF
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
else
    cd "$srcdir"
    make distclean >/dev/null 2>&1 || true
    if [[ ! -x "./configure" ]]; then
        autotools_prepare
    fi
    config_args=(
        --prefix="$PREFIX"
        --disable-shared
        --enable-static
    )
    if [[ "$TARGET_INPUT" == "windows" ]]; then
        config_args+=(--host=x86_64-w64-mingw32)
    fi
    ./configure "${config_args[@]}"
    make -j"$NPROC"
    make install
fi