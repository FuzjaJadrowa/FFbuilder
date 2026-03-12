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

HOST_UNAME="$(uname -s)"
is_windows_host() {
    case "$HOST_UNAME" in
        MINGW*|MSYS*|CYGWIN*) return 0 ;;
        *) return 1 ;;
    esac
}

FFMPEG_REPO="${FFMPEG_REPO:-https://github.com/FFmpeg/FFmpeg.git}"
FFMPEG_BRANCH="${FFMPEG_BRANCH:-release/8.0}"

WORK="${WORKDIR:-$ROOT/ffbuild}"
SRC="$WORK/src"
BUILD="$WORK/build"
PREFIX="$WORK/prefix"
ARTIFACTS="${ARTIFACTS:-$ROOT/artifacts}"

mkdir -p "$SRC" "$BUILD" "$PREFIX" "$ARTIFACTS"

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
            if [[ "${LINUX_TOOLCHAIN:-}" == "musl" ]]; then
                export CC="${CC:-musl-gcc}"
                export CXX="${CXX:-musl-g++}"
            else
                export CC="${CC:-gcc}"
                export CXX="${CXX:-g++}"
            fi
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
            if command -v pacman >/dev/null 2>&1; then
                if ! command -v x86_64-w64-mingw32-strip >/dev/null 2>&1 && \
                   ! command -v x86_64-w64-mingw32-gcc-strip >/dev/null 2>&1 && \
                   ! command -v gcc-strip >/dev/null 2>&1; then
                    pacman -S --needed --noconfirm mingw-w64-x86_64-binutils
                fi
            fi
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
                    echo "Missing MinGW nm (x86_64-w64-mingw32-nm). Install mingw-w64 binutils or set NM." >&2
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
                    echo "Missing MinGW strip (x86_64-w64-mingw32-strip). Install mingw-w64 binutils or set STRIP." >&2
                    exit 1
                fi
            fi
            if is_windows_host; then
                CROSS_PREFIX=""
                FFMPEG_TARGET_FLAGS="--target-os=mingw32 --arch=x86_64"
            else
                CROSS_PREFIX="${CROSS_PREFIX:-x86_64-w64-mingw32-}"
                FFMPEG_TARGET_FLAGS="--target-os=mingw32 --arch=x86_64 --enable-cross-compile --cross-prefix=$CROSS_PREFIX"
            fi
            ;;
    esac
}

set_toolchain

export ROOT TARGET_INPUT WORK SRC BUILD PREFIX ARTIFACTS NPROC CC CXX AR RANLIB NM STRIP
export CROSS_PREFIX="${CROSS_PREFIX:-}"
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PREFIX/share/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
export PATH="$PREFIX/bin:$PATH"

if [[ "$TARGET_INPUT" == "windows" ]]; then
    if ! command -v "$CC" >/dev/null 2>&1; then
        for candidate in /mingw64/bin /c/msys64/mingw64/bin /c/tools/msys64/mingw64/bin; do
            if [[ -x "$candidate/$CC" ]]; then
                export PATH="$candidate:$PATH"
                break
            fi
        done
    fi
    if [[ -n "${CROSS_PREFIX:-}" ]] && ! command -v "${CROSS_PREFIX}strings" >/dev/null 2>&1; then
        for candidate in "${MINGW_PREFIX:-/mingw64}/bin" /mingw64/bin /c/msys64/mingw64/bin /c/tools/msys64/mingw64/bin; do
            if [[ -x "$candidate/${CROSS_PREFIX}strings" ]]; then
                export PATH="$candidate:$PATH"
                break
            fi
        done
    fi
    mingw_bindir="$(dirname "$(command -v "$CC")")"
    if [[ -d "$mingw_bindir" ]]; then
        export PATH="$mingw_bindir:$PATH"
    fi

    if [[ -n "${CROSS_PREFIX:-}" ]]; then
        if ! command -v "${CROSS_PREFIX}strings" >/dev/null 2>&1; then
            cc_path="$(command -v "$CC" || true)"
            if [[ -n "$cc_path" ]]; then
                cc_bindir="$(dirname "$cc_path")"
                triplet="$("$CC" -dumpmachine 2>/dev/null || true)"
                if [[ -z "$triplet" ]]; then
                    cc_base="$(basename "$CC")"
                    if [[ "$cc_base" == *-gcc ]]; then
                        triplet="${cc_base%-gcc}"
                    elif [[ "$cc_base" == *-clang ]]; then
                        triplet="${cc_base%-clang}"
                    elif [[ "$cc_base" == *-cc ]]; then
                        triplet="${cc_base%-cc}"
                    fi
                fi
                if [[ -z "$triplet" ]]; then
                    triplet="x86_64-w64-mingw32"
                fi
                if [[ -x "$cc_bindir/${triplet}-strings" ]]; then
                    export CROSS_PREFIX="$cc_bindir/${triplet}-"
                    FFMPEG_TARGET_FLAGS="--target-os=mingw32 --arch=x86_64 --enable-cross-compile --cross-prefix=$CROSS_PREFIX"
                fi
            fi
        fi
    fi

    if ! is_windows_host && [[ -n "${CROSS_PREFIX:-}" ]] && ! command -v "${CROSS_PREFIX}strings" >/dev/null 2>&1; then
        echo "Missing ${CROSS_PREFIX}strings in PATH. Install MinGW binutils or set CROSS_PREFIX to the toolchain path." >&2
        exit 1
    fi
fi

LIBS_DIR="$ROOT/libs"
LIB_SCRIPTS=(
    "$LIBS_DIR/libiconv.sh"
    "$LIBS_DIR/libxml2.sh"
    "$LIBS_DIR/libogg.sh"
    "$LIBS_DIR/libvorbis.sh"
    "$LIBS_DIR/libtheora.sh"
    "$LIBS_DIR/libopus.sh"
    "$LIBS_DIR/libmp3lame.sh"
    "$LIBS_DIR/libfdk-aac.sh"
    "$LIBS_DIR/libwebp.sh"
    "$LIBS_DIR/libzimg.sh"
    "$LIBS_DIR/libx264.sh"
    "$LIBS_DIR/libx265.sh"
    "$LIBS_DIR/libvpx.sh"
    "$LIBS_DIR/libsvtav1.sh"
    "$LIBS_DIR/libdav1d.sh"
)

ENABLE_VAAPI="${ENABLE_VAAPI:-0}"
ENABLE_NVCODEC="${ENABLE_NVCODEC:-0}"
ENABLE_EXTRAS="${ENABLE_EXTRAS:-1}"
ENABLE_FONTS="${ENABLE_FONTS:-1}"
ENABLE_DVD="${ENABLE_DVD:-1}"
ENABLE_SYSTEM_EXTRAS="${ENABLE_SYSTEM_EXTRAS:-1}"

if [[ "$TARGET_INPUT" == "linux" ]]; then
    if [[ "$ENABLE_VAAPI" == "1" ]]; then
        LIB_SCRIPTS+=(
            "$LIBS_DIR/libdrm.sh"
            "$LIBS_DIR/libva.sh"
        )
    else
        echo "Skipping VAAPI build on Linux: set ENABLE_VAAPI=1 to enable." >&2
    fi
fi

if [[ "$TARGET_INPUT" == "windows" || "$TARGET_INPUT" == "linux" ]]; then
    if [[ "$TARGET_INPUT" == "windows" || "$ENABLE_NVCODEC" == "1" ]]; then
        LIB_SCRIPTS+=("$LIBS_DIR/libnvcodec.sh")
    else
        echo "Skipping NVENC/NVDEC headers on Linux: set ENABLE_NVCODEC=1 to enable." >&2
    fi
fi

if [[ "$TARGET_INPUT" == "windows" ]]; then
    LIB_SCRIPTS+=("$LIBS_DIR/libamf.sh")
fi

if [[ "$ENABLE_EXTRAS" == "1" ]]; then
    LIB_SCRIPTS+=(
        "$LIBS_DIR/libfftw3.sh"
        "$LIBS_DIR/libgmp.sh"
        "$LIBS_DIR/libopenssl.sh"
        "$LIBS_DIR/libssh.sh"
        "$LIBS_DIR/libsrt.sh"
        "$LIBS_DIR/libsoxr.sh"
        "$LIBS_DIR/libsnappy.sh"
        "$LIBS_DIR/libvmaf.sh"
        "$LIBS_DIR/libkvazaar.sh"
        "$LIBS_DIR/libgme.sh"
        "$LIBS_DIR/libvidstab.sh"
        "$LIBS_DIR/libtwolame.sh"
        "$LIBS_DIR/libxvid.sh"
        "$LIBS_DIR/libzvbi.sh"
        "$LIBS_DIR/libchromaprint.sh"
        "$LIBS_DIR/libaribb24.sh"
        "$LIBS_DIR/libaribcaption.sh"
    )
fi

if [[ "$ENABLE_FONTS" == "1" ]]; then
    LIB_SCRIPTS+=(
        "$LIBS_DIR/libzlib.sh"
        "$LIBS_DIR/libbz2.sh"
        "$LIBS_DIR/libpng.sh"
        "$LIBS_DIR/libexpat.sh"
        "$LIBS_DIR/libfreetype.sh"
        "$LIBS_DIR/libfontconfig.sh"
        "$LIBS_DIR/libharfbuzz.sh"
        "$LIBS_DIR/libfribidi.sh"
        "$LIBS_DIR/libass.sh"
    )
fi

if [[ "$ENABLE_DVD" == "1" ]]; then
    LIB_SCRIPTS+=(
        "$LIBS_DIR/libdvdcss.sh"
        "$LIBS_DIR/libdvdread.sh"
        "$LIBS_DIR/libdvdnav.sh"
        "$LIBS_DIR/libudfread.sh"
        "$LIBS_DIR/libbluray.sh"
    )
fi

for script in "${LIB_SCRIPTS[@]}"; do
    if [[ ! -f "$script" ]]; then
        echo "Missing library script: $script" >&2
        exit 1
    fi
    bash "$script"
done

if [[ "$TARGET_INPUT" == "windows" && "${MINGW_STATIC_RUNTIME:-1}" == "1" ]]; then
    for pc in "$PREFIX/lib/pkgconfig/"*.pc "$PREFIX/share/pkgconfig/"*.pc; do
        [[ -f "$pc" ]] || continue
        sed -i 's/ -lgcc_s_seh//g; s/ -lgcc_s//g' "$pc"
    done
fi

EXTRA_CFLAGS="-I$PREFIX/include"
EXTRA_LDFLAGS="-L$PREFIX/lib"
EXTRA_LIBS=""

if [[ "$TARGET_INPUT" == "linux" && "${LINUX_TOOLCHAIN:-}" == "musl" ]]; then
    EXTRA_LDFLAGS="$EXTRA_LDFLAGS -static"
fi

if [[ "$TARGET_INPUT" == "windows" ]]; then
    if [[ "${MINGW_STATIC_RUNTIME:-1}" == "1" ]]; then
        EXTRA_LDFLAGS="$EXTRA_LDFLAGS -static -static-libgcc -static-libstdc++"
        EXTRA_LIBS="$EXTRA_LIBS -Wl,-Bstatic -lwinpthread -lstdc++ -lgcc -lgcc_eh -Wl,-Bdynamic"
    fi
fi

pc_exists() {
    [[ -f "$PREFIX/lib/pkgconfig/$1.pc" || -f "$PREFIX/share/pkgconfig/$1.pc" ]]
}

pc_has() {
    local expr="$1"
    if command -v pkg-config >/dev/null 2>&1; then
        pkg-config --exists "$expr"
        return $?
    fi
    pc_exists "${expr%% *}"
}

pc_exists_any() {
    local name
    for name in "$@"; do
        if pc_exists "$name"; then
            return 0
        fi
    done
    return 1
}

FFMPEG_FLAGS=(
    --prefix="$PREFIX"
    --pkg-config-flags=--static
    --disable-shared
    --enable-static
    --enable-gpl
    --enable-version3
    --enable-nonfree
    --disable-debug
    --disable-doc
    --disable-programs
    --enable-ffmpeg
    --enable-ffprobe
    --enable-libmp3lame
    --enable-libfdk-aac
    --enable-libopus
    --enable-libvorbis
    --enable-libtheora
    --enable-libwebp
    --enable-libzimg
    --enable-libxml2
    --enable-libx264
    --enable-libx265
    --enable-libvpx
    --enable-libsvtav1
    --enable-libdav1d
    --extra-cflags="$EXTRA_CFLAGS"
    --extra-ldflags="$EXTRA_LDFLAGS"
    --disable-autodetect
)

ffdir="$SRC/ffmpeg"
if [[ ! -d "$ffdir/.git" ]]; then
    git clone --filter=blob:none "$FFMPEG_REPO" "$ffdir"
fi
git -C "$ffdir" fetch --depth 1 origin "$FFMPEG_BRANCH" || true
git -C "$ffdir" checkout "$FFMPEG_BRANCH"

ffmpeg_help="$BUILD/ffmpeg_configure_help.txt"
if [[ ! -f "$ffmpeg_help" || "${FFMPEG_CONFIGURE_REFRESH:-0}" == "1" ]]; then
    "$ffdir/configure" --help > "$ffmpeg_help"
fi

ffmpeg_has_flag() {
    local flag="$1"
    grep -q -- "$flag" "$ffmpeg_help"
}

add_ffmpeg_flag() {
    local flag="$1"
    if ffmpeg_has_flag "$flag"; then
        FFMPEG_FLAGS+=("$flag")
    else
        echo "Skipping unsupported FFmpeg flag: $flag" >&2
    fi
}

if [[ "$TARGET_INPUT" == "windows" ]]; then
    FFMPEG_FLAGS+=(--enable-dxva2 --enable-d3d11va)
    if [[ -d "$PREFIX/include/AMF" ]]; then
        add_ffmpeg_flag --enable-amf
    else
        echo "Skipping AMF: headers not installed in $PREFIX/include/AMF." >&2
    fi
fi

if [[ "$TARGET_INPUT" == "macos" ]]; then
    add_ffmpeg_flag --enable-videotoolbox
fi

if [[ "$TARGET_INPUT" == "linux" ]]; then
    if [[ "$ENABLE_VAAPI" == "1" ]]; then
        if pc_exists "libdrm"; then
            add_ffmpeg_flag --enable-libdrm
        else
            echo "Skipping libdrm: libdrm not found via pkg-config." >&2
        fi
        if pc_exists "libva"; then
            add_ffmpeg_flag --enable-vaapi
        else
            echo "Skipping VAAPI: libva not found via pkg-config." >&2
        fi
    fi
fi

if [[ "$TARGET_INPUT" != "macos" ]]; then
    if [[ "$TARGET_INPUT" == "windows" || "$ENABLE_NVCODEC" == "1" ]]; then
        if pc_exists "ffnvcodec"; then
            add_ffmpeg_flag --enable-ffnvcodec
            add_ffmpeg_flag --enable-nvenc
            add_ffmpeg_flag --enable-nvdec
            add_ffmpeg_flag --enable-cuvid
        else
            echo "Skipping NVENC/NVDEC: nv-codec-headers not found via pkg-config." >&2
        fi
    fi
fi

if [[ "$ENABLE_EXTRAS" == "1" ]]; then
    if pc_exists "fftw3"; then
        add_ffmpeg_flag --enable-fftw3
    else
        echo "Skipping FFTW3: fftw3 not found via pkg-config." >&2
    fi
    if pc_exists "gmp"; then
        add_ffmpeg_flag --enable-gmp
    else
        echo "Skipping GMP: gmp not found via pkg-config." >&2
    fi
    if pc_exists "openssl"; then
        add_ffmpeg_flag --enable-openssl
    else
        echo "Skipping OpenSSL: openssl not found via pkg-config." >&2
    fi
    if pc_exists "libssh"; then
        add_ffmpeg_flag --enable-libssh
    else
        echo "Skipping libssh: libssh not found via pkg-config." >&2
    fi
    if pc_exists "srt"; then
        add_ffmpeg_flag --enable-libsrt
    else
        echo "Skipping SRT: srt not found via pkg-config." >&2
    fi
    if pc_exists "soxr"; then
        add_ffmpeg_flag --enable-libsoxr
    else
        echo "Skipping soxr: soxr not found via pkg-config." >&2
    fi
    if pc_exists "snappy"; then
        add_ffmpeg_flag --enable-libsnappy
    else
        echo "Skipping snappy: snappy not found via pkg-config." >&2
    fi
    if pc_exists "libvmaf"; then
        add_ffmpeg_flag --enable-libvmaf
    else
        echo "Skipping libvmaf: libvmaf not found via pkg-config." >&2
    fi
    if pc_exists "kvazaar"; then
        add_ffmpeg_flag --enable-libkvazaar
    else
        echo "Skipping kvazaar: kvazaar not found via pkg-config." >&2
    fi
    if pc_exists "gme"; then
        add_ffmpeg_flag --enable-libgme
    else
        echo "Skipping libgme: gme not found via pkg-config." >&2
    fi
    if pc_exists_any "vidstab" "libvidstab"; then
        add_ffmpeg_flag --enable-libvidstab
    else
        echo "Skipping libvidstab: vidstab not found via pkg-config." >&2
    fi
    if pc_exists_any "twolame" "libtwolame"; then
        add_ffmpeg_flag --enable-libtwolame
    else
        echo "Skipping twolame: twolame not found via pkg-config." >&2
    fi
    if pc_exists_any "xvidcore" "xvid"; then
        add_ffmpeg_flag --enable-libxvid
    else
        echo "Skipping xvid: xvidcore not found via pkg-config." >&2
    fi
    if pc_exists_any "zvbi-0.2" "libzvbi"; then
        add_ffmpeg_flag --enable-libzvbi
    else
        echo "Skipping libzvbi: zvbi not found via pkg-config." >&2
    fi
    if pc_exists_any "libchromaprint" "chromaprint"; then
        add_ffmpeg_flag --enable-libchromaprint
    else
        echo "Skipping chromaprint: libchromaprint not found via pkg-config." >&2
    fi
    if pc_exists "libaribb24"; then
        add_ffmpeg_flag --enable-libaribb24
    else
        echo "Skipping libaribb24: libaribb24 not found via pkg-config." >&2
    fi
    if pc_exists "libaribcaption"; then
        add_ffmpeg_flag --enable-libaribcaption
    else
        echo "Skipping libaribcaption: libaribcaption not found via pkg-config." >&2
    fi
    if pc_exists "libzmq"; then
        add_ffmpeg_flag --enable-libzmq
    else
        echo "Skipping libzmq: libzmq not found via pkg-config." >&2
    fi
    if pc_exists "libplacebo"; then
        add_ffmpeg_flag --enable-libplacebo
    else
        echo "Skipping libplacebo: libplacebo not found via pkg-config." >&2
    fi
    if pc_exists "libvpl"; then
        add_ffmpeg_flag --enable-libvpl
    else
        echo "Skipping libvpl: libvpl not found via pkg-config." >&2
    fi
    if pc_exists "rav1e"; then
        add_ffmpeg_flag --enable-librav1e
    else
        echo "Skipping rav1e: rav1e not found via pkg-config." >&2
    fi
    if pc_exists "vvenc"; then
        add_ffmpeg_flag --enable-libvvenc
    else
        echo "Skipping vvenc: vvenc not found via pkg-config." >&2
    fi
    if pc_exists "uavs3d"; then
        add_ffmpeg_flag --enable-libuavs3d
    else
        echo "Skipping uavs3d: uavs3d not found via pkg-config." >&2
    fi
    if pc_exists "xavs2"; then
        add_ffmpeg_flag --enable-libxavs2
    else
        echo "Skipping xavs2: xavs2 not found via pkg-config." >&2
    fi
    if pc_exists "davs2"; then
        add_ffmpeg_flag --enable-libdavs2
    else
        echo "Skipping davs2: davs2 not found via pkg-config." >&2
    fi
    if pc_exists "frei0r"; then
        add_ffmpeg_flag --enable-frei0r
    else
        echo "Skipping frei0r: frei0r not found via pkg-config." >&2
    fi
    if pc_exists "rubberband"; then
        add_ffmpeg_flag --enable-librubberband
    else
        echo "Skipping rubberband: rubberband not found via pkg-config." >&2
    fi
    if [[ "$TARGET_INPUT" == "windows" ]]; then
        if [[ -f "$PREFIX/include/avisynth/avisynth_c.h" || -f "$PREFIX/include/avisynth_c.h" ]]; then
            add_ffmpeg_flag --enable-avisynth
        else
            echo "Skipping AviSynth: headers not found in $PREFIX/include." >&2
        fi
    fi
fi

if [[ "$ENABLE_FONTS" == "1" ]]; then
    if [[ -f "$PREFIX/lib/libz.a" ]] || pc_exists "zlib"; then
        add_ffmpeg_flag --enable-zlib
    else
        echo "Skipping zlib: libz not found in prefix or via pkg-config." >&2
    fi
    if pc_exists "freetype2"; then
        add_ffmpeg_flag --enable-libfreetype
    else
        echo "Skipping freetype: freetype2 not found via pkg-config." >&2
    fi
    if pc_exists "fontconfig"; then
        add_ffmpeg_flag --enable-libfontconfig
    else
        echo "Skipping fontconfig: fontconfig not found via pkg-config." >&2
    fi
    if pc_exists "harfbuzz"; then
        add_ffmpeg_flag --enable-libharfbuzz
    else
        echo "Skipping harfbuzz: harfbuzz not found via pkg-config." >&2
    fi
    if pc_exists "fribidi"; then
        add_ffmpeg_flag --enable-libfribidi
    else
        echo "Skipping fribidi: fribidi not found via pkg-config." >&2
    fi
    if pc_exists "libass"; then
        add_ffmpeg_flag --enable-libass
    else
        echo "Skipping libass: libass not found via pkg-config." >&2
    fi
fi

if [[ "$ENABLE_DVD" == "1" ]]; then
    if pc_exists_any "dvdread" "libdvdread"; then
        add_ffmpeg_flag --enable-libdvdread
    else
        echo "Skipping libdvdread: dvdread not found via pkg-config." >&2
    fi
    if pc_exists_any "dvdnav" "libdvdnav"; then
        add_ffmpeg_flag --enable-libdvdnav
    else
        echo "Skipping libdvdnav: dvdnav not found via pkg-config." >&2
    fi
    if pc_exists "libbluray"; then
        add_ffmpeg_flag --enable-libbluray
    else
        echo "Skipping libbluray: libbluray not found via pkg-config." >&2
    fi
fi

if [[ "$ENABLE_SYSTEM_EXTRAS" == "1" ]]; then
    if pc_exists "x11"; then
        add_ffmpeg_flag --enable-xlib
    else
        echo "Skipping X11: x11 not found via pkg-config." >&2
    fi
    if pc_exists_any "OpenCL" "opencl"; then
        add_ffmpeg_flag --enable-opencl
    else
        echo "Skipping OpenCL: OpenCL not found via pkg-config." >&2
    fi
    if pc_exists "vulkan"; then
        add_ffmpeg_flag --enable-vulkan
    else
        echo "Skipping Vulkan: vulkan not found via pkg-config." >&2
    fi
    if pc_exists "libpulse"; then
        add_ffmpeg_flag --enable-libpulse
    else
        echo "Skipping PulseAudio: libpulse not found via pkg-config." >&2
    fi
    if pc_exists "sdl2"; then
        add_ffmpeg_flag --enable-sdl2
    else
        echo "Skipping SDL2: sdl2 not found via pkg-config." >&2
    fi
    if [[ "$TARGET_INPUT" == "windows" ]]; then
        add_ffmpeg_flag --enable-schannel
    fi
fi

if [[ -n "$EXTRA_LIBS" ]]; then
    FFMPEG_FLAGS+=(--extra-libs="$EXTRA_LIBS")
fi

if [[ "${FFMPEG_AUTODETECT:-0}" == "1" ]]; then
    tmp_flags=()
    for f in "${FFMPEG_FLAGS[@]}"; do
        if [[ "$f" != "--disable-autodetect" ]]; then
            tmp_flags+=("$f")
        fi
    done
    FFMPEG_FLAGS=("${tmp_flags[@]}")
fi

builddir="$BUILD/ffmpeg"
rm -rf "$builddir"
mkdir -p "$builddir"
cd "$builddir"

"$ffdir/configure" \
    "${FFMPEG_FLAGS[@]}" \
    $FFMPEG_TARGET_FLAGS \
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

if [[ "$TARGET_INPUT" == "windows" && "${BUNDLE_MINGW_RUNTIME_DLLS:-0}" == "1" ]]; then
    mingw_bindir="$(dirname "$(command -v "$CC")")"
    runtime_dlls=(
        libwinpthread-1.dll
        libgcc_s_seh-1.dll
        libstdc++-6.dll
    )
    for dll in "${runtime_dlls[@]}"; do
        if [[ -f "$mingw_bindir/$dll" ]]; then
            cp "$mingw_bindir/$dll" "$pkgdir/"
        else
            echo "Warning: $dll not found in $mingw_bindir" >&2
        fi
    done
fi

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