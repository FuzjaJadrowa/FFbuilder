#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

DAVS2_REPO="${DAVS2_REPO:-https://github.com/pkuvcl/davs2.git}"
DAVS2_BRANCH="${DAVS2_BRANCH:-master}"

srcdir="$SRC/davs2"
ensure_clone "$srcdir" "$DAVS2_REPO"
git_checkout "$srcdir" "$DAVS2_BRANCH"

if [[ "$TARGET_INPUT" == "macos" ]]; then
    echo "Skipping davs2 on macOS: upstream build uses x86 toolchain assumptions." >&2
    exit 0
fi

buildroot="$srcdir/build/linux"
if [[ -x "$buildroot/configure" ]]; then
    cd "$buildroot"
    make distclean >/dev/null 2>&1 || true
    config_args=(
        --prefix="$PREFIX"
    )
    if [[ "$TARGET_INPUT" == "windows" ]]; then
        config_args+=(--host=x86_64-w64-mingw32)
    fi
    ./configure "${config_args[@]}"
    make -j"$NPROC"
    make install
else
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
    if [[ "$TARGET_INPUT" == "windows" ]]; then
        config_args+=(--host=x86_64-w64-mingw32)
    fi
    ./configure "${config_args[@]}"
    make -j"$NPROC"
    make install
fi

pc_file="$PREFIX/lib/pkgconfig/davs2.pc"
if [[ ! -f "$pc_file" ]]; then
    mkdir -p "$PREFIX/lib/pkgconfig"
    version="1.6.0"
    for f in "$srcdir/source/common/version.h" "$srcdir/source/version.h" "$srcdir/include/davs2.h" "$srcdir/davs2.h"; do
        if [[ -f "$f" ]]; then
            v="$(awk -F\" '/DAVS2_VERSION/ {print $2; exit}' "$f")"
            if [[ -n "${v:-}" ]]; then
                version="$v"
                break
            fi
        fi
    done
    libname="davs2"
    if [[ ! -f "$PREFIX/lib/libdavs2.a" && -f "$PREFIX/lib/libdavs2d.a" ]]; then
        libname="davs2d"
    fi
    includedir="$PREFIX/include"
    if [[ -f "$PREFIX/include/davs2/davs2.h" ]]; then
        includedir="$PREFIX/include/davs2"
    fi
    cat >"$pc_file" <<EOF
prefix=$PREFIX
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=$includedir

Name: davs2
Description: AVS2 decoder (davs2)
Version: $version
Libs: -L\${libdir} -l$libname
Cflags: -I\${includedir}
EOF
fi