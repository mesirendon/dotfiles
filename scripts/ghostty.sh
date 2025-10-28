#!/usr/bin/env bash
set -euo pipefail

CFG_DIR="$HOME/.config/ghostty"
SHADERS_DIR="$CFG_DIR/shaders"

mkdir -p "$SHADERS_DIR"

# --- Fetch shaders ---
TMP="$(mktemp -d)"
git clone --depth 1 https://github.com/hackr-sh/ghostty-shaders "$TMP/ghostty-shaders"
cp "$TMP/ghostty-shaders"/cursor_*.glsl "$SHADERS_DIR/" 2>/dev/null || true
rm -rf "$TMP"

# --- Create a default symlink ---
DEFAULT_SHADER="$SHADERS_DIR/cursor_blaze.glsl"
LINK_PATH="$SHADERS_DIR/shader.glsl"

if [ -f "$DEFAULT_SHADER" ]; then
  ln -sf "$DEFAULT_SHADER" "$LINK_PATH"
  echo "🔗 Linked default shader: $LINK_PATH → $(basename "$DEFAULT_SHADER")"
else
  echo "⚠️  No default shader found. You can add one manually under $SHADERS_DIR."
fi

echo "✅ Ghostty installed and configured."
echo "   Config: $CFG_DIR/config"
echo "   Shaders dir: $SHADERS_DIR"
echo "   Active shader: $LINK_PATH"
echo "   To change shader: ln -sf ~/.config/ghostty/shaders/<file>.glsl ~/.config/ghostty/shaders/shader.glsl"
