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

include_src=""
for candidate in "$srcdir/amf/public/include" "$srcdir/public/include" "$srcdir/AMF/public/include"; do
    if [[ -d "$candidate" ]]; then
        include_src="$candidate"
        break
    fi
done

if [[ -z "$include_src" ]]; then
    echo "AMF headers not found in $srcdir." >&2
    exit 1
fi

mkdir -p "$PREFIX/include"
cp -R "$include_src"/* "$PREFIX/include/"
