#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

if ! command -v cargo >/dev/null 2>&1; then
    echo "Skipping rav1e: missing cargo." >&2
    exit 0
fi

RAV1E_REPO="${RAV1E_REPO:-https://github.com/xiph/rav1e.git}"
RAV1E_BRANCH="${RAV1E_BRANCH:-master}"

srcdir="$SRC/rav1e"
ensure_clone "$srcdir" "$RAV1E_REPO"
git_checkout "$srcdir" "$RAV1E_BRANCH"

cd "$srcdir"

cargo build --release --features=capi

install -d "$PREFIX/lib" "$PREFIX/include" "$PREFIX/lib/pkgconfig"
if [[ -f "target/release/librav1e.a" ]]; then
    cp "target/release/librav1e.a" "$PREFIX/lib/"
fi
if [[ -f "capi/rav1e.h" ]]; then
    cp "capi/rav1e.h" "$PREFIX/include/"
fi

cat >"$PREFIX/lib/pkgconfig/rav1e.pc" <<EOF
prefix=$PREFIX
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: rav1e
Description: AV1 encoder
Version: 0.0.0
Libs: -L\${libdir} -lrav1e
Cflags: -I\${includedir}
EOF