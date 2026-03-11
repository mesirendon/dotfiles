#!/usr/bin/env bash
set -euo pipefail

echo "🔠 Installing fonts"

OS="$(uname -s)"

if [[ "$OS" == "Darwin" ]]; then
	brew install --cask font-meslo-lg-nerd-font
	brew install --cask font-fira-code-nerd-font
	brew install --cask font-fira-code
else
	FONT_DIR="$HOME/.local/share/fonts"
	mkdir -p "$FONT_DIR"

	# NOTE: Update NERD_VERSION periodically. Check: https://github.com/ryanoasis/nerd-fonts/releases
	NERD_VERSION="v3.3.0"
	NERD_BASE="https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_VERSION}"

	for font in "Meslo" "FiraCode"; do
		if ls "$FONT_DIR"/*"${font}"* >/dev/null 2>&1; then
			echo "  ✅ ${font} Nerd Font already installed"
			continue
		fi
		echo "  ⬇️ Downloading ${font} Nerd Font..."
		curl -fsSL "${NERD_BASE}/${font}.tar.xz" -o "/tmp/${font}.tar.xz"
		tar -xf "/tmp/${font}.tar.xz" -C "$FONT_DIR"
		rm -f "/tmp/${font}.tar.xz"
	done

	echo "  🔄 Rebuilding font cache..."
	fc-cache -fv "$FONT_DIR"
fi
