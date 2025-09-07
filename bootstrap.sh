#!/usr/bin/env bash
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo -v || {
  echo "Need sudo to proceed"
  exit 1
}

echo "===> 💻 Detecting OS"
OS="$(uname -s)"

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

echo "===> Platform detected: $PLATFORM"

if [[ "$PLATFORM" == "Debian" ]]; then
  echo "===> 🐧 Installing Debian/Ubuntu Prerequisites"
  "$REPO_DIR/scripts/apt.sh"
fi

if [[ "$PLATFORM" == "macos" ]]; then
  BREW_PREFIX="/opt/homebrew"
else
  BREW_PREFIX="/home/linuxbrew/.linuxbrew"
fi

if [[ ! -d "$BREW_PREFIX" ]]; then
  echo "===> 🍺 Installing Homebrew"
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  printf '\t---> ✅ Homebrew is already installed\n'
fi

if [[ "$PLATFORM" == "Debian" ]]; then
  "$REPO_DIR/scripts/linuxbrew.sh"
fi

eval "$("$BREW_PREFIX/bin/brew" shellenv)"

echo "===> 🍻 Installing Brew Bundle"
BFILE="$REPO_DIR/Brewfile"

i=0
total=$(grep -Ev '^[[:space:]]*($|#)' "$BFILE" | wc -l)

while IFS= read -r pkg; do
  [ -z "$pkg" ] && continue
  case "$pkg" in \#*) continue ;; esac
  i=$((i + 1))
  echo "[$i/$total] ⏳ Installing $pkg..."
  brew install --quiet "$pkg" || true
done <"$BFILE"

if [[ "$PLATFORM" == "macos" ]]; then
  echo "==> 🍎 Brew bundle (mac)"
  brew bundle --file="$REPO_DIR/Brewfile.mac" --verbose || true
fi

echo "===> 📥 Stowing dotfiles (dry-run)"
DOTFILES=("git" "zsh" "p10k" "tmux" "nvim" "bin")
(cd "$REPO_DIR" && stow -nv "${DOTFILES[@]}") || true
read -p "Proceed stowing dotfiles? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
  (cd "$REPO_DIR" && stow -v "${DOTFILES[@]}")
fi

"$REPO_DIR/scripts/oh-my-zsh.sh"
brew install --cask font-meslo-lg-nerd-font

echo "===> 💿 Installing tmux plugins"
"$REPO_DIR/scripts/tmux.sh"

echo "===> 💻 Installation Finished"
echo "===> 🔃 Restart your computer for the changes to take effect 🔃 <==="
