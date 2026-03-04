#!/usr/bin/env bash
set -euo pipefail

pacman -S --needed --noconfirm \
    autoconf \
    automake \
    base-devel \
    git \
    libtool \
    mingw-w64-x86_64-binutils \
    mingw-w64-x86_64-cmake \
    mingw-w64-x86_64-meson \
    mingw-w64-x86_64-ninja \
    mingw-w64-x86_64-python \
    mingw-w64-x86_64-toolchain \
    mingw-w64-x86_64-nasm \
    mingw-w64-x86_64-pkg-config \
    mingw-w64-x86_64-yasm \
    perl \
    zip