# Kiro CLI pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh"

# Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# OS Detection
case "$(uname -s)" in
Darwin) OS_FAMILY=mac ;;
Linux) OS_FAMILY=linux ;;
*) OS_FAMILY=other ;;
esac
export OS_FAMILY

# Homebrew shellenv
if [[ $OS_FAMILY == mac ]]; then
  [[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
  [[ -x /usr/local/bin/brew ]] && eval "$(/usr/local/bin/brew shellenv)"
elif [[ $OS_FAMILY == linux ]]; then
  [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Oh My Zsh base
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

## Plugins
plugins=(
  emoji
  docker
  git git-extras gitignore
  golang
  man node npm nvm
  sudo
  zsh-navigation-tools
)

## Extra completion dirs
if [[ $OS_FAMILY == mac ]]; then
  [[ -d "$HOME/.docker/completions" ]] && fpath=("$HOME/.docker/completions" $fpath)
fi

## nvm (if installed)
export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"

## Load Oh My Zsh
source "$ZSH/oh-my-zsh.sh"

# User config and PATH
export PATH="$HOME/.claude/bin:$HOME/.bin:$PATH"
export EDITOR="nvim"

# Prefer imagemagick-full (keg-only) — it's built with librsvg, so `magick`
# can rasterize SVGs. The plain imagemagick formula cannot.
if [[ -d "${HOMEBREW_PREFIX:-/opt/homebrew}/opt/imagemagick-full/bin" ]]; then
  export PATH="${HOMEBREW_PREFIX:-/opt/homebrew}/opt/imagemagick-full/bin:$PATH"
fi

# Go env: Preferring go's own values
if command -v go >/dev/null 2>&1; then
  export GOPATH="${GOPATH:-$(go env GOPATH 2>/dev/null || echo "$HOME/go")}"
  export GOROOT="${GOROOT:-$(go env GOROOT 2>/dev/null || true)}"
fi

## Fallbacks if go isn't on PATH yet
if [[ -z "${GOROOT:-}" ]] && command -v brew >/dev/null 2>&1; then
  GOROOT="$(brew --prefix go 2>/dev/null)/libexec"
fi
export GOPATH="${GOPATH:-$HOME/go}"
export GOROOT="${GOROOT:-$GOROOT}"
export PATH="$PATH:$GOPATH/bin${GOROOT:+:$GOROOT/bin}"

# Personal paths
export mopath="$HOME/Documents/Projects/Modak"
export capath="$HOME/Documents/Cacharreo"
export mesi="$HOME/Documents/Projects/mesirendon/"

# Private scope settings
export GOPRIVATE='github.com/modak-live/*'

# Aliases
alias rm="rm -fr"
alias weather="curl -4 http://wttr.in/bogota"
alias l='eza -l --group-directories-first --git'
alias la='eza -la --group-directories-first --git'
alias dcomp='docker-compose'
alias vim='nvim'
alias tw='taskwarrior-tui'
alias zj='zellij'
alias zja='zj a $(zj ls -r| fzf --ansi --reverse | cut -d " "  -f 1)'
copy() {
  if command -v pbcopy >/dev/null 2>&1; then
    pbcopy
  elif [[ -n "${WSL_DISTRO_NAME:-}" ]] && command -v clip.exe >/dev/null 2>&1; then
    clip.exe
  elif command -v wl-copy >/dev/null 2>&1; then
    wl-copy
  elif command -v xclip >/dev/null 2>&1; then
    xclip -selection clipboard
  elif command -v xsel >/dev/null 2>&1; then
    xsel --clipboard --input
  else
    cat >/dev/null
    echo "No clipboard tool found" >&2
    return 1
  fi
}
alias clip='copy <&0'
alias tmux='tmux -u'

# Functions
ghostty-shader() {
  local shader="${1:-cursor_blaze.glsl}"
  ln -sf "$HOME/.config/ghostty/shaders/$shader" "$HOME/.config/ghostty/shaders/shader.glsl"
  echo "Shader set to $shader"
}

claude-install() {
  if command -v claude >/dev/null 2>&1; then
    echo "✅ Claude Code is already installed"
    claude --version
    return 0
  fi
  curl -fsSL --connect-timeout 15 --max-time 120 https://claude.ai/install.sh | bash
  if command -v claude >/dev/null 2>&1; then
    echo "✅ Claude Code installed successfully"
    claude --version
  else
    echo "⚠️  Claude Code install script finished but 'claude' is not on PATH."
    echo "    You may need to restart your shell or add ~/.claude/bin to PATH."
  fi
}

brew_trust_taps() {
  local tap
  while IFS= read -r tap; do
    [[ "$tap" == homebrew/* ]] && continue
    print "Trusting tap: $tap"
    HOMEBREW_NO_AUTO_UPDATE=1 yes | brew tap "$tap" 2>/dev/null || true
  done < <(brew tap)
}

brew_check_tap() {
  local tap="${1:?Usage: brew_check_tap <user/repo>}"
  print "==> Tap metadata (brew tap-info)"
  brew tap-info "$tap" 2>/dev/null || print "Tap not installed locally"
  print ""
  local org="${tap%%/*}"
  local name="${tap##*/}"
  local repo="${org}/homebrew-${name}"
  print "==> GitHub info (gh repo view)"
  gh repo view "$repo" --json name,description,stargazerCount,updatedAt,openIssueCount \
    --template '{{.name}}: {{.description}}\nStars: {{.stargazerCount}} | Open issues: {{.openIssueCount}} | Last updated: {{.updatedAt}}\n' \
    2>/dev/null || print "Could not fetch GitHub info (gh not authenticated or repo not found)"
}

sysupdate() {
  export HOMEBREW_NO_AUTO_UPDATE=1
  if [[ $OS_FAMILY == linux ]]; then
    sudo apt update && sudo apt -y upgrade && sudo apt -y dist-upgrade &&
      sudo apt -y autoremove && sudo apt -y autoclean &&
      brew update && brew upgrade && brew cleanup
  else
    brew update && brew upgrade && brew cleanup
  fi
}

mkcd() { mkdir -p -- "$1" && cd -- "$1" || return; }

# Wipe Neovim's plugins/cache/state for a clean reinstall, preserving the ShaDa file
# (~/.local/state/nvim/shada/main.shada) so recorded macros, marks and history survive.
# Pass --hard (or -f) to skip preservation and reset everything.
# NOTE: `command rm` is deliberate -- `alias rm="rm -fr"` above would otherwise be
# expanded into this function's body at definition time.
vimreset() {
  local hard=0
  case "${1:-}" in
    --hard | -f) hard=1 ;;
    "") ;;
    *)
      print -u2 "Usage: vimreset [--hard]"
      return 1
      ;;
  esac

  if ((!hard)) && pgrep -x nvim >/dev/null 2>&1; then
    print -u2 "⚠️  Neovim is still running; it would overwrite the restored ShaDa on exit."
    print -u2 "    Quit all instances first, or use 'vimreset --hard' to reset anyway."
    return 1
  fi

  local state="$HOME/.local/state/nvim"
  local shada="$state/shada/main.shada"
  local snapshot=""

  if ((!hard)) && [[ -f "$shada" ]]; then
    snapshot="$(mktemp -t nvim-shada)" || return 1
    if ! cp "$shada" "$snapshot"; then
      command rm -f "$snapshot"
      print -u2 "⚠️  Could not snapshot $shada; aborting."
      return 1
    fi
  fi

  command rm -rf "$HOME/.cache/nvim" "$HOME/.local/share/nvim" "$state"
  command rm -f "$HOME/.config/nvim/lazy-lock.json"

  if [[ -n "$snapshot" ]]; then
    mkdir -p "$state/shada"
    mv "$snapshot" "$shada"
    chmod 600 "$shada"
    print "✅ Neovim reset; preserved macros/marks/history in $shada"
  elif ((hard)); then
    print "✅ Neovim reset (--hard); ShaDa discarded"
  else
    print "✅ Neovim reset; no ShaDa file found to preserve"
  fi
}

# Powerlevel config file
[[ -f "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"

# tabtab completion
[[ -f "$HOME/.config/tabtab/zsh/__tabtab.zsh" ]] && . "$HOME/.config/tabtab/zsh/__tabtab.zsh"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Created by `pipx` on 2025-10-21 13:20:47
export PATH="$PATH:/home/mesi/.local/bin"

eval "$(zoxide init zsh)"

# Kiro CLI post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh"
