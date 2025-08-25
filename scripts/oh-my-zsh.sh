#!/usr/bin/env bash
set -euo pipefail

ZSH_DIR="$HOME/.oh-my-zsh"
ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH_DIR/custom}"

# Install oh my zsh non interactive
if [[ ! -d "$ZSH_DIR" ]]; then
	echo "===> 💿 Installing Oh My ZSH"
	export RUNZSH=no CHSH=no KEEP_ZSHRC=yes
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
	printf '\t---> ✅ Oh My ZSH is already installed\n'
fi

# Install Powerlevel10k theme
if [[ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]]; then
	echo "===> 💿 Installing Powerlevel10k theme"
	git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
else
	printf '\t---> ✅ Powerlevel10k is already installed\n'
fi

# Plugins
plugins=(
	zsh-users/zsh-autosuggestions
	zsh-users/zsh-syntax-highlighting
)

for repo in "${plugins[@]}"; do
	name="${repo##*/}"
	target="$ZSH_CUSTOM/plugins/$name"
	if [[ ! -d "$target" ]]; then
		echo "===> 💿 Installing $name..."
		git clone https://github.com/$repo "$target"
	else
		printf '\t---> ✅ %s is already installed\n' "$name"
	fi
done

# Ensure ZSH is the default shell
if [[ "$SHELL" != *"zsh" ]]; then
	if command -v zsh >/dev/null; then
		echo "===> 💻 Setting zsh as default shell"
		chsh -s "$(command -v zsh)" || echo "⚠️ chsh failed; run manually"
	fi
fi

echo "✅ oh-my-zsh installation completed"
