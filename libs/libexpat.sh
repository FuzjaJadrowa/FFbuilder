#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

EXPAT_VERSION="${EXPAT_VERSION:-2.6.4}"
EXPAT_URL="${EXPAT_URL:-https://github.com/libexpat/libexpat/releases/download/R_${EXPAT_VERSION//./_}/expat-${EXPAT_VERSION}.tar.gz}"

srcdir="$SRC/expat-$EXPAT_VERSION"
tarball="$SRC/expat-$EXPAT_VERSION.tar.gz"
ensure_tarball "$EXPAT_URL" "$tarball" "$srcdir"

if [[ -x "$srcdir/configure" ]]; then
    cd "$srcdir"
    make distclean >/dev/null 2>&1 || true
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
else
    builddir="$BUILD/expat"
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
        -DEXPAT_BUILD_TESTS=OFF
        -DEXPAT_BUILD_EXAMPLES=OFF
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
fi