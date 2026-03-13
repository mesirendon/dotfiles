#!/usr/bin/env bash
set -euo pipefail

echo "👻 Installing Ghostty (Debian/Ubuntu)..."

# ---- detect distro ----
if command -v lsb_release >/dev/null 2>&1; then
	DISTRO="$(lsb_release -si | tr '[:upper:]' '[:lower:]')"
	CODENAME="$(lsb_release -sc)"
	VERSION_ID="$(lsb_release -sr | cut -d. -f1,2 || true)"
else
	. /etc/os-release
	DISTRO="${ID,,}"
	CODENAME="${VERSION_CODENAME:-}"
	VERSION_ID="${VERSION_ID:-}"
fi

ARCH="$(uname -m)"
echo "📦 Detected: ${DISTRO} (${CODENAME:-unknown}) ${VERSION_ID:-} [${ARCH}]"

# ---- shared: build from source ----
build_from_source() {
	echo "🔨 Building Ghostty from source..."

	sudo apt install -y \
		libgtk-4-dev \
		libgtk4-layer-shell-dev \
		libadwaita-1-dev \
		gettext \
		libxml2-utils \
		pkg-config \
		git

	WORKDIR="$(mktemp -d)"
	trap 'rm -rf "$WORKDIR"' EXIT

	echo "⬇️ Downloading Ghostty source tarball..."
	curl -fsSL "https://github.com/ghostty-org/ghostty/releases/download/tip/ghostty-source.tar.gz" \
		-o "${WORKDIR}/ghostty-source.tar.gz"

	mkdir -p "${WORKDIR}/ghostty"
	tar -xf "${WORKDIR}/ghostty-source.tar.gz" -C "${WORKDIR}/ghostty" --strip-components=1

	ZIG_VERSION="$(grep 'minimum_zig_version' "${WORKDIR}/ghostty/build.zig.zon" | sed 's/.*"\(.*\)".*/\1/')"
	echo "🔍 Ghostty requires Zig ${ZIG_VERSION}"

	case "$ARCH" in
	x86_64) ZIG_TARBALL="zig-x86_64-linux-${ZIG_VERSION}.tar.xz" ;;
	aarch64 | arm64 | armv8l) ZIG_TARBALL="zig-aarch64-linux-${ZIG_VERSION}.tar.xz" ;;
	*)
		echo "❌ Unsupported CPU arch for source build: ${ARCH}"
		exit 1
		;;
	esac

	echo "⬇️ Downloading Zig ${ZIG_VERSION} (${ARCH})..."
	curl -fsSL "https://ziglang.org/download/${ZIG_VERSION}/${ZIG_TARBALL}" -o "${WORKDIR}/${ZIG_TARBALL}"
	mkdir -p "${WORKDIR}/zig"
	tar -xf "${WORKDIR}/${ZIG_TARBALL}" -C "${WORKDIR}/zig" --strip-components=1
	ZIG="${WORKDIR}/zig/zig"

	PREFIX="${PREFIX:-$HOME/.local}"
	echo "🛠 Building + installing to: ${PREFIX}"
	cd "${WORKDIR}/ghostty"
	"${ZIG}" build -p "${PREFIX}" -Doptimize=ReleaseFast

	echo "✅ Ghostty installed from source."
	echo "ℹ️  Ensure ${PREFIX}/bin is on your PATH."
}

sudo apt update -y
sudo apt install -y curl gpg apt-transport-https ca-certificates tar xz-utils

# ---- Debian ----
if [[ "$DISTRO" == "debian" ]]; then
	echo "➡️ Setting up debian.griffo.io repository..."

	if [[ ! -f /etc/apt/trusted.gpg.d/debian.griffo.io.gpg ]]; then
		sudo sh -c 'curl -fsSL https://debian.griffo.io/EA0F721D231FDD3A0A17B9AC7808B4DD62C41256.asc \
      | gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/debian.griffo.io.gpg'
	fi

	echo "deb https://debian.griffo.io/apt ${CODENAME:-bookworm} main" |
		sudo tee /etc/apt/sources.list.d/debian.griffo.io.list >/dev/null

	sudo apt update -y

	if sudo apt install -y ghostty 2>/dev/null; then
		echo "✅ Ghostty installed from debian.griffo.io."
		exit 0
	fi

	echo "⚠️  debian.griffo.io has no package for ${ARCH}; falling back to source build..."
	build_from_source
	exit 0
fi

# ---- Ubuntu ----
if [[ "$DISTRO" == "ubuntu" ]]; then
	if [[ "${VERSION_ID:-}" == "24.04" || "${CODENAME:-}" == "noble" || \
		"${VERSION_ID:-}" == "25.10" || "${CODENAME:-}" == "questing" ]]; then
		echo "➡️ Trying mkasberg/ghostty-ubuntu installer..."
		if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh)"; then
			echo "✅ Ghostty installed via mkasberg/ghostty-ubuntu."
			exit 0
		fi
		echo "⚠️  mkasberg installer failed; falling back to source build..."
	else
		echo "➡️ Ubuntu ${VERSION_ID:-?} not supported by mkasberg; falling back to source build..."
	fi

	build_from_source
	exit 0
fi

echo "❌ Unsupported distribution: ${DISTRO}"
exit 1
