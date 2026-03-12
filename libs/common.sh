#!/usr/bin/env bash
set -euo pipefail

require_var() {
    local name="$1"
    if [[ -z "${!name:-}" ]]; then
        echo "Missing env $name. Run via build.sh or export it." >&2
        exit 1
    fi
}

for var in ROOT TARGET_INPUT WORK SRC BUILD PREFIX NPROC CC CXX AR RANLIB NM STRIP; do
    require_var "$var"
done

export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PREFIX/share/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
export PATH="$PREFIX/bin:$PATH"

ensure_clone() {
    local dir="$1"
    local repo="$2"
    if [[ ! -d "$dir/.git" ]]; then
        git clone --filter=blob:none "$repo" "$dir"
    fi
}

git_checkout() {
    local dir="$1"
    local ref="$2"
    git -C "$dir" fetch --depth 1 origin "$ref" || true
    git -C "$dir" checkout "$ref"
}

is_windows_host() {
    case "$(uname -s)" in
        MINGW*|MSYS*|CYGWIN*) return 0 ;;
        *) return 1 ;;
    esac
}

is_cross_windows() {
    [[ "$TARGET_INPUT" == "windows" ]] && ! is_windows_host
}

tool_path() {
    local tool="$1"
    if is_windows_host && ! is_cross_windows; then
        if command -v "$tool" >/dev/null 2>&1; then
            local p
            p="$(command -v "$tool")"
            if [[ -x "${p}.exe" ]]; then
                cygpath -w "${p}.exe"
                return
            fi
            if [[ -x "$p" ]]; then
                cygpath -w "$p"
                return
            fi
        fi
        printf '%s' "$tool"
        return
    fi
    if command -v "$tool" >/dev/null 2>&1; then
        command -v "$tool"
    else
        printf '%s' "$tool"
    fi
}

fetch_url() {
    local url="$1"
    local dest="$2"
    if command -v curl >/dev/null 2>&1; then
        curl -L -o "$dest" "$url"
        return
    fi
    if command -v wget >/dev/null 2>&1; then
        wget -O "$dest" "$url"
        return
    fi
    echo "Missing curl/wget to download $url" >&2
    exit 1
}

ensure_tarball() {
    local url="$1"
    local tarball="$2"
    local out_dir="$3"
    local strip="${4:-0}"
    if [[ -d "$out_dir" ]]; then
        return
    fi
    mkdir -p "$(dirname "$tarball")"
    if [[ ! -f "$tarball" ]]; then
        fetch_url "$url" "$tarball"
    fi
    mkdir -p "$out_dir"
    if [[ "$strip" == "1" ]]; then
        tar -xf "$tarball" -C "$out_dir" --strip-components=1
    else
        tar -xf "$tarball" -C "$(dirname "$out_dir")"
    fi
}

autotools_prepare() {
    if [[ -x "./autogen.sh" ]]; then
        NOCONFIGURE=1 ./autogen.sh
        return
    fi
    if [[ -f "configure.ac" || -f "configure.in" ]]; then
        autoreconf -fiv
    fi
}