#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

ICONV_SOURCE="${ICONV_SOURCE:-tarball}"
ICONV_REPO="${ICONV_REPO:-https://git.savannah.gnu.org/git/libiconv.git}"
ICONV_BRANCH="${ICONV_BRANCH:-master}"
ICONV_VERSION="${ICONV_VERSION:-1.18}"
ICONV_URL="${ICONV_URL:-https://ftp.gnu.org/gnu/libiconv/libiconv-${ICONV_VERSION}.tar.gz}"

if [[ "$ICONV_SOURCE" == "git" ]]; then
    srcdir="$SRC/libiconv"
    ensure_clone "$srcdir" "$ICONV_REPO"
    git_checkout "$srcdir" "$ICONV_BRANCH"
else
    srcdir="$SRC/libiconv-$ICONV_VERSION"
    tarball="$SRC/libiconv-$ICONV_VERSION.tar.gz"
    if [[ ! -d "$srcdir" ]]; then
        mkdir -p "$SRC"
        if [[ ! -f "$tarball" ]]; then
            if command -v curl >/dev/null 2>&1; then
                curl -L -o "$tarball" "$ICONV_URL"
            elif command -v wget >/dev/null 2>&1; then
                wget -O "$tarball" "$ICONV_URL"
            else
                echo "Missing curl/wget to download $ICONV_URL" >&2
                exit 1
            fi
        fi
        tar -xf "$tarball" -C "$SRC"
    fi
fi

cd "$srcdir"
make distclean >/dev/null 2>&1 || true

if [[ ! -x "./configure" ]]; then
    if [[ -x "./gitsub.sh" ]]; then
        ./gitsub.sh pull
    fi
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

if [[ "$TARGET_INPUT" == "windows" ]]; then
    config_args+=(--host=x86_64-w64-mingw32)
fi

./configure "${config_args[@]}"
GROFF="${GROFF:-:}" MAKEINFO="${MAKEINFO:-:}" make -j"$NPROC"
make install