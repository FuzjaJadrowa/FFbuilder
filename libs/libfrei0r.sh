#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

FREI0R_REPO="${FREI0R_REPO:-https://github.com/dyne/frei0r.git}"
FREI0R_BRANCH="${FREI0R_BRANCH:-master}"

srcdir="$SRC/frei0r"
ensure_clone "$srcdir" "$FREI0R_REPO"
git_checkout "$srcdir" "$FREI0R_BRANCH"

cd "$srcdir"
make distclean >/dev/null 2>&1 || true

if [[ ! -x "./configure" ]]; then
    if [[ -x "./autogen.sh" ]]; then
        NOCONFIGURE=1 ./autogen.sh
    else
        autotools_prepare
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

if [[ ! -f "$PREFIX/lib/pkgconfig/frei0r.pc" ]]; then
    mkdir -p "$PREFIX/lib/pkgconfig"
    cat >"$PREFIX/lib/pkgconfig/frei0r.pc" <<EOF
prefix=$PREFIX
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: frei0r
Description: frei0r plugin API
Version: 0.0.0
Cflags: -I\${includedir}
EOF
fi