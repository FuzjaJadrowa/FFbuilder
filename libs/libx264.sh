#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

X264_REPO="${X264_REPO:-https://code.videolan.org/videolan/x264.git}"
X264_BRANCH="${X264_BRANCH:-stable}"

srcdir="$SRC/x264"
ensure_clone "$srcdir" "$X264_REPO"
git_checkout "$srcdir" "$X264_BRANCH"

cd "$srcdir"
make distclean >/dev/null 2>&1 || true

config_args=(
    --prefix="$PREFIX"
    --enable-static
    --disable-cli
)

if [[ "$TARGET_INPUT" == "windows" ]]; then
    export PATH="/mingw64/bin:/clang64/bin:$PATH"

    LOCAL_CROSS_PREFIX="${CROSS_PREFIX:-x86_64-w64-mingw32-}"
    if ! command -v "${LOCAL_CROSS_PREFIX}gcc" >/dev/null 2>&1; then
        echo "Prefiks $LOCAL_CROSS_PREFIX nieznaleziony, próba kompilacji natywnej mingw..."
        LOCAL_CROSS_PREFIX=""
    fi

    config_args+=(
        --host=x86_64-w64-mingw32
        --cross-prefix="$LOCAL_CROSS_PREFIX"
    )
else
    config_args+=(--enable-pic)
fi

./configure "${config_args[@]}"
make -j"$NPROC"
make install