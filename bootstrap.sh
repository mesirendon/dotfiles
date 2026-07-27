#!/usr/bin/env bash
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export HOMEBREW_NO_AUTO_UPDATE=1
BOOTSTRAP_START=$SECONDS

timer() {
  local label="$1"; shift
  local start=$SECONDS
  local rc=0
  "$@" || rc=$?
  printf '  ⏱  %s: %ds\n' "$label" "$(( SECONDS - start ))"
  return $rc
}

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
  timer "apt packages" "$REPO_DIR/scripts/apt.sh"
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
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL --connect-timeout 15 --max-time 120 https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
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
timer "brew bundle" brew bundle --file="$REPO_DIR/Brewfile" --verbose || echo "⚠️  Some Homebrew packages failed — check output above before continuing"

echo "===> 📥 Stowing dotfiles (dry-run)"
DOTFILES=("git" "zsh" "p10k" "nvim" "bin" "taskwarrior" "ghostty" "zellij")
(cd "$REPO_DIR" && stow -nv "${DOTFILES[@]}") || true
read -p "Proceed stowing dotfiles? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
  (cd "$REPO_DIR" && stow -v "${DOTFILES[@]}")
fi

if [[ "$PLATFORM" == "macos" ]]; then
  echo "==> 🍎 Brew bundle (mac)"
  timer "brew bundle (mac)" brew bundle --file="$REPO_DIR/Brewfile.mac" --verbose || echo "⚠️  Some macOS Homebrew packages failed — check output above before continuing"
elif [[ "$PLATFORM" == "Debian" ]]; then
  timer "ghostty-linux" "$REPO_DIR/scripts/ghostty-linux.sh" || echo "⚠️  Ghostty Linux install failed — check output above"
fi

echo "===> 💿 Installing Oh My ZSH"
timer "oh-my-zsh" "$REPO_DIR/scripts/oh-my-zsh.sh"

echo "===> 🚀 Running post-install scripts"
timer "ghostty" "$REPO_DIR/scripts/ghostty.sh" || echo "⚠️  Ghostty config failed — check output above"
timer "zellij" "$REPO_DIR/scripts/zellij.sh" || echo "⚠️  Zellij setup failed — check output above"
timer "claude-code" "$REPO_DIR/scripts/claude-code.sh" || echo "⚠️  Claude Code install failed — check output above"
timer "luarocks" "$REPO_DIR/scripts/luarocks.sh" || echo "⚠️  luarocks 5.1 config failed — check output above"

printf '\n===> 💻 Installation Finished in %ds\n' "$(( SECONDS - BOOTSTRAP_START ))"
echo "===> 🔃 Restart your computer for the changes to take effect 🔃 <==="
