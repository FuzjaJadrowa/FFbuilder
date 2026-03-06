#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

XAVS2_REPO="${XAVS2_REPO:-https://github.com/pkuvcl/xavs2.git}"
XAVS2_BRANCH="${XAVS2_BRANCH:-master}"

srcdir="$SRC/xavs2"
ensure_clone "$srcdir" "$XAVS2_REPO"
git_checkout "$srcdir" "$XAVS2_BRANCH"

if [[ "$TARGET_INPUT" == "macos" ]]; then
    echo "Skipping xavs2 on macOS: upstream build uses x86 toolchain assumptions." >&2
    exit 0
fi

if [[ "$TARGET_INPUT" == "windows" ]]; then
    git -C "$srcdir" apply --verbose - <<'PATCH' || true
diff --git a/source/encoder/encoder.c b/source/encoder/encoder.c
index 9e82d8c..c98c3b1 100644
--- a/source/encoder/encoder.c
+++ b/source/encoder/encoder.c
@@ -630,7 +630,8 @@ static void encoder_aec_prepare_one_frame(xavs2_t *h)
     }
 }
 
-static void *encoder_aec_encode_one_frame(xavs2_t *h)
+static void *encoder_aec_encode_one_frame(void *arg)
 {
+    xavs2_t *h = (xavs2_t *)arg;
     pix32u_t pixel_cnt;
     int ret;
 
PATCH
fi

if [[ "$TARGET_INPUT" == "linux" ]]; then
    export CFLAGS="${CFLAGS:-} -fno-pie"
    export LDFLAGS="${LDFLAGS:-} -no-pie"
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
    if [[ "$TARGET_INPUT" == "windows" ]]; then
        make -j"$NPROC" CFLAGS+=" -Wno-incompatible-pointer-types -Wno-error=incompatible-pointer-types"
    elif [[ "$TARGET_INPUT" == "linux" ]]; then
        make -j"$NPROC" CFLAGS+=" -fno-pie" LDFLAGS+=" -no-pie"
    else
        make -j"$NPROC"
    fi
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
    if [[ "$TARGET_INPUT" == "windows" ]]; then
        make -j"$NPROC" CFLAGS+=" -Wno-incompatible-pointer-types -Wno-error=incompatible-pointer-types"
    elif [[ "$TARGET_INPUT" == "linux" ]]; then
        make -j"$NPROC" CFLAGS+=" -fno-pie" LDFLAGS+=" -no-pie"
    else
        make -j"$NPROC"
    fi
    make install
fi