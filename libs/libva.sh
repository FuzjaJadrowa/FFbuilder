#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

LIBVA_REPO="${LIBVA_REPO:-https://github.com/intel/libva.git}"
LIBVA_BRANCH="${LIBVA_BRANCH:-master}"

if [[ "$TARGET_INPUT" != "linux" ]]; then
    echo "Skipping libva: Linux only." >&2
    exit 0
fi

srcdir="$SRC/libva"
builddir="$BUILD/libva"
ensure_clone "$srcdir" "$LIBVA_REPO"
git_checkout "$srcdir" "$LIBVA_BRANCH"

rm -rf "$builddir"
meson setup "$builddir" "$srcdir" \
    --prefix="$PREFIX" \
    --libdir=lib \
    -Dbuildtype=release \
    -Ddefault_library=static
meson compile -C "$builddir"
meson install -C "$builddir"

pc_patch_static() {
    local pc_file="$1"
    if [[ ! -f "$pc_file" ]]; then
        return 1
    fi
    if ! grep -q -- "-Wl,-Bstatic" "$pc_file"; then
        local tmp_pc
        tmp_pc="$(mktemp)"
        awk '{
            if ($1 == "Libs:") {
                line = substr($0, length("Libs:") + 1)
                print "Libs: -Wl,-Bstatic" line " -Wl,-Bdynamic"
                next
            }
            print
        }' "$pc_file" >"$tmp_pc"
        mv "$tmp_pc" "$pc_file"
    fi
    if ! grep -q -- "-lm" "$pc_file"; then
        if grep -q "^Libs.private:" "$pc_file"; then
            local tmp_priv
            tmp_priv="$(mktemp)"
            awk '{ if ($0 ~ /^Libs.private:/) { print $0 " -lm -ldl -lpthread"; next } print }' "$pc_file" >"$tmp_priv"
            mv "$tmp_priv" "$pc_file"
        else
            echo "Libs.private: -lm -ldl -lpthread" >>"$pc_file"
        fi
    fi
}

pc_file="$PREFIX/lib/pkgconfig/libva.pc"
if [[ ! -f "$pc_file" && -f "$PREFIX/share/pkgconfig/libva.pc" ]]; then
    pc_file="$PREFIX/share/pkgconfig/libva.pc"
fi
pc_patch_static "$pc_file" || true

pc_drm="$PREFIX/lib/pkgconfig/libva-drm.pc"
if [[ ! -f "$pc_drm" && -f "$PREFIX/share/pkgconfig/libva-drm.pc" ]]; then
    pc_drm="$PREFIX/share/pkgconfig/libva-drm.pc"
fi
pc_patch_static "$pc_drm" || true

if [[ ! -f "$PREFIX/lib/libva.a" ]]; then
    echo "libva.a not found in $PREFIX/lib; disabling VAAPI to avoid shared lib dependency." >&2
    rm -f \
        "$PREFIX/lib/pkgconfig/libva.pc" \
        "$PREFIX/share/pkgconfig/libva.pc" \
        "$PREFIX/lib/pkgconfig/libva-drm.pc" \
        "$PREFIX/share/pkgconfig/libva-drm.pc"
    exit 0
fi