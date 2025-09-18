#!/usr/bin/env bash
set -euo pipefail

echo "🐈‍⬛ Installing Kitty terminal emulator (Linux only)..."

# --- Variables ---
KITTY_INSTALL_DIR="${HOME}/.local/kitty.app"
BIN_DIR="${HOME}/.bin/"
APPLICATIONS_DIR="${HOME}/.local/share/applications/"
ICONS_DIR="${HOME}/.local/share/icons/"
DESKTOP_FILE_SOURCE="${KITTY_INSTALL_DIR}/share/applications/kitty.desktop"
OPEN_DESKTOP_FILE_SOURCE="${KITTY_INSTALL_DIR}/share/applications/kitty-open.desktop"
ICON_SOURCE="${KITTY_INSTALL_DIR}/share/icons/hicolor/256x256/apps/kitty.png"

# --- Download and install Kitty ---
echo "📥 Downloading kitty binary..."
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin dest="$KITTY_INSTALL_DIR" launch=n

# --- Symlink binary ---
mkdir -p "$BIN_DIR"
ln -sf "$KITTY_INSTALL_DIR/bin/kitty" "$KITTY_INSTALL_DIR/bin/kitten" "$BIN_DIR"

# --- Install .desktop launcher ---
echo "🖼 Setting up .desktop launcher..."
mkdir -p "$APPLICATIONS_DIR"
mkdir -p "$ICONS_DIR"

# Copy and patch .desktop file
cp "$DESKTOP_FILE_SOURCE" "$APPLICATIONS_DIR"
cp "$OPEN_DESKTOP_FILE_SOURCE" "$APPLICATIONS_DIR"
sed -i "s|Icon=kitty|Icon=$ICON_SOURCE|g" "$APPLICATIONS_DIR/kitty*.desktop"
sed -i "s|Exec=kitty|Exec=$BIN_DIR/kitty|g" "$APPLICATIONS_DIR/kitty*.desktop"
echo 'kitty.desktop' >~/.config/xdg-terminals.list

# --- Completion ---
echo "✅ Kitty installed successfully!"
echo "🏁 You can now launch it from your application menu, or via: kitty"
