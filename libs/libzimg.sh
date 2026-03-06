#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

ZIMG_SOURCE="${ZIMG_SOURCE:-tarball}"
ZIMG_REPO="${ZIMG_REPO:-https://github.com/sekrit-twc/zimg.git}"
ZIMG_BRANCH="${ZIMG_BRANCH:-master}"
ZIMG_VERSION="${ZIMG_VERSION:-3.0.5}"
ZIMG_URL="${ZIMG_URL:-https://github.com/sekrit-twc/zimg/archive/refs/tags/release-${ZIMG_VERSION}.tar.gz}"

if [[ "$ZIMG_SOURCE" == "git" ]]; then
    srcdir="$SRC/zimg"
    ensure_clone "$srcdir" "$ZIMG_REPO"
    git_checkout "$srcdir" "$ZIMG_BRANCH"
    git -C "$srcdir" submodule update --init --recursive
else
    srcdir="$SRC/zimg-release-$ZIMG_VERSION"
    tarball="$SRC/zimg-release-$ZIMG_VERSION.tar.gz"
    if [[ ! -d "$srcdir" ]]; then
        mkdir -p "$SRC"
        if [[ ! -f "$tarball" ]]; then
            if command -v curl >/dev/null 2>&1; then
                curl -L -o "$tarball" "$ZIMG_URL"
            elif command -v wget >/dev/null 2>&1; then
                wget -O "$tarball" "$ZIMG_URL"
            else
                echo "Missing curl/wget to download $ZIMG_URL" >&2
                exit 1
            fi
        fi
        tar -xf "$tarball" -C "$SRC"
    fi
fi

cd "$srcdir"
make distclean >/dev/null 2>&1 || true

if [[ ! -x "./configure" ]]; then
    if [[ -x "./autogen.sh" ]]; then
        NOCONFIGURE=1 ./autogen.sh
    elif [[ -f "configure.ac" || -f "configure.in" ]]; then
        autoreconf -fiv
    fi
fi

config_args=(
    --prefix="$PREFIX"
    --disable-shared
    --enable-static
)

if [[ "$TARGET_INPUT" != "windows" ]]; then
    config_args+=(--with-pic)
fi

if [[ "$TARGET_INPUT" == "windows" ]]; then
    config_args+=(--host=x86_64-w64-mingw32)
fi

./configure "${config_args[@]}"
make -j"$NPROC"
make install