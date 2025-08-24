#!/usr/bin/env bash
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo echo ""

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
mapfile -t PKGS < <(grep -Ev '^\s*$' "$BFILE")
TOTAL=${#PKGS[@]}
(( TOTAL > 0 )) || { echo "No packages in $BFILE"; exit 0; }

i=0
for pkg in "${PKGS[@]}"; do
	i=$(( i + 1 ))
	printf '[%d/%d] Installing %s...\n' "$i" "$TOTAL" "$pkg"

	if brew list --formula --versions "$pkg" >/dev/null 2>&1; then
		printf '\t---> already installed\n'
	else
		brew install --quiet "$pkg"
	fi
done

echo "===> Stowing dotfiles (dry-run)"
( cd "$REPO_DIR" && stow -nv git ) || true
read -p "Proceed stowing dotfiles? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
	( cd "$REPO_DIR" && stow -v git )
fi

echo "===> Installation Finished"

