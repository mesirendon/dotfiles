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

if [[ "$PLATFORM" == "debian" ]]; then
	echo "===> Installing Debian/Ubuntu Prerequisites"
	"$REPO_DIR/scripts/apt.sh"
fi

echo "===> Installing Homebrew"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$($(command -v brew) shellenv)"

echo "===> Installing Brew Bundle"
brew bundle --file="$REPO_DIR/Brewfile" --verbose

echo "===> Stowing dotfiles (dry-run)"
( cd "$REPO_DIR" && stow -nv git ) || true
read -p "Proceed stowing dotfiles? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
	( cd "$REPO_DIR" && stow -v git )
fi

exec $SHELL
echo "===> Installation Finished"
