#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
sudo apt update
grep -Ev '^[[:space:]]*(#|$)' "$SCRIPT_DIR/../Aptfile" | xargs sudo apt install -y
