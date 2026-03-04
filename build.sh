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
            CROSS_PREFIX="${CROSS_PREFIX:-x86_64-w64-mingw32-}"
            FFMPEG_TARGET_FLAGS="--target-os=mingw32 --arch=x86_64 --enable-cross-compile --cross-prefix=$CROSS_PREFIX"
            ;;
    esac
}

set_toolchain

export ROOT TARGET_INPUT WORK SRC BUILD PREFIX ARTIFACTS NPROC CC CXX AR RANLIB NM STRIP
export CROSS_PREFIX="${CROSS_PREFIX:-}"
export PKG_CONFIG_PATH="${PKG_CONFIG_PATH:-$PREFIX/lib/pkgconfig:$PREFIX/share/pkgconfig}"
export PATH="$PREFIX/bin:$PATH"

LIBS_DIR="$ROOT/libs"
LIB_SCRIPTS=(
    "$LIBS_DIR/libx264.sh"
    "$LIBS_DIR/libx265.sh"
    "$LIBS_DIR/libvpx.sh"
    "$LIBS_DIR/libsvtav1.sh"
    "$LIBS_DIR/libdav1d.sh"
)

for script in "${LIB_SCRIPTS[@]}"; do
    if [[ ! -f "$script" ]]; then
        echo "Missing library script: $script" >&2
        exit 1
    fi
    bash "$script"
done

EXTRA_CFLAGS="-I$PREFIX/include"
EXTRA_LDFLAGS="-L$PREFIX/lib"
EXTRA_LIBS=""

if [[ "$TARGET_INPUT" == "windows" ]]; then
    if [[ "${MINGW_STATIC_RUNTIME:-1}" == "1" ]]; then
        EXTRA_LDFLAGS="$EXTRA_LDFLAGS -static -static-libgcc -static-libstdc++"
    fi
fi

FFMPEG_FLAGS=(
    --prefix="$PREFIX"
    --pkg-config-flags=--static
    --disable-shared
    --enable-static
    --enable-gpl
    --disable-debug
    --disable-doc
    --disable-programs
    --enable-ffmpeg
    --enable-ffprobe
    --enable-libx264
    --enable-libx265
    --enable-libvpx
    --enable-libsvtav1
    --enable-libdav1d
    --extra-cflags="$EXTRA_CFLAGS"
    --extra-ldflags="$EXTRA_LDFLAGS"
    --disable-autodetect
)

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

ffdir="$SRC/ffmpeg"
if [[ ! -d "$ffdir/.git" ]]; then
    git clone --filter=blob:none "$FFMPEG_REPO" "$ffdir"
fi
git -C "$ffdir" fetch --depth 1 origin "$FFMPEG_BRANCH" || true
git -C "$ffdir" checkout "$FFMPEG_BRANCH"

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