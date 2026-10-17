#!/bin/sh
# bootstrap.sh [package]...: stow packages into $HOME on this machine.
# With no arguments it installs DEFAULT_PACKAGES. It checks dependencies,
# refuses unsafe combinations, backs up conflicting files, then stows.
# Naming another variant of an installed tool switches to it.
# It never runs sudo or writes outside $HOME: it prints install hints instead.
DEFAULT_PACKAGES="tmux-full" # change this one line to change the default

set -eu
cd "$(dirname "$0")"

say() { printf 'dotfiles: %s\n' "$*"; }
die() {
  printf 'dotfiles: %s\n' "$*" >&2
  exit 1
}
have() { command -v "$1" >/dev/null 2>&1; }
has_pkg() {
  case " $pkgs " in *" $1 "*) return 0 ;; esac
  return 1
}

# A package is installed if one of its files links into it. With
# --no-folding each file is its own link, so the first one found will do
stowed() {
  [ -d "$1" ] || return 1
  f=$(cd "$1" && find . -type f -o -type l | head -n 1)
  case $(readlink "$HOME/${f#./}" 2>/dev/null) in */"$1/${f#./}") return 0 ;; esac
  return 1
}

# No arguments means the defaults, but a variant that's already installed
# stays: re-running the installer to update mustn't switch you back
if [ $# -eq 0 ]; then
  for p in $DEFAULT_PACKAGES; do
    for v in "${p%%-*}"-*; do stowed "$v" && p=$v; done
    set -- "$@" "$p"
  done
fi

case $(uname -s) in
  Darwin) hint="brew install" ;;
  *) hint="sudo apt install" ;;
esac

# Validate names, allow one variant per tool, collect what's needed, and
# find any other variant installed now (old): naming one switches from it
pkgs="" tools="" old="" needs="stow git"
for p in "$@"; do
  p=${p%/}
  { [ -d "$p" ] && [ "$p" != test ]; } || die "unknown package: $p"
  tool=${p%%-*}
  case " $tools " in
    *" $tool "*) die "$p: install one $tool variant, not two" ;;
  esac
  pkgs="$pkgs $p" tools="$tools $tool"
  for v in "$tool"-*; do [ "$v" = "$p" ] || ! stowed "$v" || old="$old $v"; done
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

# Switching: unstow the old variant, or stow stops on its links. A running
# tmux keeps the old config's settings (a reload can't unset them), so
# refuse that before anything changes
if [ -n "$old" ]; then
  case $old in *tmux-*)
    ! tmux has-session 2>/dev/null ||
      die "tmux is running and would keep$old's settings. Quit it (tmux kill-server), then rerun this from a plain terminal"
    ;;
  esac
  say "switching: unstowing$old"
  # shellcheck disable=SC2086 # old is a space-separated list of names
  stow -D $old
fi

# tmux-full's and tmux-raidboss's extras are optional (convention 7): warn,
# don't stop
if has_pkg tmux-full || has_pkg tmux-raidboss; then
  if ! have brew; then
    say "note: the tmux picker and status tools come from Homebrew (see Brewfile)"
  elif ! brew bundle check --file Brewfile >/dev/null 2>&1; then
    say "note: some tmux tools are missing: brew bundle --file $PWD/Brewfile"
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

# Plugins must exist before tmux first starts, or the config errors
if has_pkg tmux-full || has_pkg tmux-raidboss; then
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
