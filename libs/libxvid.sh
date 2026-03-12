#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

XVID_REPO="${XVID_REPO:-https://github.com/Distrotech/xvidcore.git}"
XVID_BRANCH="${XVID_BRANCH:-master}"

srcdir="$SRC/xvidcore"
ensure_clone "$srcdir" "$XVID_REPO"
git_checkout "$srcdir" "$XVID_BRANCH"

builddir="$srcdir/build/generic"
cd "$builddir"
make distclean >/dev/null 2>&1 || true

config_args=(
    --prefix="$PREFIX"
    --disable-shared
    --enable-static
)

if [[ "$TARGET_INPUT" == "windows" ]]; then
    config_args+=(--host=x86_64-w64-mingw32)
fi

./configure "${config_args[@]}"
make -j"$NPROC"
make install