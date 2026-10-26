#!/usr/bin/env bash
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export HOMEBREW_NO_AUTO_UPDATE=1
BOOTSTRAP_START=$SECONDS

usage() {
  cat <<EOF
Usage: $(basename "$0") [--server]

  --server    Headless install: skip Homebrew casks (GUI apps, fonts) and
              Ghostty (install, config and shaders).
  -h, --help  Show this help.
EOF
}

SERVER=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --server) SERVER=true ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

timer() {
  local label="$1"; shift
  local start=$SECONDS
  local rc=0
  "$@" || rc=$?
  printf '  ⏱  %s: %ds\n' "$label" "$(( SECONDS - start ))"
  return $rc
}

bundle() {
  local file="$1"
  if [[ "$SERVER" == true ]]; then
    { grep -v '^[[:space:]]*cask ' "$file" || true; } | brew bundle --file=- --verbose
  else
    brew bundle --file="$file" --verbose
  fi
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
if [[ "$SERVER" == true ]]; then
  echo "===> 🖥️  Server mode: skipping casks and Ghostty"
fi

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
timer "brew bundle" bundle "$REPO_DIR/Brewfile" || echo "⚠️  Some Homebrew packages failed — check output above before continuing"

echo "===> 📥 Stowing dotfiles (dry-run)"
DOTFILES=("git" "zsh" "p10k" "nvim" "bin" "taskwarrior" "zellij")
if [[ "$SERVER" == false ]]; then
  DOTFILES+=("ghostty")
fi
(cd "$REPO_DIR" && stow -nv "${DOTFILES[@]}") || true
read -p "Proceed stowing dotfiles? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
  (cd "$REPO_DIR" && stow -v "${DOTFILES[@]}")
fi

if [[ "$PLATFORM" == "macos" ]]; then
  echo "==> 🍎 Brew bundle (mac)"
  timer "brew bundle (mac)" bundle "$REPO_DIR/Brewfile.mac" || echo "⚠️  Some macOS Homebrew packages failed — check output above before continuing"
elif [[ "$PLATFORM" == "Debian" && "$SERVER" == false ]]; then
  timer "ghostty-linux" "$REPO_DIR/scripts/ghostty-linux.sh" || echo "⚠️  Ghostty Linux install failed — check output above"
fi

echo "===> 💿 Installing Oh My ZSH"
timer "oh-my-zsh" "$REPO_DIR/scripts/oh-my-zsh.sh"

echo "===> 🚀 Running post-install scripts"
if [[ "$SERVER" == false ]]; then
  timer "ghostty" "$REPO_DIR/scripts/ghostty.sh" || echo "⚠️  Ghostty config failed — check output above"
fi
timer "zellij" "$REPO_DIR/scripts/zellij.sh" || echo "⚠️  Zellij setup failed — check output above"
timer "claude-code" "$REPO_DIR/scripts/claude-code.sh" || echo "⚠️  Claude Code install failed — check output above"
timer "luarocks" "$REPO_DIR/scripts/luarocks.sh" || echo "⚠️  luarocks 5.1 config failed — check output above"

printf '\n===> 💻 Installation Finished in %ds\n' "$(( SECONDS - BOOTSTRAP_START ))"
echo "===> 🔃 Restart your computer for the changes to take effect 🔃 <==="
