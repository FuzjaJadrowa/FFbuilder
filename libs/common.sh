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
    if command -v "$tool" >/dev/null 2>&1; then
        command -v "$tool"
    else
        printf '%s' "$tool"
    fi
}