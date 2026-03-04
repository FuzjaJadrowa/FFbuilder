#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

require_env() {
    local var
    for var in "$@"; do
        if [[ -z "${!var:-}" ]]; then
            echo "Missing required env var: $var" >&2
            exit 1
        fi
    done
}

fetch_repo() {
    local name="$1"
    local url="$2"
    local no_filter="${3:-0}"
    local dir="$SRC/$name"
    if [[ ! -d "$dir/.git" ]]; then
        if [[ "$no_filter" == "1" ]]; then
            git clone --depth 1 "$url" "$dir"
        else
            git clone --filter=blob:none --depth 1 "$url" "$dir"
        fi
    else
        git -C "$dir" fetch --depth 1 origin || true
    fi
}

ensure_configure() {
    local dir="$1"
    if [[ -f "$dir/configure" ]]; then
        return
    fi
    if [[ -x "$dir/autogen.sh" ]]; then
        (cd "$dir" && ./autogen.sh)
        return
    fi
    if [[ -x "$dir/bootstrap" ]]; then
        (cd "$dir" && ./bootstrap)
        return
    fi
    if [[ -x "$dir/bootstrap.sh" ]]; then
        (cd "$dir" && ./bootstrap.sh)
        return
    fi
    echo "Missing configure script in $dir (no autogen/bootstrap found)." >&2
    exit 1
}