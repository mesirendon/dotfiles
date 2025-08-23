#!/usr/bin/env bash
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "===> Detecting OS"
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
	echo "===> Installing Debian/Ubuntu Prerequisites"
	"$REPO_DIR/scripts/apt.sh"
fi

echo "===> Installing Homebrew"
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

if [[ "$PLATFORM" == "macos" ]]; then
	BREW_PREFIX="/opt/homebrew"
else
	BREW_PREFIX="/home/linuxbrew/.linuxbrew"
	"$REPO_DIR/scripts/homebrew.sh"
fi

eval "$("$BREW_PREFIX/bin/brew" shellenv)"

echo "===> Installing Brew Bundle"
BFILE="$REPO_DIR/Brewfile"
TOTAL=$(grep -c '^brew ' "$BFILE")
COUNT=0
while read -r line; do
	[[ "$line" =~ ^brew ]] || continue
	pkg=$(echo "$line" | awk '{print $2}')
	COUNT=$((COUNT+1))
	echo "[$COUNT/$TOTAL] Installing $pkg..."
	brew install "$pkg" || true
done < "$BFILE"

echo "===> Stowing dotfiles (dry-run)"
( cd "$REPO_DIR" && stow -nv git ) || true
read -p "Proceed stowing dotfiles? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
	( cd "$REPO_DIR" && stow -v git )
fi

exec $SHELL
echo "===> Installation Finished"
