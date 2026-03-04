#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT_DIR/common.sh"

require_env SRC BUILD PREFIX NPROC TARGET_INPUT

DAV1D_REPO="${DAV1D_REPO:-https://code.videolan.org/videolan/dav1d.git}"

fetch_repo "dav1d" "$DAV1D_REPO"
src="$SRC/dav1d"
builddir="$BUILD/dav1d"
rm -rf "$builddir"

meson_args=(
    --prefix="$PREFIX"
    --default-library=static
    -Denable_tools=false
    -Denable_tests=false
)

if [[ "${IS_CROSS_WINDOWS:-0}" == "1" ]]; then
    cross_file="$BUILD/meson-cross-mingw.txt"
    meson_pkgconfig="pkg-config"
    if command -v "${CROSS_PREFIX}pkg-config" >/dev/null 2>&1; then
        meson_pkgconfig="${CROSS_PREFIX}pkg-config"
    fi
    cat >"$cross_file" <<EOF
[binaries]
c = '$CC'
cpp = '$CXX'
ar = '$AR'
strip = '$STRIP'
pkgconfig = '$meson_pkgconfig'

[host_machine]
system = 'windows'
cpu_family = 'x86_64'
cpu = 'x86_64'
endian = 'little'

[properties]
needs_exe_wrapper = true
EOF
    meson setup "$builddir" "$src" "${meson_args[@]}" --cross-file "$cross_file"
else
    meson setup "$builddir" "$src" "${meson_args[@]}"
fi

ninja -C "$builddir" -j"$NPROC"
ninja -C "$builddir" install