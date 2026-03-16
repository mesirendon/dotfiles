#!/usr/bin/env bash
set -euo pipefail

echo "===> 🤖 Installing Claude Code"

if command -v claude >/dev/null 2>&1; then
	printf '\t---> ✅ Claude Code is already installed\n'
	claude --version
	exit 0
fi

curl -fsSL --connect-timeout 15 --max-time 120 https://claude.ai/install.sh | bash

if command -v claude >/dev/null 2>&1; then
	printf '\t---> ✅ Claude Code installed successfully\n'
	claude --version
else
	echo "⚠️  Claude Code install script finished but 'claude' is not on PATH."
	echo "    You may need to restart your shell or add ~/.claude/bin to PATH."
fi
