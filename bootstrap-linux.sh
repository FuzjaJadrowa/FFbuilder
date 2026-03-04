#!/usr/bin/env bash
set -euo pipefail

sudo apt-get update
sudo apt-get install -y \
    autoconf \
    automake \
    build-essential \
    ca-certificates \
    cmake \
    git \
    libtool \
    libtool-bin \
    meson \
    nasm \
    ninja-build \
    perl \
    pkg-config \
    python3 \
    yasm \
    zip