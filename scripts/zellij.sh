#!/usr/bin/env bash
set -euo pipefail

ZELLIJ_PLUGINS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/zellij/plugins"
mkdir -p "$ZELLIJ_PLUGINS_DIR"

install_room() {
	local dest="$ZELLIJ_PLUGINS_DIR/room.wasm"
	# NOTE: Update ROOM_VERSION periodically. Check: https://github.com/rvcas/room/releases
	local version="v1.2.1"
	echo "🔌 Installing Zellij plugin: room ${version} -> $dest"
	curl -fsSL "https://github.com/rvcas/room/releases/download/${version}/room.wasm" -o "$dest"
}

install_room
echo "✅ Zellij plugins installed."
