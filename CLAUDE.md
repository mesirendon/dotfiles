# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a personal dotfiles repository managed with [GNU Stow](https://www.gnu.org/software/stow/). It automates installation of tools and symlinking of configuration files across Debian/Ubuntu Linux and macOS (Intel and Apple Silicon).

## Bootstrap

Run the full setup from scratch:

```bash
./bootstrap.sh
```

The script auto-detects OS/architecture and runs the appropriate steps. It requires `sudo` and interactive confirmation before stowing files.

### Individual scripts (called by bootstrap.sh)

| Script | Purpose |
|---|---|
| `scripts/apt.sh` | Install packages from `Aptfile` via apt |
| `scripts/linuxbrew.sh` | Configure Linuxbrew on Debian |
| `scripts/ghostty-linux.sh` | Install Ghostty terminal on Linux |
| `scripts/ghostty.sh` | Configure Ghostty settings |
| `scripts/oh-my-zsh.sh` | Install Oh My Zsh |
| `scripts/fonts.sh` | Install fonts |
| `scripts/zellij.sh` | Install Zellij plugins (room.wasm) |
| `scripts/claude-code.sh` | Install Claude Code CLI |

## Stow Packages

Each top-level directory is a Stow package that maps to `$HOME`. Managed packages:

- `git` — `.gitconfig`
- `zsh` — `.zshrc`
- `p10k` — Powerlevel10k prompt config
- `nvim` — Neovim config (LazyVim-based, at `.config/nvim/`)
- `bin` — Personal scripts at `.bin/` (`codews2tmux`, `codews2zellij`, `lambdaenvvars`)
- `taskwarrior` — Task manager config
- `ghostty` — Terminal emulator config and shaders
- `zellij` — Terminal multiplexer config and plugins

To dry-run stowing (preview symlinks):

```bash
stow -nv <package>
```

To apply:

```bash
stow -v <package>
```

To unstow:

```bash
stow -Dv <package>
```

## Package Management

- **Debian/Ubuntu**: `Aptfile` (installed via `apt`)
- **All platforms (x86_64)**: `Brewfile` (installed via Homebrew)
- **arm64 Linux**: `Brewfile.arm64` (reduced set; apt covers what Homebrew doesn't build for arm64)
- **macOS only**: `Brewfile.mac` (GUI apps and macOS-specific tools via casks)

When adding a new tool, update the appropriate file(s) based on platform availability.

## Architecture

```
.dotfiles/
├── bootstrap.sh        # Main entry point
├── Aptfile             # apt packages (Debian/Ubuntu)
├── Brewfile            # Homebrew formulae (all platforms)
├── Brewfile.arm64      # Reduced Homebrew set for arm64 Linux
├── Brewfile.mac        # macOS-only casks and formulae
├── scripts/            # Modular install scripts
├── git/                # Stow package
├── zsh/                # Stow package
├── nvim/               # Stow package (LazyVim)
├── ghostty/            # Stow package
├── zellij/             # Stow package
├── bin/                # Stow package (personal scripts)
├── taskwarrior/        # Stow package
└── p10k/               # Stow package
```

## Key Conventions

- Scripts use `set -euo pipefail` and detect `REPO_DIR` relative to `BASH_SOURCE[0]`.
- Git commits are SSH-signed (`gpg.format = ssh`).
- `autoSetupRemote = true` — no need to specify upstream on first push.
- HTTPS GitHub URLs are rewritten to SSH via `url."git@github.com:".insteadOf`.
