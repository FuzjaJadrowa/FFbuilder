#!/usr/bin/env bash
set -euo pipefail

if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew is required on macOS." >&2
    exit 1
fi

brew update
brew install \
    autoconf \
    automake \
    cmake \
    git \
    libtool \
    meson \
    nasm \
    ninja \
    pkg-config \
    python \
    yasm \
    zip
