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

amf_include=""
for candidate in \
    "$srcdir/amf/public/include/AMF" \
    "$srcdir/amf/public/include" \
    "$srcdir/public/include/AMF" \
    "$srcdir/public/include" \
    "$srcdir/AMF/public/include/AMF" \
    "$srcdir/AMF/public/include" \
    "$srcdir/include/AMF" \
    "$srcdir/include" \
    "$srcdir/AMF"; do
    if [[ -d "$candidate" ]]; then
        if [[ -f "$candidate/core/Version.h" ]]; then
            amf_include="$candidate"
            break
        fi
        if [[ -f "$candidate/AMF/core/Version.h" ]]; then
            amf_include="$candidate/AMF"
            break
        fi
    fi
done

if [[ -z "$amf_include" ]]; then
    version_path="$(find "$srcdir" -type f -path "*/core/Version.h" -print -quit 2>/dev/null || true)"
    if [[ -n "$version_path" ]]; then
        amf_include="$(dirname "$(dirname "$version_path")")"
    fi
fi

if [[ -z "$amf_include" ]]; then
    echo "AMF headers not found in $srcdir." >&2
    exit 1
fi

mkdir -p "$PREFIX/include"
if [[ "$(basename "$amf_include")" == "AMF" ]]; then
    cp -R "$amf_include" "$PREFIX/include/"
else
    mkdir -p "$PREFIX/include/AMF"
    cp -R "$amf_include/"* "$PREFIX/include/AMF/"
fi