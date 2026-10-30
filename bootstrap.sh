#!/bin/sh
# bootstrap.sh [package]...: stow packages into $HOME on this machine.
# bootstrap.sh --pick: choose them with fzf instead.
# With no arguments it installs DEFAULT_PACKAGES. It checks dependencies,
# refuses unsafe combinations, backs up conflicting files, then stows.
# Naming another variant of an installed tool switches to it.
# It never runs sudo or writes outside $HOME: it prints install hints instead.
DEFAULT_PACKAGES="tmux-full" # the default; the README's tables name it too

set -eu
cd "$(dirname "$0")"

say() { printf 'dotfiles: %s\n' "$*"; }
die() {
  printf 'dotfiles: %s\n' "$*" >&2
  exit 1
}
have() { command -v "$1" >/dev/null 2>&1; }

# A package is installed if one of its files links into it. With
# --no-folding each file is its own link, so the first one found will do
stowed() {
  [ -d "$1" ] || return 1
  f=$(cd "$1" && find . -type f -o -type l | head -n 1)
  case $(readlink "$HOME/${f#./}" 2>/dev/null) in */"$1/${f#./}") return 0 ;; esac
  return 1
}

# --pick only chooses the arguments; everything after runs as if they'd
# been typed, and the command is printed so it can be typed next time.
# Each package's "# <package>: ..." header comment is its description
if [ "${1:-}" = --pick ]; then
  [ $# -eq 1 ] || die "--pick chooses the packages; don't name any"
  all=$(for d in */; do [ "$d" = test/ ] || printf '%s ' "${d%/}"; done)
  { have fzf && [ -t 1 ]; } ||
    die "--pick needs fzf and a terminal. Name packages instead, ./bootstrap.sh <package>..., from: $all"
  # The preview is expanded later, by the sh that fzf runs it in
  # shellcheck disable=SC2016
  preview='p={1}; f=$(grep -rl "^# $p: " "$p" | head -n 1)
    [ -z "$f" ] || sed -n "/^# $p: /,/^#\{0,1\}$/s/^# //p" "$f"
    echo; echo "links into ~:"; cd "$p" && find . -type f -o -type l | sed "s|^\./|  ~/|"'
  picked=$(for p in $all; do
    if stowed "$p"; then echo "$p ● installed"; else echo "$p"; fi
  done | SHELL=/bin/sh fzf --multi --reverse --prompt 'packages> ' \
    --header 'Tab: pick more   Enter: install   Esc: cancel' \
    --preview-window wrap --preview "$preview" | cut -d' ' -f1)
  if [ -z "$picked" ]; then say "nothing picked; nothing changed" && exit 0; fi
  # shellcheck disable=SC2086 # picked is a list of names, split on purpose
  set -- $picked
  say "running ./bootstrap.sh $*"
fi

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
# find any other variant installed now (old): naming one switches from it.
# A tmux variant that declares tpm needs its plugins (tpm); asking the
# config means a new variant needs no edit here
pkgs="" tools="" old="" needs="stow git" tpm="" zsh=""
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
    tmux-*)
      needs="$needs tmux"
      if grep -q "@plugin 'tmux-plugins/tpm'" "$p/.config/tmux/tmux.conf"; then tpm=1; fi
      ;;
    zsh-*) needs="$needs zsh" zsh=1 ;;
  esac
done

missing=""
for c in $needs; do have "$c" || missing="$missing $c"; done
[ -z "$missing" ] || die "missing:$missing. Install with: $hint$missing"

# On a shell-config machine ~/.zshenv sets ZDOTDIR, so a stowed ~/.zshrc
# would be silently ignored
if [ -n "$zsh" ]; then
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

# The tpm variants' extras are optional (convention 7): warn, don't stop
if [ -n "$tpm" ]; then
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
if [ -n "$tpm" ]; then
  tpm="$HOME/.config/tmux/plugins/tpm"
  if [ ! -d "$tpm" ]; then
    say "cloning tpm"
    git clone -q --depth 1 https://github.com/tmux-plugins/tpm "$tpm"
  fi
  say "installing tmux plugins"
  "$tpm/bin/install_plugins" || die "tmux plugin install failed; rerun, or press prefix + I in tmux"
fi

if [ -n "$zsh" ]; then
  case ${SHELL:-} in
    */zsh) ;;
    *) say "next: make zsh your login shell with: chsh -s $(command -v zsh)" ;;
  esac
fi
say "done. Start a new shell or tmux session to use it."
