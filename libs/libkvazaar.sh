#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

KVAZAAR_REPO="${KVAZAAR_REPO:-https://github.com/ultravideo/kvazaar.git}"
KVAZAAR_BRANCH="${KVAZAAR_BRANCH:-master}"

srcdir="$SRC/kvazaar"
ensure_clone "$srcdir" "$KVAZAAR_REPO"
git_checkout "$srcdir" "$KVAZAAR_BRANCH"

cd "$srcdir"
make distclean >/dev/null 2>&1 || true

if [[ ! -x "./configure" ]]; then
    autotools_prepare
fi

config_args=(
    --prefix="$PREFIX"
    --disable-shared
    --enable-static
    --disable-cli
)

if [[ "$TARGET_INPUT" == "windows" ]]; then
    config_args+=(--host=x86_64-w64-mingw32)
fi

./configure "${config_args[@]}"
make -j"$NPROC"
make install