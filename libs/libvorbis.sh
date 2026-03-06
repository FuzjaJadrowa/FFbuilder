#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

VORBIS_REPO="${VORBIS_REPO:-https://github.com/xiph/vorbis.git}"
VORBIS_BRANCH="${VORBIS_BRANCH:-master}"

srcdir="$SRC/vorbis"
ensure_clone "$srcdir" "$VORBIS_REPO"
git_checkout "$srcdir" "$VORBIS_BRANCH"

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
    --with-ogg="$PREFIX"
    --disable-oggtest
    --disable-examples
)

if [[ "$TARGET_INPUT" == "windows" ]]; then
    config_args+=(--host=x86_64-w64-mingw32)
fi

./configure "${config_args[@]}"
make -C lib -j"$NPROC" libvorbis.la libvorbisenc.la libvorbisfile.la

install -d "$PREFIX/lib" "$PREFIX/include/vorbis" "$PREFIX/lib/pkgconfig"

for lib in libvorbis libvorbisenc libvorbisfile; do
    if [[ -f "$srcdir/lib/.libs/${lib}.a" ]]; then
        install -c -m 644 "$srcdir/lib/.libs/${lib}.a" "$PREFIX/lib/"
    fi
done

install -c -m 644 "$srcdir/include/vorbis/"*.h "$PREFIX/include/vorbis/"
install -c -m 644 "$srcdir/vorbis.pc" "$PREFIX/lib/pkgconfig/"
install -c -m 644 "$srcdir/vorbisenc.pc" "$PREFIX/lib/pkgconfig/"
install -c -m 644 "$srcdir/vorbisfile.pc" "$PREFIX/lib/pkgconfig/"
