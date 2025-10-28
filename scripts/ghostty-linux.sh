#!/usr/bin/env bash
set -euo pipefail

echo "👻 Installing Ghostty terminal emulator (Linux only)..."

if command -v lsb_release >/dev/null 2>&1; then
  CODENAME="$(lsb_release -sc)"
else
  CODENAME="$(
    . /etc/os-release
    echo "${VERSION_CODENAME:-bookworm}"
  )"
fi

sudo sh -c 'curl -sS https://debian.griffo.io/EA0F721D231FDD3A0A17B9AC7808B4DD62C41256.asc \
  | gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/debian.griffo.io.gpg'

echo "deb https://debian.griffo.io/apt ${CODENAME} main" |
  sudo tee /etc/apt/sources.list.d/debian.griffo.io.list >/dev/null

sudo apt update
sudo apt install -y ghostty
