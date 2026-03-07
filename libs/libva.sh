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
