#!/usr/bin/env bash
set -euo pipefail

echo "👻 Installing Ghostty terminal emulator (Debian / Ubuntu)..."

if command -v lsb_release >/dev/null 2>&1; then
	DISTRO="$(lsb_release -si | tr '[:upper:]' '[:lower:]')" # “ubuntu” or “debian”
	CODENAME="$(lsb_release -sc)"
else
	. /etc/os-release
	DISTRO="${ID,,}"
	CODENAME="${VERSION_CODENAME:-bookworm}"
fi

echo "📦 Detected distribution: ${DISTRO} (${CODENAME})"

sudo apt update -y
sudo apt install -y curl gpg apt-transport-https

if [[ "$DISTRO" == "debian" ]]; then
	echo "➡️ Setting up repository from debian.griffo.io..."

	if [[ ! -f /etc/apt/trusted.gpg.d/debian.griffo.io.gpg ]]; then
		sudo sh -c 'curl -fsSL https://debian.griffo.io/EA0F721D231FDD3A0A17B9AC7808B4DD62C41256.asc \
      | gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/debian.griffo.io.gpg'
	fi

	echo "deb https://debian.griffo.io/apt ${CODENAME} main" |
		sudo tee /etc/apt/sources.list.d/debian.griffo.io.list >/dev/null

	sudo apt update -y
	sudo apt install -y ghostty

	echo "✅ Ghostty installed successfully from debian.griffo.io."

elif [[ "$DISTRO" == "ubuntu" ]]; then
	echo "➡️ Installing Ghostty via mkasberg/ghostty-ubuntu installer..."

	# Run the official script directly
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh)"

	echo "✅ Ghostty installed successfully via mkasberg/ghostty-ubuntu."

# ---------------------------------------------------------------------
# ❌ Unsupported distro
# ---------------------------------------------------------------------
else
	echo "❌ Unsupported distribution: ${DISTRO}"
	echo "This script supports Debian and Ubuntu only."
	exit 1
fi

echo "🎉 Installation complete!"
