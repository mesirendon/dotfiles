# Dotfiles

<!--toc:start-->
- [Dotfiles](#dotfiles)
  - [Installation](#installation)
    - [Prerequisites](#prerequisites)
    - [Setup](#setup)
  - [Usage](#usage)
    - [Neovim Integrations](#neovim-integrations)
      - [Architecture](#architecture)
      - [Lua Rocks (`luarocks`)](#lua-rocks-luarocks)
      - [Go Development (`go.nvim`)](#go-development-gonvim)
      - [Go mod utilities](#go-mod-utilities)
      - [Testing (`neotest`)](#testing-neotest)
        - [Go extras](#go-extras)
      - [Debugging (`nvim-dap`)](#debugging-nvim-dap)
      - [Go Linting (`nvim-lint` + `golangci-lint`)](#go-linting-nvim-lint--golangci-lint)
      - [LSP (Language Servers)](#lsp-language-servers)
      - [GitHub — Octo (`octo.nvim`)](#github--octo-octonvim)
      - [GitHub Releases (`nvim-ghrelease`)](#github-releases-nvim-ghrelease)
      - [PlantUML (`plantuml-previewer.vim`)](#plantuml-plantuml-previewervim)
      - [Case Coercion (`vim-abolish`)](#case-coercion-vim-abolish)
      - [Text Alignment (`mini.align`)](#text-alignment-minialign)
      - [Symbol Navigation (`aerial.nvim`)](#symbol-navigation-aerialnvim)
      - [Color Highlighting (`nvim-colorizer`)](#color-highlighting-nvim-colorizer)
      - [Image Rendering (`image.nvim`)](#image-rendering-imagenvim)
      - [Snippets (`LuaSnip`)](#snippets-luasnip)
      - [Colorscheme (`catppuccin`)](#colorscheme-catppuccin)
      - [Dashboard (`snacks.nvim`)](#dashboard-snacksnvim)
      - [UI Select/Input (`dressing.nvim`)](#ui-selectinput-dressingnvim)
      - [Bundled Editing Features](#bundled-editing-features)
      - [Claude Code (`claudecode.nvim`)](#claude-code-claudecodenvim)
      - [Treesitter Text-Object Navigation](#treesitter-text-object-navigation)
      - [Auto-save](#auto-save)
      - [Global Shortcuts](#global-shortcuts)
    - [Taskwarrior](#taskwarrior)
      - [Core concepts](#core-concepts)
      - [Common commands](#common-commands)
      - [Configured urgency weights](#configured-urgency-weights)
      - [Date format](#date-format)
      - [TUI (`taskwarrior-tui`)](#tui-taskwarrior-tui)
      - [Color scheme (Nord-inspired)](#color-scheme-nord-inspired)
    - [Shell Helpers](#shell-helpers)
      - [`vimreset` — clean Neovim reinstall](#vimreset--clean-neovim-reinstall)
<!--toc:end-->

This project streamlines the installation of software and configurations I use
daily. It is tailored to my personal workflow and preferences. Pull requests are
welcome, provided they do not conflict with my personal setup.

## Installation

### Prerequisites

- Git must be installed. On Debian/Ubuntu:

  ```bash
  sudo apt install git -y
  ```

### Setup

1. Clone the repository:

   ```bash
   git clone git@github.com:mesirendon/dotfiles.git ~/.dotfiles
   ```

2. Enter the directory:

   ```bash
   cd ~/.dotfiles
   ```

3. Run the bootstrap script (you may be prompted for your password):

   ```bash
   ./bootstrap.sh
   ```

4. Restart your system:

   ```bash
   sudo reboot
   ```

## Usage

### Neovim Integrations

The Neovim config is a **standalone** setup built directly on
[lazy.nvim](https://github.com/folke/lazy.nvim) — no distribution. All config
lives under `nvim/.config/nvim/lua/`.

#### Architecture

| Concern | Choice |
| --- | --- |
| Plugin manager | lazy.nvim |
| Completion | `blink.cmp` + `LuaSnip` |
| Picker / UI | Snacks (picker, explorer, dashboard), which-key, lualine, bufferline, noice |
| LSP | native `vim.lsp.config` / `vim.lsp.enable` + Mason |
| Treesitter | `arborist` (nvim-treesitter disabled) |
| Theme | `catppuccin-mocha` |

**Load order.** `init.lua` loads options (which set `<leader>`) *before*
lazy.nvim, then keymaps/autocmds load on `VeryLazy` once the UI is ready:

```mermaid
flowchart TD
    A[init.lua] --> B["config.options<br/>leaders + editor options"]
    B --> C["config.lazy<br/>bootstrap lazy.nvim"]
    C --> D["require('lazy').setup{ import = 'plugins' }"]
    D --> E["lazy loads every spec in lua/plugins/"]
    E --> F{{User event: VeryLazy}}
    F --> G[config.autocmds]
    F --> H[config.keymaps]
```

**Base specs + extensions, merged by name.** lazy.nvim deep-merges every spec
that shares the same plugin repo name, across all files. Heavy `config`/glue
lives in **base specs**; small **extension files** only add `opts` that merge
upward. This is how you plug new things in without touching the plumbing:

```mermaid
flowchart LR
    subgraph bases [Base specs - own the glue]
        LSP["plugins/lsp.lua<br/>nvim-lspconfig"]
        MAS["plugins/mason.lua<br/>mason"]
        COD["plugins/coding.lua<br/>conform + nvim-lint"]
    end
    subgraph ext [Extensions - opts only]
        IDE["plugins/ide.lua"]
        MD["plugins/markdown.lua"]
    end
    IDE -->|servers| LSP
    MD  -->|servers| LSP
    IDE -->|ensure_installed| MAS
    MD  -->|ensure_installed| MAS
    IDE -->|formatters_by_ft, linters_by_ft| COD
    MD  -->|formatters, linters| COD
```

**LSP pipeline.** Servers are declared as data (`opts.servers`); `plugins/lsp.lua`
turns that into running servers, and keymaps attach per-buffer via
`config/lsp.lua`, gated by what each server supports:

```mermaid
flowchart TD
    S1["ide.lua<br/>servers = { gopls, lua_ls, … }"] --> M[merged opts.servers]
    S2["markdown.lua<br/>servers = { marksman }"] --> M
    M --> C["plugins/lsp.lua config()"]
    C --> D["vim.lsp.config '*' with blink.cmp capabilities"]
    C --> E["loop servers: vim.lsp.config + mason-lspconfig"]
    E --> G["mason installs missing servers"]
    G --> H["server starts on matching filetype"]
    H --> I{{LspAttach}}
    I --> J["config.lsp.on_attach()<br/>gd/gr/K/&lt;leader&gt;ca… + inlay hints"]
```

**Adding new plugins & integrations:**

- **New standalone plugin** — drop a file in `lua/plugins/` returning a lazy
  spec (`{ "author/foo.nvim", opts = {} }`); the whole folder is imported.
- **New LSP server** — add it to `opts.servers` on `nvim-lspconfig` (in `ide.lua`
  or a language file); Mason auto-installs it and attach keymaps come for free.
- **New formatter/linter** — extend `conform.nvim`'s `formatters_by_ft` /
  `nvim-lint`'s `linters_by_ft`, and add the tool to any `mason.nvim`
  `ensure_installed` (lists are concatenated via `opts_extend`, never replaced).
- **New keymaps** — a spec's `keys` field (lazy-loading), `lua/config/keymaps.lua`
  (global), or a `FileType` autocmd (buffer-local; see the Go block).
- **New test/debug language** — add an adapter to the `adapters` registry in
  `lua/plugins/test.lua`; if it needs extra keymaps, add an `ft_extras` entry in
  `lua/config/testing.lua`. The `<leader>t`/`<leader>d` menus themselves are
  language-agnostic and need no change.
- **Extend an existing plugin** — declare a spec with the *same repo name* and
  your `opts`; lazy merges it into the base.
- **Shared helpers** — `require("util").root()`, `require("config.icons").icons`,
  `require("util").on_load(name, fn)` replace the old `LazyVim.*` global.

#### Lua Rocks (`luarocks`)

Neovim embeds **LuaJIT (Lua 5.1)**, so any rock you want to `require()` from your
config must be *built for 5.1* — a rock installed against the system Lua 5.4 will
not load. Homebrew's `luarocks` defaults to the newest Lua it can find, so this
setup pins it to Homebrew's `luajit` (both are in the `Brewfile`).

Rocks are managed **declaratively** from a single manifest,
`nvim/.config/nvim/Rockfile`, which drives both installation and editor docs:

| File | Role |
| --- | --- |
| `nvim/.config/nvim/Rockfile` | The manifest — single source of truth |
| `scripts/luarocks.sh` | Bootstrap: writes `~/.luarocks/config-5.1.lua` pointing at LuaJIT, then installs every rock in the manifest |
| `lua/config/luarocks.lua` | Runtime: appends the luarocks trees to `package.path`/`cpath` so `require()` works, and feeds the same dirs to `lua_ls` |
| `lua/config/rocks.lua` | Docs: turns manifest entries into lazydev LuaCATS stub plugins |

```mermaid
flowchart TD
    RF["Rockfile<br/>luasocket LuaCATS/luasocket socket,mime"]
    RF --> SH["scripts/luarocks.sh<br/>(bootstrap.sh)"]
    RF --> RK["config/rocks.lua"]
    SH --> INST["luarocks --lua-version 5.1 --local install<br/>→ ~/.luarocks"]
    INST --> LR["config/luarocks.lua"]
    LR --> PP["package.path / cpath<br/>require('socket') works"]
    LR --> LS["lua_ls workspace.library<br/>(plugins/ide.lua)"]
    RK --> DEP["lazydev dependencies<br/>(plugins/coding.lua)"]
    RK --> LIB["lazydev library + words<br/>hover & completion docs"]
```

**Manifest format.** Three whitespace-separated columns; `#` comments and blank
lines are ignored. Use `-` to skip an optional column.

```text
# rock        luacats-repo        words
luasocket     LuaCATS/luasocket   socket,mime
```

| Column | Meaning |
| --- | --- |
| `rock` | Name passed to `luarocks --lua-version 5.1 --local install` |
| `luacats-repo` | GitHub repo of [LuaCATS](https://github.com/LuaCATS) annotation stubs, or `-` for none |
| `words` | Comma-separated Lua patterns that load the stubs on demand, or `-` |

**Adding a rock:**

1. Append a line to `nvim/.config/nvim/Rockfile`.
2. Run `./scripts/luarocks.sh` — idempotent, and skips rocks already installed.
3. Restart Neovim; lazy.nvim picks up the new LuaCATS stub repo automatically.

**Removing a rock:** delete its line, then
`luarocks --lua-version 5.1 --local remove <rock>` and `:Lazy clean` to drop the
now-unreferenced stub plugin.

**One-off install** (not persisted to a fresh machine — prefer the Rockfile):

```bash
luarocks --lua-version 5.1 --local install <rock>
```

**Inspecting:**

| Command | Description |
| --- | --- |
| `luarocks --lua-version 5.1 list` | Rocks installed for LuaJIT |
| `:lua print(require("socket")._VERSION)` | Confirm a rock loads inside Neovim |
| `:lua vim.print(require("config.luarocks").lua_ls_library())` | Dirs handed to `lua_ls` |
| `:lua vim.print(require("config.rocks").entries())` | Parsed manifest |

Every step degrades gracefully: `scripts/luarocks.sh` exits cleanly if `brew`,
`luajit`, or `luarocks` is missing, and `config/luarocks.lua` returns empty
values when `luarocks` is not on `PATH` — so the config still loads on a machine
without any of it.

> Rocks install into `~/.luarocks`, **outside** Neovim's state dirs, so they are
> not affected by [`vimreset`](#vimreset--clean-neovim-reinstall). The LuaCATS
> stub plugins live under `~/.local/share/nvim/lazy` and are reinstalled by
> lazy.nvim on the next launch.

#### Go Development (`go.nvim`)

Struct, error, interface, and tag utilities. All mappings are `<localleader>g*` inside `.go` files.

| Keymap | Description | Example |
| --- | --- | --- |
| `<localleader>gf` | Fill struct fields with zero values | Cursor on `MyStruct{}` → fills all fields |
| `<localleader>ge` | Wrap with `if err != nil { return ..., err }` | Cursor after an `err`-returning call |
| `<localleader>gi` | Stub all methods for an interface | Cursor on a type, enter interface name in prompt |
| `<localleader>ga` | Add `json:"..."` tags to struct fields | Cursor anywhere in struct |
| `<localleader>gA` | Remove struct tags | Cursor anywhere in struct |
| `<localleader>gT` | Modify struct tags | Interactive prompt for tag options |
| `<localleader>go` | Toggle between `foo.go` and `foo_test.go` | Fast source/test switching |
| `<localleader>gc` | Generate doc comment for the function | Cursor on `func` line |

#### Go mod utilities

Inside `go.mod` files, `<localleader>g*` drives module commands.

| Keymap | Description |
| --- | --- |
| `<localleader>gg` | `go get -u ./...` — update all dependencies |
| `<localleader>gt` | `go mod tidy` |
| `<localleader>gu` | Bump Go version + toolchain to latest (fetches from go.dev) |

#### Testing (`neotest`)

`<leader>t*` in **any** buffer. Neotest picks the adapter that claims the current file: Go (`neotest-golang`), Python (`pytest`), JS/TS (`jest`, `vitest`), Lua (`plenary`), and a `vim-test` catch-all for Ruby, Elixir, PHP, Rust, Java and C#.

| Keymap | Description |
| --- | --- |
| `<leader>tn` | Run nearest test |
| `<leader>tv` | Run nearest test (verbose) |
| `<leader>tf` | Run all tests in current file |
| `<leader>tp` | Run all tests in current directory |
| `<leader>ta` | Run all tests in the suite |
| `<leader>tl` | Re-run last test |
| `<leader>tS` | Stop running tests |
| `<leader>tw` | Toggle watch mode for the current file |
| `<leader>to` | Show last test output |
| `<leader>tO` | Toggle output panel |
| `<leader>ts` | Toggle test summary panel |
| `<leader>td` | Debug nearest test (DAP strategy) |

Adding a language means adding one entry to the `adapters` registry in `nvim/.config/nvim/lua/plugins/test.lua`.

##### Go extras

Available under the same `<leader>t` menu, but only inside `.go` files. Go tests run with `-v -coverprofile=coverage.out` and `-race` when CGO is available.

| Keymap | Description |
| --- | --- |
| `<leader>tA` | Run all tests with optional `-tags` prompt |
| `<leader>tu` | Run package tests with `-update` (update snapshots) |
| `<leader>tC` | Print coverage summary from `coverage.out` |
| `<leader>tH` | Open HTML coverage report in browser |

Per-filetype extras like these are registered in the `ft_extras` table in `nvim/.config/nvim/lua/config/testing.lua`.

#### Debugging (`nvim-dap`)

`<leader>d*` in **any** buffer. Delve backs Go (via `nvim-dap-go`); `mason-nvim-dap` installs and configures the adapters for Python, JS/TS, Rust/C/C++ and Bash.

| Keymap | Description |
| --- | --- |
| `<leader>db` | Toggle breakpoint |
| `<leader>dB` | Set conditional breakpoint |
| `<leader>dC` | Clear all breakpoints |
| `<leader>dc` | Start / continue |
| `<leader>di` | Step into |
| `<leader>do` | Step over |
| `<leader>dO` | Step out |
| `<leader>dr` | Restart session |
| `<leader>dL` | Re-run last configuration |
| `<leader>dS` | Stop session |
| `<leader>du` | Toggle DAP UI (scopes / stacks / breakpoints / REPL) |
| `<leader>ds` | Open scopes/stacks/breakpoints view |
| `<leader>dv` | Inspect variable under cursor |
| `<leader>dR` | Toggle DAP REPL |

In Go, two launch configs are available when starting (`<leader>dc`): **Debug Main** (workspace `main`) and **Debug Current File**. `AWS_PROFILE` and `AWS_REGION` are forwarded automatically.

#### Go Linting (`nvim-lint` + `golangci-lint`)

Linting is intentionally **not** configured globally — `golangci-lint` runs against whatever `.golangci.yml`/`.golangci.toml` (or lack thereof) exists in the current project. This dotfiles repo only installs the binary and wires up the keymaps; rule selection is left entirely to each project.

| Keymap | Description |
| --- | --- |
| `<localleader>ll` | Run `golangci-lint` on current package and display results |
| `<localleader>lr` | Clear lint diagnostics |
| `<localleader>ld` | Show diagnostic detail for symbol under cursor |
| `<localleader>lD` | Open full diagnostics list |

#### LSP (Language Servers)

Managed by Mason + nvim-lspconfig. Active servers:

| Language | Server | Extras |
| --- | --- | --- |
| Go | `gopls` | standard config (`gofumpt` formatting, `fieldalignment` analysis, full inlay-hint set: assign types, composite literal fields, constant values, function type params, ignored errors, parameter names, range var types) — no extra analyzers or `staticcheck` overrides |
| TypeScript/JS | `vtsls` | — |
| Lua | `lua-language-server` | vim global pre-loaded |
| Bash/Shell | `bash-language-server` | — |
| YAML | `yaml-language-server` | GitHub Actions + docker-compose schemas |
| Docker | `dockerls` | — |

Formatters run on save via `conform.nvim` (`gofumpt`+`goimports` for Go, `prettierd` for web, `stylua` for Lua, `shfmt` for shell). Linters run via `nvim-lint` (`golangci-lint`, `eslint_d`, `shellcheck`).

#### GitHub — Octo (`octo.nvim`)

PR and issue management without leaving Neovim. Uses `fzf-lua` as the picker.

**Top-level mappings** (`<leader>o*`):

| Keymap | Description |
| --- | --- |
| `<leader>opp` | List PRs |
| `<leader>opn` | Create new PR |
| `<leader>opv` | View current PR |
| `<leader>opc` | Checkout PR |
| `<leader>opk` | PR checks / CI status |
| `<leader>opm` | Merge PR (squash by default) |
| `<leader>opl` | Reload PR |
| `<leader>opr` | Start review |
| `<leader>ops` | Submit review |
| `<leader>opb` | Open PR in browser |
| `<leader>oa` | Assign PR/issue to me |
| `<leader>or` | Add reviewer |
| `<leader>oil` | List issues |
| `<leader>oic` | Create issue |
| `<leader>oiv` | View issue |

Inside an Octo buffer, `<localleader>p*` drives PR actions (checkout, merge variants, commits, files, diff), `<localleader>i*` drives issue actions (close, reopen, list), `<localleader>l*` manages labels (add, remove, create), and `<localleader>a*` manages assignees (add, remove). `<localleader>ca/cr/cd` add, reply, or delete comments; `[c/]c` jump between comments.

#### GitHub Releases (`nvim-ghrelease`)

A `gh` CLI wrapper of my own
([mesirendon/nvim-ghrelease](https://github.com/mesirendon/nvim-ghrelease)) for
cutting GitHub releases without leaving the editor. Configured in
`plugins/ghrelease.lua`; loads lazily on the `:GhRelease` command.

| Keymap / Command | Description |
| --- | --- |
| `<leader>gr` | Create a GitHub release |
| `:GhRelease` | Same, as a command |

The plugin's own default keymap is disabled (`keymaps.create = false`) so the
binding is declared here instead.

#### PlantUML (`plantuml-previewer.vim`)

Live-reloading diagram preview for `.puml` files. The PlantUML jar is located automatically via Homebrew.

| Keymap | Description |
| --- | --- |
| `<localleader>up` | Open live preview in browser |
| `<localleader>ur` | Force reload (re-saves the buffer) |
| `<localleader>us` | Export to SVG or PNG (prompts for format) |

Edits trigger a debounced (600 ms) re-render automatically — no manual reload needed while typing.

#### Case Coercion (`vim-abolish`)

Change identifier case with `cr*` in normal mode (cursor on any word):

| Keymap | Result |
| --- | --- |
| `crs` | `snake_case` |
| `crc` | `camelCase` |
| `crm` | `PascalCase` |
| `cru` | `UPPER_SNAKE_CASE` |
| `cr-` | `kebab-case` |
| `crt` | `Title Case` |

#### Text Alignment (`mini.align`)

| Keymap | Mode | Description |
| --- | --- | --- |
| `ga` | normal/visual | Align selection around a character (enter delimiter at prompt) |
| `gA` | normal/visual | Align with live preview |

Example: select a block of variable assignments and press `ga=` to align all `=` signs.

#### Symbol Navigation (`aerial.nvim`)

Opened via `<leader>cs` (or `:AerialToggle`). Shows a sidebar outline of functions, types, and methods with min width 50 / max width 80.

#### Color Highlighting (`nvim-colorizer`)

Automatically active in `css`, `scss`, `sass`, `html`, `javascript`, `typescript`, and `lua` files. Renders `#RGB`, `#RRGGBB`, `rgb()`, `hsl()`, and Tailwind color names as inline color swatches.

#### Image Rendering (`image.nvim`)

Renders images inline using the Kitty terminal protocol. Supported formats: `png`, `jpg`, `jpeg`, `gif`, `webp`, `svg`. Markdown image tags render automatically; images clear in insert mode. Max display size is 100 × 40 cells.

#### Snippets (`LuaSnip`)

Custom snippets live in `nvim/.config/nvim/lua/snippets/`. Go template snippets are in `snippets/gotmpl.lua`. LuaSnip is the snippet engine behind `blink.cmp`, and community snippets (`friendly-snippets`) are loaded too — all surfaced through the blink completion menu.

#### Colorscheme (`catppuccin`)

`catppuccin-mocha` flavour, set as the default colorscheme in `plugins/colorscheme.lua`.

#### Dashboard (`snacks.nvim`)

Custom start screen: custom ASCII header, footer ("Write. Build. Learn."), and an optional `chafa`-rendered logo section (shown only if `~/.config/nvim/logo.png` exists).

#### UI Select/Input (`dressing.nvim`)

Improves the look of `vim.ui.select`/`vim.ui.input` prompts (used by things like `GoImpl`'s interface-name prompt and LSP code actions).

#### Bundled Editing Features

Beyond the language servers above, these are wired as explicit specs under
`plugins/`: `mini.surround` + `mini.comment` (`coding.lua`), `mini.pairs` +
`mini.ai` (`coding.lua`), `toggleterm.nvim` (`toggleterm.lua`, `<leader>;*`
and `lazygit` on `<leader>gg`/`<leader>gG`), `kulala.nvim` REST client (`rest.lua`, `<leader>R*`), `aerial` (`aerial.lua`),
`render-markdown` + `markdown-preview` (`markdown.lua`), and `claudecode.nvim`
(`claudecode.lua`).

#### Claude Code (`claudecode.nvim`)

Bridges the Claude Code CLI with Neovim — file context, selection sharing, and diff review. Configured in `plugins/claudecode.lua`. Activate the CLI with `claude` in a terminal; the plugin syncs the active buffer automatically.

#### Terminals (`toggleterm.nvim`)

Terminal management has its own group, `<leader>;` (`plugins/toggleterm.lua`) — deliberately separate from `<leader>t` (tests). Floating is the default and primary direction; splits open at the bottom (height 15) or on the right (40% width).

Terminals **invert** the root-vs-cwd convention used by the picker and explorer: **lowercase = literal cwd**, **uppercase = root dir** (resolved by `util.root`, which — given the sub-project markers in `root_spec` — is the enclosing module inside a monorepo).

| Keymap | Description |
| --- | --- |
| `<leader>;f` / `<leader>;F` | Floating terminal (cwd / root dir) |
| `<leader>;h` / `<leader>;H` | Bottom split terminal (cwd / root dir) |
| `<leader>;v` / `<leader>;V` | Right split terminal (cwd / root dir) |
| `<leader>;s` | Select an open terminal (`:TermSelect`) |
| `<leader>;n` / `<leader>;N` | New terminal, never reuses an existing one (cwd / root dir) |
| `<Ctrl-/>` | Toggle the floating terminal (cwd), from normal or terminal mode |

Terminals are cached per direction + directory, so pressing the same keymap again toggles the *same* shell instead of spawning a new one. Inside a terminal, `<Esc>` drops to normal mode, `<Ctrl-h/j/k/l>` move between windows, and `q` in normal mode closes it.

#### Lazygit (`<leader>gg` / `<leader>gG`)

`lazygit` runs as a floating toggleterm, opened in the cwd (`<leader>gg`) or in the git root (`<leader>gG`). The `<Esc>`/`q` terminal maps are removed inside this buffer so lazygit receives those keys itself. Installed via Homebrew (`brew "lazygit"` in the `Brewfile`); the keymap warns if the binary is missing.

#### Treesitter Text-Object Navigation

Jump between code constructs with `]`/`[` in normal mode:

| Keymap | Description |
| --- | --- |
| `]f` / `[f` | Next / prev function start |
| `]F` / `[F` | Next / prev function end |
| `]c` / `[c` | Next / prev class start |
| `]C` / `[C` | Next / prev class end |
| `]a` / `[a` | Next / prev parameter start |
| `]A` / `[A` | Next / prev parameter end |

`<Alt-Space>` expands the treesitter selection node by node; `<Backspace>` contracts it.

#### Auto-save

Buffers are saved automatically on `BufLeave`, `WinLeave`, and `FocusLost`. Only normal file buffers are written — terminals, readonly files, and scratch buffers are skipped silently.

#### Global Shortcuts

| Keymap | Description |
| --- | --- |
| `+` | Increment number under cursor (`<C-a>`) |
| `-` | Decrement number under cursor (`<C-x>`) |

---

### Taskwarrior

CLI task manager with a TUI frontend (`taskwarrior-tui`). Config is stowed from `taskwarrior/`.

#### Core concepts

- **Projects** group related tasks (`project:work`).
- **Tags** label tasks for filtering (`+next`, `+waiting`).
- **Urgency** is a computed score that drives the default `next` report sort order.

#### Common commands

| Command | Description |
| --- | --- |
| `task add <description> project:<name> +<tag> due:<date>` | Add a task |
| `task next` | Default view — all pending tasks sorted by urgency |
| `task <id> done` | Mark task complete |
| `task <id> delete` | Delete task |
| `task <id> modify due:<date>` | Change a field on an existing task |
| `task <id> start` | Start working on a task (sets `start` timestamp) |
| `task <id> stop` | Stop without completing |
| `task <id> annotate <note>` | Attach a timestamped note |
| `task project:<name>` | Filter by project |
| `task +<tag>` | Filter by tag |
| `task calendar` | Month view with due dates |

#### Configured urgency weights

| Tag / Project | Coefficient | Effect |
| --- | --- | --- |
| `+next` | +15 | Floats to top of queue |
| `+waiting` | −3 | Pushes to bottom |
| Any user project | +1 | Slight boost over unprojectd tasks |

#### Date format

Dates are entered and displayed as `m/d/Y` (e.g. `6/30/2026`). Annotations include time: `m/d/Y H:N:S`.

#### TUI (`taskwarrior-tui`)

Launch with `tw`. Vim-style keybindings:

| Key | Action |
| --- | --- |
| `j` / `k` | Move down / up |
| `h` / `l` | Move left / right |
| `Space` | Toggle task done |
| `a` | Add task |
| `e` | Edit task (opens `$EDITOR`) |
| `m` | Modify task |
| `d` / `x` | Delete task |
| `/` | Filter |
| `r` | Refresh |
| `q` / `ZZ` | Quit |

#### Color scheme (Nord-inspired)

| State | Appearance |
| --- | --- |
| `+next` tag | Bold white on blue |
| `+waiting` tag | Black on yellow |
| Due soon | Bold white on cyan |
| Overdue | White on red |
| Completed | Bold black on green |
| Active (started) | Bold white on magenta |

---

### Shell Helpers

Defined in `zsh/.zshrc`.

#### `vimreset` — clean Neovim reinstall

Wipes Neovim's plugins, cache, and state so the next launch rebuilds everything
from scratch, **while preserving your recorded macros**.

```bash
vimreset          # reset, keep macros/marks/history
vimreset --hard   # reset everything, discard macros too  (alias: -f)
```

| Path | Reset | Notes |
| --- | --- | --- |
| `~/.cache/nvim` | removed | Rebuilt on next launch |
| `~/.local/share/nvim` | removed | Plugins + Mason tools reinstall |
| `~/.local/state/nvim` | removed | Logs, undo, swap |
| `~/.config/nvim/lazy-lock.json` | removed | Not git-tracked; lazy.nvim re-resolves |
| `~/.local/state/nvim/shada/main.shada` | **preserved** | Registers, marks, history |
| `~/.luarocks` | untouched | See [Lua Rocks](#lua-rocks-luarocks) |

**Why the ShaDa file matters.** Macros recorded with `q` live in registers, and
Neovim persists registers to `~/.local/state/nvim/shada/main.shada` — inside the
state directory the reset deletes. `vimreset` snapshots that file first and
restores it afterwards, so `@a` still works after a rebuild. Global marks, jumps,
and command/search history ride along in the same file and come back too.

**Macros are only written on exit.** Neovim flushes its ShaDa when it quits, so
quit all instances before resetting — otherwise the macro you just recorded was
never persisted in the first place. `vimreset` refuses to run while `nvim` is
alive for this reason (a running instance would also overwrite the restored file
on exit). Use `--hard` to bypass the check when you genuinely want a clean slate.
