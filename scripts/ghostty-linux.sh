#!/usr/bin/env bash
set -euo pipefail

echo "👻 Installing Ghostty terminal emulator..."

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

	echo "✅ Ghostty installed from debian.griffo.io."

elif [[ "$DISTRO" == "ubuntu" ]]; then
	echo "➡️ Setting up Ghostty Ubuntu package repository..."

	sudo mkdir -p /etc/apt/keyrings
	curl -fsSL https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh |
		grep "gpgkey" -A1 | grep -o "https://.*\.asc" |
		sudo gpg --dearmor -o /etc/apt/keyrings/ghostty.gpg || true

	echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/ghostty.gpg] \
    https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/ ${CODENAME} main" |
		sudo tee /etc/apt/sources.list.d/ghostty.list >/dev/null

	sudo apt update -y
	sudo apt install -y ghostty

	echo "✅ Ghostty installed via ghostty-ubuntu .deb repository."

else
	echo "❌ Unsupported distribution: ${DISTRO}"
	echo "This installer supports Debian and Ubuntu only."
	exit 1
fi

echo
echo "🎉 Installation complete! Run: ghostty"
