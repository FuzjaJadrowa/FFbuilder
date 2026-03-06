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

buildroot="$srcdir/build/linux"
if [[ -x "$buildroot/configure" ]]; then
    cd "$buildroot"
    make distclean >/dev/null 2>&1 || true
    config_args=(
        --prefix="$PREFIX"
        --disable-cli
    )
    if [[ "$TARGET_INPUT" == "linux" ]]; then
        config_args+=(--extra-cflags="-fno-pie" --extra-ldflags="-no-pie")
    fi
    if [[ "$TARGET_INPUT" == "windows" ]]; then
        config_args+=(--host=x86_64-w64-mingw32)
    fi
    if [[ "$TARGET_INPUT" == "windows" ]]; then
        config_args+=(--extra-cflags="-Wno-incompatible-pointer-types -Wno-error=incompatible-pointer-types")
    fi
    ./configure "${config_args[@]}"
    base_cflags="$(awk -F= '/^CFLAGS=/{sub(/^CFLAGS=/, ""); print; exit}' config.mak || true)"
    base_ldflags="$(awk -F= '/^LDFLAGS=/{sub(/^LDFLAGS=/, ""); print; exit}' config.mak || true)"
    extra_includes="-I$buildroot -I$srcdir/source/encoder -I$srcdir/source/common/x86 -I$srcdir/source/common/vec -I$srcdir/source/test"
    if [[ "$TARGET_INPUT" == "linux" ]]; then
        base_cflags="$base_cflags -fno-pie"
        base_ldflags="$base_ldflags -no-pie"
    fi
    if [[ "$TARGET_INPUT" == "windows" ]]; then
        base_cflags="$base_cflags -Wno-incompatible-pointer-types -Wno-error=incompatible-pointer-types"
    fi
    if [[ -n "$base_cflags" ]]; then
        make -j"$NPROC" CFLAGS="$base_cflags $extra_includes" LDFLAGS="$base_ldflags"
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
        --disable-cli
    )
    if [[ "$TARGET_INPUT" == "linux" ]]; then
        config_args+=(--extra-cflags="-fno-pie" --extra-ldflags="-no-pie")
    fi
    if [[ "$TARGET_INPUT" == "windows" ]]; then
        config_args+=(--host=x86_64-w64-mingw32)
    fi
    if [[ "$TARGET_INPUT" == "windows" ]]; then
        config_args+=(--extra-cflags="-Wno-incompatible-pointer-types -Wno-error=incompatible-pointer-types")
    fi
    ./configure "${config_args[@]}"
    base_cflags="$(awk -F= '/^CFLAGS=/{sub(/^CFLAGS=/, ""); print; exit}' config.mak || true)"
    base_ldflags="$(awk -F= '/^LDFLAGS=/{sub(/^LDFLAGS=/, ""); print; exit}' config.mak || true)"
    extra_includes="-I$srcdir/source/encoder -I$srcdir/source/common/x86 -I$srcdir/source/common/vec -I$srcdir/source/test"
    if [[ "$TARGET_INPUT" == "linux" ]]; then
        base_cflags="$base_cflags -fno-pie"
        base_ldflags="$base_ldflags -no-pie"
    fi
    if [[ "$TARGET_INPUT" == "windows" ]]; then
        base_cflags="$base_cflags -Wno-incompatible-pointer-types -Wno-error=incompatible-pointer-types"
    fi
    if [[ -n "$base_cflags" ]]; then
        make -j"$NPROC" CFLAGS="$base_cflags $extra_includes" LDFLAGS="$base_ldflags"
    else
        make -j"$NPROC"
    fi
    make install
fi

pc_file="$PREFIX/lib/pkgconfig/xavs2.pc"
if [[ ! -f "$pc_file" ]]; then
    mkdir -p "$PREFIX/lib/pkgconfig"
    version="1.0.0"
    if [[ -f "$srcdir/source/common/version.h" ]]; then
        v="$(awk -F\" '/XAVS2_VERSION/ {print $2; exit}' "$srcdir/source/common/version.h")"
        if [[ -n "${v:-}" ]]; then
            version="$v"
        fi
    fi
    cat >"$pc_file" <<EOF
prefix=$PREFIX
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: xavs2
Description: AVS2 encoder (xavs2)
Version: $version
Libs: -L\${libdir} -lxavs2
Cflags: -I\${includedir}
EOF
fi