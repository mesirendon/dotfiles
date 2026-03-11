#!/usr/bin/env bash
test -d ~/.linuxbrew && eval "$(~/.linuxbrew/bin/brew shellenv)"
test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
grep -qF 'brew shellenv' ~/.bashrc || echo "eval \"\$($(brew --prefix)/bin/brew shellenv)\"" >> ~/.bashrc
