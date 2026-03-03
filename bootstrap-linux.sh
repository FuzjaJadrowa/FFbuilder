#!/usr/bin/env bash
set -euo pipefail

sudo apt-get update
sudo apt-get install -y \
    build-essential \
    ca-certificates \
    git \
    nasm \
    pkg-config \
    yasm \
    zip