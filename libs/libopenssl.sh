#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

OPENSSL_VERSION="${OPENSSL_VERSION:-3.3.2}"
OPENSSL_URL="${OPENSSL_URL:-https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz}"

srcdir="$SRC/openssl-$OPENSSL_VERSION"
tarball="$SRC/openssl-$OPENSSL_VERSION.tar.gz"
ensure_tarball "$OPENSSL_URL" "$tarball" "$srcdir"

arch="$(uname -m)"
if [[ "$arch" == "arm64" ]]; then
    arch="aarch64"
fi

case "$TARGET_INPUT" in
    linux)
        if [[ "$arch" == "aarch64" ]]; then
            openssl_target="linux-aarch64"
        else
            openssl_target="linux-x86_64"
        fi
        ;;
    macos)
        if [[ "$arch" == "aarch64" ]]; then
            openssl_target="darwin64-arm64-cc"
        else
            openssl_target="darwin64-x86_64-cc"
        fi
        ;;
    windows)
        openssl_target="mingw64"
        ;;
    *)
        echo "Unsupported target for OpenSSL: $TARGET_INPUT" >&2
        exit 1
        ;;
 esac

cd "$srcdir"
make clean >/dev/null 2>&1 || true

perl ./Configure "$openssl_target" \
    no-shared no-dso no-tests \
    --prefix="$PREFIX" --libdir=lib

make -j"$NPROC"
make install_sw