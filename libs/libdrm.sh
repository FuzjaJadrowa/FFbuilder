#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

LIBDRM_REPO="${LIBDRM_REPO:-https://gitlab.freedesktop.org/mesa/drm.git}"
LIBDRM_BRANCH="${LIBDRM_BRANCH:-main}"

if [[ "$TARGET_INPUT" != "linux" ]]; then
    echo "Skipping libdrm: Linux only." >&2
    exit 0
fi

srcdir="$SRC/libdrm"
builddir="$BUILD/libdrm"
ensure_clone "$srcdir" "$LIBDRM_REPO"
git_checkout "$srcdir" "$LIBDRM_BRANCH"

rm -rf "$builddir"
meson setup "$builddir" "$srcdir" \
    --prefix="$PREFIX" \
    --libdir=lib \
    -Dbuildtype=release \
    -Ddefault_library=static
meson compile -C "$builddir"
meson install -C "$builddir"
