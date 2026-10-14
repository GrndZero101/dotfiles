#!/bin/sh
# bootstrap.sh [package]...: stow packages into $HOME on this machine.
# With no arguments it installs DEFAULT_PACKAGES. It checks dependencies,
# refuses unsafe combinations, backs up conflicting files, then stows.
# It never runs sudo or writes outside $HOME: it prints install hints instead.
DEFAULT_PACKAGES="tmux-full"   # change this one line to change the default

set -eu
cd "$(dirname "$0")"

say() { printf 'dotfiles: %s\n' "$*"; }
die() { printf 'dotfiles: %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }
has_pkg() { case " $pkgs " in *" $1 "*) return 0 ;; esac; return 1; }

# shellcheck disable=SC2086 # splitting the default list into arguments
[ $# -gt 0 ] || set -- $DEFAULT_PACKAGES

case $(uname -s) in
  Darwin) hint="brew install" ;;
  *) hint="sudo apt install" ;;
esac

# Validate names, allow one variant per tool, and collect what's needed
pkgs="" tools="" needs="stow git"
for p in "$@"; do
  p=${p%/}
  { [ -d "$p" ] && [ "$p" != test ]; } || die "unknown package: $p"
  tool=${p%%-*}
  case " $tools " in
    *" $tool "*) die "$p: install one $tool variant, not two" ;;
  esac
  pkgs="$pkgs $p" tools="$tools $tool"
  case $p in
    tmux-*) needs="$needs tmux" ;;
    zsh-*) needs="$needs zsh" ;;
  esac
done

missing=""
for c in $needs; do have "$c" || missing="$missing $c"; done
[ -z "$missing" ] || die "missing:$missing. Install with: $hint$missing"

# On a shell-config machine ~/.zshenv sets ZDOTDIR, so a stowed ~/.zshrc
# would be silently ignored
if has_pkg zsh-minimal || has_pkg zsh-antidote; then
  [ ! -e "$HOME/.zshenv" ] ||
    die "$HOME/.zshenv exists (shell-config?), so zsh would ignore ~/.zshrc. zsh-* packages are for fresh boxes and containers."
fi

# tmux-full's extras are optional (convention 7): warn, don't stop
if has_pkg tmux-full; then
  if ! have brew; then
    say "note: tmux-full's picker and status tools come from Homebrew (see Brewfile)"
  elif ! brew bundle check --file Brewfile >/dev/null 2>&1; then
    say "note: some tmux-full tools are missing: brew bundle --file $PWD/Brewfile"
  fi
fi

# Move real files that stow would refuse to replace into a timestamped
# backup. Links stowed by another package are left alone: stow then stops
# with a clear error. Never --adopt: it would overwrite the repo's files
backup="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
for p in $pkgs; do
  stow -n "$p" 2>&1 |
    sed -n -e 's/.* over existing target \(.*\) since neither a link nor a directory.*/\1/p' \
      -e 's/.*existing target is not owned by stow: //p' |
    while IFS= read -r f; do
      say "backing up ~/$f to $backup/$f"
      mkdir -p "$backup/$(dirname "$f")"
      mv "$HOME/$f" "$backup/$f"
    done
done

say "stowing$pkgs"
# shellcheck disable=SC2086 # pkgs is a space-separated list of names
stow $pkgs

# Plugins must exist before tmux first starts, or tmux-full's config errors
if has_pkg tmux-full; then
  tpm="$HOME/.config/tmux/plugins/tpm"
  if [ ! -d "$tpm" ]; then
    say "cloning tpm"
    git clone -q --depth 1 https://github.com/tmux-plugins/tpm "$tpm"
  fi
  say "installing tmux plugins"
  "$tpm/bin/install_plugins" || die "tmux plugin install failed; rerun, or press prefix + I in tmux"
fi

if has_pkg zsh-minimal || has_pkg zsh-antidote; then
  case ${SHELL:-} in
    */zsh) ;;
    *) say "next: make zsh your login shell with: chsh -s $(command -v zsh)" ;;
  esac
fi
say "done. Start a new shell or tmux session to use it."
