#!/usr/bin/env bash
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export HOMEBREW_NO_AUTO_UPDATE=1

sudo -v || {
  echo "Need sudo to proceed"
  exit 1
}
# Keep sudo session alive for the duration of the script
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

echo "===> 💻 Detecting OS and Architecture"
OS="$(uname -s)"
ARCH="$(uname -m)"

if [[ "$OS" == "Linux" ]]; then
  if [[ -f /etc/debian_version ]]; then
    PLATFORM="Debian"
  else
    echo "Unsupported Linux Distribution"
    exit 1
  fi
elif [[ "$OS" == "Darwin" ]]; then
  PLATFORM="macos"
else
  echo "Unsupported OS: $OS"
  exit 1
fi

echo "===> Platform detected: $PLATFORM ($ARCH)"

if [[ "$PLATFORM" == "Debian" ]]; then
  echo "===> 🐧 Installing Debian/Ubuntu Prerequisites"
  "$REPO_DIR/scripts/apt.sh"
fi

if [[ "$PLATFORM" == "macos" ]]; then
  if [[ "$ARCH" == "arm64" ]]; then
    BREW_PREFIX="/opt/homebrew"
  else
    BREW_PREFIX="/usr/local"
  fi
else
  BREW_PREFIX="/home/linuxbrew/.linuxbrew"
fi

if [[ ! -d "$BREW_PREFIX" ]]; then
  echo "===> 🍺 Installing Homebrew"
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  printf '\t---> ✅ Homebrew is already installed\n'
fi

if command -v brew >/dev/null 2>&1; then
  BREW_BIN="$(command -v brew)"
elif [[ -x /opt/homebrew/bin/brew ]]; then
  BREW_BIN="/opt/homebrew/bin/brew"
elif [[ -x /usr/local/bin/brew ]]; then
  BREW_BIN="/usr/local/bin/brew"
elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  BREW_BIN="/home/linuxbrew/.linuxbrew/bin/brew"
else
  echo "Homebrew installation failed: brew binary not found"
  exit 1
fi

if [[ "$PLATFORM" == "Debian" ]]; then
  "$REPO_DIR/scripts/linuxbrew.sh"
fi

eval "$("$BREW_BIN" shellenv)"

echo "===> 🍻 Installing Brew Bundle"
if [[ "$PLATFORM" == "Debian" && ("$ARCH" == "aarch64" || "$ARCH" == "arm64") ]]; then
  BFILE="$REPO_DIR/Brewfile.arm64"
  echo "    (using reduced Brewfile for arm64 Linux — apt covers the rest)"
else
  BFILE="$REPO_DIR/Brewfile"
fi

brew bundle --file="$BFILE" || true

echo "===> 📥 Stowing dotfiles (dry-run)"
DOTFILES=("git" "zsh" "p10k" "nvim" "bin" "taskwarrior" "ghostty" "zellij")
(cd "$REPO_DIR" && stow -nv "${DOTFILES[@]}") || true
read -p "Proceed stowing dotfiles? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
  (cd "$REPO_DIR" && stow -v "${DOTFILES[@]}")
fi

if [[ "$PLATFORM" == "macos" ]]; then
  echo "==> 🍎 Brew bundle (mac)"
  brew bundle --file="$REPO_DIR/Brewfile.mac" --verbose || true
elif [[ "$PLATFORM" == "Debian" ]]; then
  "$REPO_DIR/scripts/ghostty-linux.sh"
fi

"$REPO_DIR/scripts/ghostty.sh"
"$REPO_DIR/scripts/oh-my-zsh.sh"
"$REPO_DIR/scripts/fonts.sh"

echo "===> 🔌 Installing zellij plugins"
"$REPO_DIR/scripts/zellij.sh"

echo "===> 🤖 Installing Claude Code"
"$REPO_DIR/scripts/claude-code.sh"

echo "===> 💻 Installation Finished"
echo "===> 🔃 Restart your computer for the changes to take effect 🔃 <==="
