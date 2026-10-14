#!/bin/sh
# check.sh: validate the repo. Parses every tmux and zsh config, lints the
# shell scripts and dry-runs stow for every package. Read-only: nothing is
# installed or linked. Exits non-zero if anything fails.
set -eu
cd "$(dirname "$0")"

failed=0
ok() { printf 'dotfiles: ok    %s\n' "$1"; }
fail() { printf 'dotfiles: FAIL  %s\n' "$1" >&2; failed=1; }
warn() { printf 'dotfiles: warn  %s\n' "$1" >&2; }
have() { command -v "$1" >/dev/null 2>&1; }

# Packages are the top-level directories, except the test image
packages=$(for d in */; do [ "$d" = test/ ] || printf '%s ' "${d%/}"; done)

# tmux: parse on a throwaway server that loads no config. These must be
# separate tmux calls: chained with \; the exit status comes from the last
# command, so a parse error would still exit 0
if have tmux; then
  sock=check-$$
  tmux -L "$sock" -f /dev/null new -d
  for f in */.config/tmux/tmux.conf; do
    if tmux -L "$sock" source-file -n "$f"; then ok "$f"; else fail "$f"; fi
  done
  tmux -L "$sock" kill-server
else
  warn "tmux not installed; tmux configs not checked"
fi

# zsh: syntax only, so it's safe on a host whose shell is shell-config's
if have zsh; then
  for f in zsh-*/.zshrc; do
    if zsh -n "$f"; then ok "$f"; else fail "$f"; fi
  done
else
  warn "zsh not installed; zsh configs not checked"
fi

# Scripts: shellcheck picks sh or bash from each shebang
scripts=$(find . -name '*.sh' -not -path './.git/*' | sort)
if have shellcheck; then
  for f in $scripts; do
    if shellcheck "$f"; then ok "$f"; else fail "$f"; fi
  done
else
  warn "shellcheck not installed; scripts not linted"
fi

# Stow: dry-run each package on its own (variants conflict by design) into
# an empty directory, so the result depends on the repo, not this machine.
# stow -n always prints a "simulation mode" warning, so show output only on
# failure
target=$(mktemp -d)
trap 'rm -rf "$target"' EXIT
for p in $packages; do
  if out=$(stow -n -t "$target" "$p" 2>&1); then
    ok "stow $p"
  else
    fail "stow $p"
    printf '%s\n' "$out" >&2
  fi
done

# Packages hardcode ~/.config (CLAUDE.md, convention 4)
if [ -n "${XDG_CONFIG_HOME:-}" ] && [ "$XDG_CONFIG_HOME" != "$HOME/.config" ]; then
  warn "XDG_CONFIG_HOME is $XDG_CONFIG_HOME; packages assume ~/.config"
fi

if [ "$failed" -ne 0 ]; then
  printf 'dotfiles: checks failed\n' >&2
  exit 1
fi
printf 'dotfiles: all checks passed\n'
