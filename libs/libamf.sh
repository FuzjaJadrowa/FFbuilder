#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

AMF_REPO="${AMF_REPO:-https://github.com/GPUOpen-LibrariesAndSDKs/AMF.git}"
AMF_BRANCH="${AMF_BRANCH:-master}"

if [[ "$TARGET_INPUT" != "windows" ]]; then
    echo "Skipping AMF headers: Windows only." >&2
    exit 0
fi

srcdir="$SRC/amf"
ensure_clone "$srcdir" "$AMF_REPO"
git_checkout "$srcdir" "$AMF_BRANCH"
git -C "$srcdir" submodule update --init --recursive || true

amf_dir=""
for candidate in \
    "$srcdir/amf/public/include/AMF" \
    "$srcdir/public/include/AMF" \
    "$srcdir/AMF/public/include/AMF" \
    "$srcdir/include/AMF" \
    "$srcdir/AMF"; do
    if [[ -d "$candidate" ]]; then
        amf_dir="$candidate"
        break
    fi
done

if [[ -z "$amf_dir" ]]; then
    amf_dir="$(find "$srcdir" -type d -name AMF -path "*/public/include/AMF" -print -quit 2>/dev/null || true)"
fi

if [[ -z "$amf_dir" ]]; then
    echo "AMF headers not found in $srcdir." >&2
    exit 1
fi

mkdir -p "$PREFIX/include"
cp -R "$amf_dir" "$PREFIX/include/"