# Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
	source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# OS Detection
case "$(uname -s)" in
	Darwin) OS_FAMILY=mac ;;
	Linux)  OS_FAMILY=linux ;;
	*)      OS_FAMILY=other ;;
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

## Load Oh My Zsh
source "$ZSH/oh-my-zsh.sh"

# User config and PATH
export PATH="$HOME/.bin:$PATH"

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

# Private scope settings
export GOPRIVATE='github.com/modak-live/*'

# Aliases
alias weather="curl -4 http://wttr.in/bogota"
alias l='eza -l --group-directories-first --git'
alias la='eza -la --group-directories-first --git'
alias dcomp='docker-compose'
alias vim='nvim'
if [[ $OS_FAMILY == linux ]]; then
	alias sysupdate='sudo apt update && sudo apt -y upgrade && sudo apt -y dist-upgrade && sudo apt -y autoremove && sudo apt -y autoclean'
fi
copy() {
	if command -v pbcopy >/dev/null 2>&1; then cat | pbcopy
	elif command -v wl-copy >/dev/null 2>&1; then wl-copy
	elif command -v xclip >/dev/null 2>&1; then xclip -selection clipboard
	else cat >/dev/null; echo "No clipboard tool found" >&2; return 1
	fi
}
alias clip='copy <&0'
alias tmux='tmux -u'
BAT_THEME="GitHub"

mkcd(){ mkdir -p -- "$1" && cd -- "$1"; }

# Powerlevel config file
[[ -f "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"

# tabtab completion
[[ -f "$HOME/.config/tabtab/zsh/__tabtab.zsh" ]] && . "$HOME/.config/tabtab/zsh/__tabtab.zsh"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
