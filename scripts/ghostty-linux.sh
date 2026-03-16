#!/usr/bin/env bash
set -euo pipefail

if command -v ghostty >/dev/null 2>&1; then
	printf '\t---> ✅ Ghostty is already installed\n'
	ghostty --version || true
	exit 0
fi

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

# ---- shared: verify OpenGL support ----
check_opengl() {
	if ! command -v glxinfo >/dev/null 2>&1; then
		echo "⚠️  glxinfo not found — cannot verify OpenGL support."
		echo "   Install mesa-utils and re-run, or set GSK_RENDERER=cairo if Ghostty fails to launch."
		return
	fi

	if glxinfo -B 2>/dev/null | grep -qi "opengl renderer"; then
		echo "✅ OpenGL support detected."
	else
		echo "⚠️  No working OpenGL detected (common on ARM64 VMs without GPU passthrough)."
		echo "   Ghostty/GTK4 needs a renderer. Setting up cairo (software) fallback..."

		local marker="# GSK_RENDERER fallback for Ghostty (no OpenGL)"
		local zshrc="$HOME/.zshrc"
		if [[ -f "$zshrc" ]] && grep -qF "$marker" "$zshrc"; then
			echo "   GSK_RENDERER=cairo already configured in .zshrc"
		else
			{
				echo ""
				echo "$marker"
				echo 'if [[ "$(uname -m)" == "aarch64" ]] && ! glxinfo -B 2>/dev/null | grep -qi "opengl renderer"; then'
				echo '	export GSK_RENDERER=cairo'
				echo 'fi'
			} >> "$zshrc"
			echo "   Added GSK_RENDERER=cairo fallback to $zshrc"
		fi
		echo ""
		echo "   Note: cairo disables GPU acceleration and custom shaders."
		echo "   If you later add GPU support, remove the GSK_RENDERER block from .zshrc."
	fi
}

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
	curl -fsSL --connect-timeout 15 --max-time 300 "https://github.com/ghostty-org/ghostty/releases/download/tip/ghostty-source.tar.gz" \
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
	curl -fsSL --connect-timeout 15 --max-time 300 "https://ziglang.org/download/${ZIG_VERSION}/${ZIG_TARBALL}" -o "${WORKDIR}/${ZIG_TARBALL}"
	mkdir -p "${WORKDIR}/zig"
	tar -xf "${WORKDIR}/${ZIG_TARBALL}" -C "${WORKDIR}/zig" --strip-components=1
	ZIG="${WORKDIR}/zig/zig"

	PREFIX="${PREFIX:-$HOME/.local}"
	echo "🛠 Building + installing to: ${PREFIX}"
	cd "${WORKDIR}/ghostty"
	"${ZIG}" build -p "${PREFIX}" -Doptimize=ReleaseFast

	echo "✅ Ghostty installed from source."
	echo "ℹ️  Ensure ${PREFIX}/bin is on your PATH."
	check_opengl
}

sudo apt install -y curl gpg apt-transport-https ca-certificates tar xz-utils \
	libgl1-mesa-dri libegl-mesa0 libegl1 mesa-utils

# ---- Debian ----
if [[ "$DISTRO" == "debian" ]]; then
	echo "➡️ Setting up debian.griffo.io repository..."

	if [[ ! -f /etc/apt/trusted.gpg.d/debian.griffo.io.gpg ]]; then
		sudo sh -c 'curl -fsSL --connect-timeout 15 --max-time 120 https://debian.griffo.io/EA0F721D231FDD3A0A17B9AC7808B4DD62C41256.asc \
      | gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/debian.griffo.io.gpg'
	fi

	echo "deb https://debian.griffo.io/apt ${CODENAME:-bookworm} main" |
		sudo tee /etc/apt/sources.list.d/debian.griffo.io.list >/dev/null

	sudo apt update -y

	if sudo apt install -y ghostty 2>/dev/null; then
		echo "✅ Ghostty installed from debian.griffo.io."
		check_opengl
		exit 0
	fi

	echo "⚠️  debian.griffo.io has no package for ${ARCH}; falling back to source build..."
	build_from_source
	exit 0
fi

# ---- Ubuntu ----
if [[ "$DISTRO" == "ubuntu" ]]; then
	if [[ "${VERSION_ID:-}" == "22.04" || "${CODENAME:-}" == "jammy" || \
		"${VERSION_ID:-}" == "24.04" || "${CODENAME:-}" == "noble" || \
		"${VERSION_ID:-}" == "25.04" || "${CODENAME:-}" == "plucky" || \
		"${VERSION_ID:-}" == "25.10" || "${CODENAME:-}" == "questing" ]]; then
		echo "➡️ Trying mkasberg/ghostty-ubuntu installer..."
		if /bin/bash -c "$(curl -fsSL --connect-timeout 15 --max-time 120 https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh)"; then
			echo "✅ Ghostty installed via mkasberg/ghostty-ubuntu."
			check_opengl
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
