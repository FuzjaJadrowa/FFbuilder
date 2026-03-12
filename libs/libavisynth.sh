#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

echo "AviSynth headers are system-provided (Windows). Install SDK to PREFIX/include. Skipping build." >&2
exit 0