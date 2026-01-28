#!/usr/bin/env bash
set -euo pipefail

ZELLIJ_PLUGINS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/zellij/plugins"
mkdir -p "$ZELLIJ_PLUGINS_DIR"

install_room() {
	local dest="$ZELLIJ_PLUGINS_DIR/room.wasm"
	echo "🔌 Installing Zellij plugin: room -> $dest"
	curl -fsSL "https://github.com/rvcas/room/releases/latest/download/room.wasm" -o "$dest"
}

install_room
echo "✅ Zellij plugins installed."
