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
| `scripts/kitty.sh` | Install Kitty terminal on Linux |
| `scripts/zellij.sh` | Install Zellij plugins (room.wasm) |
| `scripts/claude-code.sh` | Install Claude Code CLI |
| `scripts/tmux.sh` | Install TPM and tmux plugins (not called by bootstrap) |

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

- **Debian/Ubuntu**: `Aptfile` (system-level packages: build tools, zsh, git, gpg, GUI apps)
- **All platforms**: `Brewfile` (all CLI tools — single source of truth across macOS and Linux, both amd64 and arm64)
- **macOS only**: `Brewfile.mac` (GUI apps and macOS-specific tools via casks)

When adding a new tool, update the appropriate file(s) based on platform availability.

## Architecture

```
.dotfiles/
├── bootstrap.sh        # Main entry point
├── Aptfile             # apt packages (Debian/Ubuntu)
├── Brewfile            # Homebrew formulae (all platforms and architectures)
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

## Neovim Architecture

LazyVim is the base distribution (`branch = "stable"`). Custom config lives under `nvim/.config/nvim/lua/`:

| File/Dir | Purpose |
|---|---|
| `config/lazy.lua` | Lazy.nvim bootstrap; LazyVim pinned to `stable` branch |
| `config/extras.lua` | LazyVim extras (nvim-cmp, mini-surround, mini-comment, gitui, aerial, rest, claudecode) |
| `config/keymaps.lua` | All custom keymaps; Go/GoMod/PlantUML groups registered with which-key |
| `config/options.lua` | Editor options (`fixendofline`); **do not re-add `autowriteall`** — auto-save is handled by `autocmds.lua` |
| `config/autocmds.lua` | Smart auto-save on `BufLeave`/`WinLeave`/`FocusLost` (skips non-file buffers) |
| `plugins/ide.lua` | Mason tools, LSP servers, conform.nvim formatters, nvim-lint, DAP/dap-ui for Go |
| `plugins/treesitter.lua` | Parser list; uses `v:lua.vim.treesitter.foldexpr()` (modern API) |
| `plugins/dashboard.lua` | Snacks dashboard; chafa image preview is guarded by `filereadable` |
| `plugins/colorscheme.lua` | Nord theme; no day/night logic |
| `plugins/test.lua` | Neotest with neotest-golang |
| `plugins/octo.lua` | GitHub PR/Issue management |
| `plugins/plantuml.lua` | PlantUML preview with live-reload autocmd |
| `plugins/abolish.lua` | vim-abolish case coercion (`cr*` keymaps) |
| `plugins/claudecode.lua` | Claude Code Neovim integration |
| `plugins/colorizer.lua` | Color highlighting (CSS, HTML, JS, Lua) |
| `plugins/image.lua` | Image rendering via Kitty protocol |
| `plugins/luasnip.lua` | Snippet engine; Go template snippets in `snippets/gotmpl.lua` |
| `plugins/ui-select.lua` | Dressing.nvim for improved `vim.ui.select`/`vim.ui.input` |

### LSP / Tooling Coverage

| Language | LSP | Formatter | Linter |
|---|---|---|---|
| Go | gopls | gofumpt, goimports | golangci-lint |
| TypeScript/JS | vtsls | prettierd | eslint_d |
| Lua | lua-language-server | stylua | — |
| Bash/Shell | bash-language-server | shfmt | shellcheck |
| YAML | yaml-language-server | prettierd | — |
| Docker | dockerls | — | — |

### Key Neovim Rules

- **Do not add `none-ls`** — formatting/linting are handled by `conform.nvim` + `nvim-lint`. Adding `none-ls` causes double-format conflicts.
- **Do not add `autowriteall`/`autowrite` to `options.lua`** — the smart auto-save autocmd in `autocmds.lua` already covers this safely.
- Completion engine is **nvim-cmp** (loaded via `extras.lua`). Do not add blink.cmp.
- Go keymaps use `<localleader>t*` (test), `<localleader>d*` (debug), `<localleader>l*` (lint). GoMod uses `<localleader>g*`. PlantUML uses `<localleader>u*`.
- Octo (GitHub) keymaps use `<leader>o*` — `<leader>op*` for PRs, `<leader>oi*` for Issues.
- Abolish case coercion: `cr*` keymaps (crs=snake, crc=camel, crm=PascalCase, cru=UPPER, cr-=kebab).
- Dashboard image (`~/.config/nvim/home.jpg`) is optional — startup works without it.
- **Go test `-race` is probe-gated** — `test.lua` runs `go build -race -o /dev/null std` at startup to verify the race detector actually works before adding `-race`. This catches all failure modes (missing gcc, ABI/linker incompatibility, unsupported platform). Do not hardcode `-race` unconditionally or regress to a simple `go env CGO_ENABLED` check.

## Ghostty Linux Installation

`scripts/ghostty-linux.sh` uses a tiered approach:
1. **Debian**: tries `debian.griffo.io` apt repo → falls back to source build
2. **Ubuntu 22.04/24.04/25.04/25.10**: tries `mkasberg/ghostty-ubuntu` → falls back to source build
3. **Source build**: downloads Ghostty tarball, reads `minimum_zig_version` from `build.zig.zon`, fetches correct Zig, builds with `zig build -p ~/.local`

When adding new Ubuntu LTS support, update the version check in `ghostty-linux.sh` and verify mkasberg supports it first.

## Key Conventions

- Scripts use `set -euo pipefail` and detect `REPO_DIR` relative to `BASH_SOURCE[0]`.
- Git commits are SSH-signed (`gpg.format = ssh`).
- `autoSetupRemote = true` — no need to specify upstream on first push.
- HTTPS GitHub URLs are rewritten to SSH via `url."git@github.com:".insteadOf`.
- `tmux/` directory exists but is deprecated — not stowed and not listed in `bootstrap.sh`.
- `bin/.bin/` personal scripts: `codews2zellij` (VS Code workspace → Zellij session), `lambdaenvvars` (AWS Lambda env → `.env` file), `codews2tmux` (deprecated).
