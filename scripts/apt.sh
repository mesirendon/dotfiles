#!/usr/bin/env bash
set -euo pipefail
sudo apt update
xargs -a "$HOME/dotfiles/Aptfile" sudo apt install -y

test -d ~/.linuxbrew && eval "$(~/.linuxbrew/bin/brew shellenv)"
test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
echo "eval \"\$($(brew --prefix)/bin/brew shellenv)\"" >> ~/.bashrc

