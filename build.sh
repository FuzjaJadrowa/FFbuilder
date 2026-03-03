#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TARGET_INPUT="${1:-}"
if [[ -z "$TARGET_INPUT" ]]; then
    case "$(uname -s)" in
        Linux) TARGET_INPUT="linux" ;;
        Darwin) TARGET_INPUT="macos" ;;
        MINGW*|MSYS*|CYGWIN*) TARGET_INPUT="windows" ;;
        *) echo "Unknown host OS. Pass target: linux|macos|windows" >&2; exit 1 ;;
    esac
fi

lower() {
    printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

TARGET_INPUT="$(lower "$TARGET_INPUT")"
case "$TARGET_INPUT" in
    linux|macos|windows) ;;
    *) echo "Usage: $0 <linux|macos|windows>" >&2; exit 1 ;;
esac

FFMPEG_REPO="${FFMPEG_REPO:-https://github.com/FFmpeg/FFmpeg.git}"
FFMPEG_BRANCH="${FFMPEG_BRANCH:-release/8.0}"

WORK="${WORKDIR:-$ROOT/ffbuild}"
SRC="$WORK/src"
BUILD="$WORK/build"
PREFIX="$WORK/prefix"
ARTIFACTS="${ARTIFACTS:-$ROOT/artifacts}"

mkdir -p "$SRC" "$BUILD" "$PREFIX" "$ARTIFACTS"

DEPS_SRC="$SRC/deps"
DEPS_BUILD="$BUILD/deps"
mkdir -p "$DEPS_SRC" "$DEPS_BUILD"

append_flag() {
    local var="$1"
    local val="$2"
    local cur
    cur="$(eval "printf '%s' \"\${$var:-}\"")"
    if [[ -n "$cur" ]]; then
        eval "export $var=\"${cur} ${val}\""
    else
        eval "export $var=\"${val}\""
    fi
}

append_flag CFLAGS "-I$PREFIX/include"
append_flag CPPFLAGS "-I$PREFIX/include"
append_flag LDFLAGS "-L$PREFIX/lib"
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PREFIX/lib64/pkgconfig:${PKG_CONFIG_PATH:-}"

resolve_tool() {
    local t="$1"
    if [[ -z "$t" ]]; then
        return 1
    fi
    if command -v "$t" >/dev/null 2>&1; then
        command -v "$t"
        return 0
    fi
    return 1
}

detect_nproc() {
    if command -v nproc >/dev/null 2>&1; then
        nproc
        return
    fi
    if command -v getconf >/dev/null 2>&1; then
        getconf _NPROCESSORS_ONLN
        return
    fi
    if command -v sysctl >/dev/null 2>&1; then
        sysctl -n hw.ncpu
        return
    fi
    echo 2
}

NPROC="$(detect_nproc)"

set_toolchain() {
    local arch
    arch="$(uname -m)"
    if [[ "$arch" == "arm64" ]]; then
        arch="aarch64"
    fi

    case "$TARGET_INPUT" in
        linux)
            export CC="${CC:-gcc}"
            export CXX="${CXX:-g++}"
            export AR="${AR:-ar}"
            export RANLIB="${RANLIB:-ranlib}"
            export NM="${NM:-nm}"
            export STRIP="${STRIP:-strip}"
            FFMPEG_TARGET_FLAGS="--target-os=linux --arch=$arch"
            ;;
        macos)
            export CC="${CC:-clang}"
            export CXX="${CXX:-clang++}"
            export AR="${AR:-ar}"
            export RANLIB="${RANLIB:-ranlib}"
            export NM="${NM:-nm}"
            export STRIP="${STRIP:-strip}"
            FFMPEG_TARGET_FLAGS="--target-os=darwin --arch=$arch"
            ;;
        windows)
            export CC="${CC:-x86_64-w64-mingw32-gcc}"
            export CXX="${CXX:-x86_64-w64-mingw32-g++}"
            if [[ -z "${AR:-}" ]]; then
                if command -v x86_64-w64-mingw32-ar >/dev/null 2>&1; then
                    export AR="x86_64-w64-mingw32-ar"
                elif command -v x86_64-w64-mingw32-gcc-ar >/dev/null 2>&1; then
                    export AR="x86_64-w64-mingw32-gcc-ar"
                elif command -v gcc-ar >/dev/null 2>&1; then
                    export AR="gcc-ar"
                else
                    echo "Missing MinGW ar (x86_64-w64-mingw32-ar). Install mingw-w64 binutils or set AR." >&2
                    exit 1
                fi
            fi
            if [[ -z "${RANLIB:-}" ]]; then
                if command -v x86_64-w64-mingw32-ranlib >/dev/null 2>&1; then
                    export RANLIB="x86_64-w64-mingw32-ranlib"
                elif command -v x86_64-w64-mingw32-gcc-ranlib >/dev/null 2>&1; then
                    export RANLIB="x86_64-w64-mingw32-gcc-ranlib"
                elif command -v gcc-ranlib >/dev/null 2>&1; then
                    export RANLIB="gcc-ranlib"
                else
                    echo "Missing MinGW ranlib (x86_64-w64-mingw32-ranlib). Install mingw-w64 binutils or set RANLIB." >&2
                    exit 1
                fi
            fi
            if [[ -z "${NM:-}" ]]; then
                if command -v x86_64-w64-mingw32-nm >/dev/null 2>&1; then
                    export NM="x86_64-w64-mingw32-nm"
                elif command -v x86_64-w64-mingw32-gcc-nm >/dev/null 2>&1; then
                    export NM="x86_64-w64-mingw32-gcc-nm"
                elif command -v gcc-nm >/dev/null 2>&1; then
                    export NM="gcc-nm"
                elif command -v nm >/dev/null 2>&1; then
                    export NM="nm"
                else
                    echo "Missing nm. Install mingw-w64 binutils or set NM." >&2
                    exit 1
                fi
            fi
            if [[ -z "${STRIP:-}" ]]; then
                if command -v x86_64-w64-mingw32-strip >/dev/null 2>&1; then
                    export STRIP="x86_64-w64-mingw32-strip"
                elif command -v x86_64-w64-mingw32-gcc-strip >/dev/null 2>&1; then
                    export STRIP="x86_64-w64-mingw32-gcc-strip"
                elif command -v gcc-strip >/dev/null 2>&1; then
                    export STRIP="gcc-strip"
                elif command -v strip >/dev/null 2>&1; then
                    export STRIP="strip"
                else
                    export STRIP=":"
                    FFMPEG_DISABLE_STRIPPING=1
                fi
            fi
            if [[ -z "${STRINGS:-}" ]]; then
                if command -v x86_64-w64-mingw32-strings >/dev/null 2>&1; then
                    export STRINGS="x86_64-w64-mingw32-strings"
                elif command -v strings >/dev/null 2>&1; then
                    export STRINGS="strings"
                fi
            fi
            CROSS_PREFIX="${CROSS_PREFIX:-x86_64-w64-mingw32-}"
            FFMPEG_TARGET_FLAGS="--target-os=mingw32 --arch=x86_64 --enable-cross-compile --cross-prefix=$CROSS_PREFIX"
            ;;
    esac
}

set_toolchain

FFMPEG_FLAGS=(
    --prefix="$PREFIX"
    --pkg-config-flags=--static
    --disable-shared
    --enable-static
    --enable-gpl
    --enable-nonfree
    --disable-debug
    --disable-doc
    --disable-programs
    --enable-ffmpeg
    --enable-ffprobe
    --disable-autodetect
    --enable-libx264
    --enable-libx265
    --enable-libvpx
    --enable-libsvtav1
    --enable-libdav1d
    --enable-libmp3lame
    --enable-libfdk-aac
    --enable-libopus
    --enable-libvorbis
    --enable-libwebp
)

if [[ "${FFMPEG_AUTODETECT:-0}" == "1" ]]; then
    tmp_flags=()
    for f in "${FFMPEG_FLAGS[@]}"; do
        if [[ "$f" != "--disable-autodetect" ]]; then
            tmp_flags+=("$f")
        fi
    done
    FFMPEG_FLAGS=("${tmp_flags[@]}")
fi

if [[ "${FFMPEG_DISABLE_STRIPPING:-0}" == "1" ]]; then
    FFMPEG_FLAGS+=(--disable-stripping)
fi

FFMPEG_EXTRA_CFLAGS="-I$PREFIX/include"
FFMPEG_EXTRA_LDFLAGS="-L$PREFIX/lib"

clone_repo() {
    local url="$1"
    local dir="$2"
    if [[ ! -d "$dir/.git" ]]; then
        git clone --depth 1 "$url" "$dir"
    fi
}

ensure_configure() {
    local dir="$1"
    if [[ ! -x "$dir/configure" ]]; then
        if [[ -x "$dir/autogen.sh" ]]; then
            (cd "$dir" && ./autogen.sh)
        elif [[ -x "$dir/bootstrap" ]]; then
            (cd "$dir" && ./bootstrap)
        elif [[ -x "$dir/bootstrap.sh" ]]; then
            (cd "$dir" && ./bootstrap.sh)
        else
            echo "Missing configure/autogen script in $dir" >&2
            exit 1
        fi
    fi
}

build_x264() {
    local src="$DEPS_SRC/x264"
    clone_repo "https://code.videolan.org/videolan/x264.git" "$src"
    (cd "$src" && make distclean >/dev/null 2>&1 || true)
    local args=(--prefix="$PREFIX" --enable-static --disable-opencl --disable-cli --enable-pic)
    if [[ "$TARGET_INPUT" == "windows" ]]; then
        args+=(--host=x86_64-w64-mingw32 --cross-prefix="$CROSS_PREFIX")
    fi
    (cd "$src" && STRINGS="${STRINGS:-}" ./configure "${args[@]}")
    (cd "$src" && make -j"$NPROC")
    (cd "$src" && make install)
}

build_x265() {
    local src="$DEPS_SRC/x265"
    clone_repo "https://bitbucket.org/multicoreware/x265_git.git" "$src"
    local b="$DEPS_BUILD/x265"
    rm -rf "$b"
    mkdir -p "$b"
    local gen=()
    if command -v ninja >/dev/null 2>&1; then
        gen=(-G Ninja)
    fi
    local ar_path=""
    local ranlib_path=""
    ar_path="$(resolve_tool "$AR" || true)"
    ranlib_path="$(resolve_tool "$RANLIB" || true)"
    cmake -S "$src/source" -B "$b" "${gen[@]}" \
        -DCMAKE_INSTALL_PREFIX="$PREFIX" \
        -DCMAKE_BUILD_TYPE=Release \
        -DENABLE_SHARED=OFF \
        -DENABLE_PIC=ON \
        -DENABLE_CLI=OFF \
        -DCMAKE_C_COMPILER="$CC" \
        -DCMAKE_CXX_COMPILER="$CXX" \
        -DCMAKE_AR="${ar_path:-$AR}" \
        -DCMAKE_RANLIB="${ranlib_path:-$RANLIB}"
    cmake --build "$b" -j"$NPROC"
    cmake --install "$b"
}

build_libvpx() {
    local src="$DEPS_SRC/libvpx"
    clone_repo "https://chromium.googlesource.com/webm/libvpx" "$src"
    (cd "$src" && make distclean >/dev/null 2>&1 || true)
    local args=(--prefix="$PREFIX" --disable-shared --enable-static --disable-examples --disable-tools --disable-docs --disable-unit-tests --enable-pic)
    if [[ "$TARGET_INPUT" == "windows" ]]; then
        args+=(--target=x86_64-win64-gcc)
    fi
    (cd "$src" && ./configure "${args[@]}")
    (cd "$src" && make -j"$NPROC")
    (cd "$src" && make install)
}

build_svtav1() {
    local src="$DEPS_SRC/SVT-AV1"
    clone_repo "https://github.com/AOMediaCodec/SVT-AV1.git" "$src"
    local b="$DEPS_BUILD/svt-av1"
    rm -rf "$b"
    mkdir -p "$b"
    local gen=()
    if command -v ninja >/dev/null 2>&1; then
        gen=(-G Ninja)
    fi
    cmake -S "$src" -B "$b" "${gen[@]}" \
        -DCMAKE_INSTALL_PREFIX="$PREFIX" \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_SHARED_LIBS=OFF \
        -DSVT_AV1_BUILD_APPS=OFF \
        -DSVT_AV1_BUILD_TESTS=OFF \
        -DCMAKE_C_COMPILER="$CC" \
        -DCMAKE_CXX_COMPILER="$CXX"
    cmake --build "$b" -j"$NPROC"
    cmake --install "$b"
}

build_dav1d() {
    local src="$DEPS_SRC/dav1d"
    clone_repo "https://code.videolan.org/videolan/dav1d.git" "$src"
    local b="$DEPS_BUILD/dav1d"
    rm -rf "$b"
    mkdir -p "$b"
    meson setup "$b" "$src" \
        --prefix="$PREFIX" \
        --buildtype=release \
        -Ddefault_library=static \
        -Denable_tools=false \
        -Denable_tests=false
    meson compile -C "$b" -j"$NPROC"
    meson install -C "$b"
}

build_lame() {
    local src="$DEPS_SRC/lame"
    clone_repo "https://github.com/rbrito/lame.git" "$src"
    ensure_configure "$src"
    (cd "$src" && make distclean >/dev/null 2>&1 || true)
    (cd "$src" && ./configure --prefix="$PREFIX" --disable-shared --enable-static --disable-frontend --with-pic)
    (cd "$src" && make -j"$NPROC")
    (cd "$src" && make install)
}

build_fdk_aac() {
    local src="$DEPS_SRC/fdk-aac"
    clone_repo "https://github.com/mstorsjo/fdk-aac.git" "$src"
    ensure_configure "$src"
    (cd "$src" && make distclean >/dev/null 2>&1 || true)
    (cd "$src" && ./configure --prefix="$PREFIX" --disable-shared --enable-static --with-pic)
    (cd "$src" && make -j"$NPROC")
    (cd "$src" && make install)
}

build_ogg() {
    local src="$DEPS_SRC/ogg"
    clone_repo "https://github.com/xiph/ogg.git" "$src"
    ensure_configure "$src"
    (cd "$src" && make distclean >/dev/null 2>&1 || true)
    (cd "$src" && ./configure --prefix="$PREFIX" --disable-shared --enable-static --with-pic)
    (cd "$src" && make -j"$NPROC")
    (cd "$src" && make install)
}

build_vorbis() {
    local src="$DEPS_SRC/vorbis"
    clone_repo "https://github.com/xiph/vorbis.git" "$src"
    ensure_configure "$src"
    (cd "$src" && make distclean >/dev/null 2>&1 || true)
    (cd "$src" && ./configure --prefix="$PREFIX" --disable-shared --enable-static --with-pic)
    (cd "$src" && make -j"$NPROC")
    (cd "$src" && make install)
}

build_opus() {
    local src="$DEPS_SRC/opus"
    clone_repo "https://github.com/xiph/opus.git" "$src"
    ensure_configure "$src"
    (cd "$src" && make distclean >/dev/null 2>&1 || true)
    (cd "$src" && ./configure --prefix="$PREFIX" --disable-shared --enable-static --with-pic)
    (cd "$src" && make -j"$NPROC")
    (cd "$src" && make install)
}

build_webp() {
    local src="$DEPS_SRC/libwebp"
    clone_repo "https://chromium.googlesource.com/webm/libwebp" "$src"
    ensure_configure "$src"
    (cd "$src" && make distclean >/dev/null 2>&1 || true)
    (cd "$src" && ./configure --prefix="$PREFIX" --disable-shared --enable-static --with-pic)
    (cd "$src" && make -j"$NPROC")
    (cd "$src" && make install)
}

build_deps() {
    build_x264
    build_x265
    build_libvpx
    build_svtav1
    build_dav1d
    build_lame
    build_fdk_aac
    build_opus
    build_ogg
    build_vorbis
    build_webp
}

ffdir="$SRC/ffmpeg"
if [[ ! -d "$ffdir/.git" ]]; then
    git clone --filter=blob:none "$FFMPEG_REPO" "$ffdir"
fi
git -C "$ffdir" fetch --depth 1 origin "$FFMPEG_BRANCH" || true
git -C "$ffdir" checkout "$FFMPEG_BRANCH"

if "$ffdir/configure" --help 2>/dev/null | grep -q -- "--enable-libogg"; then
    FFMPEG_FLAGS+=(--enable-libogg)
fi

build_deps

builddir="$BUILD/ffmpeg"
rm -rf "$builddir"
mkdir -p "$builddir"
cd "$builddir"

"$ffdir/configure" \
    "${FFMPEG_FLAGS[@]}" \
    $FFMPEG_TARGET_FLAGS \
    --extra-cflags="$FFMPEG_EXTRA_CFLAGS" \
    --extra-ldflags="$FFMPEG_EXTRA_LDFLAGS" \
    --cc="$CC" --cxx="$CXX" --ar="$AR" --ranlib="$RANLIB" --nm="$NM" --strip="$STRIP"

make -j"$NPROC" V=1
make install

pkgdir="$WORK/pkg"
rm -rf "$pkgdir"
mkdir -p "$pkgdir"

ffmpeg_bin="$PREFIX/bin/ffmpeg"
ffprobe_bin="$PREFIX/bin/ffprobe"
if [[ "$TARGET_INPUT" == "windows" ]]; then
    ffmpeg_bin="${ffmpeg_bin}.exe"
    ffprobe_bin="${ffprobe_bin}.exe"
fi

cp "$ffmpeg_bin" "$pkgdir/"
cp "$ffprobe_bin" "$pkgdir/"

case "$TARGET_INPUT" in
    windows)
        (cd "$pkgdir" && zip -9 -r "$ARTIFACTS/ffmpeg-windows.zip" .)
        ;;
    macos)
        (cd "$pkgdir" && tar cJf "$ARTIFACTS/ffmpeg-macos.tar.xz" .)
        ;;
    linux)
        (cd "$pkgdir" && tar cJf "$ARTIFACTS/ffmpeg-linux.tar.xz" .)
        ;;
esac

echo "Artifacts:"
ls -la "$ARTIFACTS"
