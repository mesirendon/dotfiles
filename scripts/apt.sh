#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
sudo apt update
xargs -a "$SCRIPT_DIR/../Aptfile" sudo apt install -y
