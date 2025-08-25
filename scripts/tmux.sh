#!/usr/bin/env bash
set -euo pipefail

TPM_DIR="$HOME/.tmux/plugins/tpm"

# Installing TPM if missing
if [[ -d "$TPM_DIR" ]]; then
	echo "===> 💿 Installing Tmux Plugin Manager (TPM)"
	git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
else
	printf '\t---> ✅ TPM is already installed\n'
fi

# Running TPM to fetch plugins
if command -v tmux >/dev/null; then
	echo "===> 💿 Installing tmux plugins via TPM"
	tmux start-server
	tmux new-session -d "exit" || true
	"$TPM_DIR/bin/install_plugins"
	echo "✅ tmux plugins installed"
else
	echo "⚠️  tmux is not installed, skipping plugin setup"
fi
