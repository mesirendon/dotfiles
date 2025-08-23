#!/usr/bin/env bash
set -euo pipefail
sudo apt update
xargs -a "$HOME/dotfiles/Aptfile" sudo apt install -y
