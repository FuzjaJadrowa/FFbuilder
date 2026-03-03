#!/usr/bin/env bash
set -euo pipefail

pacman -S --needed --noconfirm \
    base-devel \
    git \
    mingw-w64-x86_64-toolchain \
    mingw-w64-x86_64-nasm \
    mingw-w64-x86_64-pkg-config \
    mingw-w64-x86_64-yasm \
    zip