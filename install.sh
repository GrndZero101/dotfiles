#!/bin/sh
# install.sh: get the repo onto this machine, then hand off to bootstrap.sh.
#   curl -fsSL https://raw.githubusercontent.com/GrndZero101/dotfiles/main/install.sh | sh
# Re-running it updates the clone. POSIX sh, because a server getting only
# tmux-minimal may not have zsh. Everything is inside main(), called on the
# last line, so a download cut off halfway runs nothing.

main() {
  set -eu
  DOTFILES_DIR=${DOTFILES_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles}
  DOTFILES_BRANCH=${DOTFILES_BRANCH:-main}
  DOTFILES_REPO_URL=${DOTFILES_REPO_URL:-https://github.com/GrndZero101/dotfiles.git}
  # A mistyped URL must fail, not wait for a password nobody can type
  export GIT_TERMINAL_PROMPT=0

  case ${1:-} in
    -h | --help)
      usage
      return 0
      ;;
  esac

  command -v git >/dev/null 2>&1 ||
    die "git is required. Install it with: sudo apt install git (Ubuntu) or brew install git (macOS)"

  if [ ! -e "$DOTFILES_DIR" ]; then
    say "cloning $DOTFILES_REPO_URL ($DOTFILES_BRANCH) into $DOTFILES_DIR"
    git clone -q --depth 1 --branch "$DOTFILES_BRANCH" "$DOTFILES_REPO_URL" "$DOTFILES_DIR"
  elif [ -d "$DOTFILES_DIR/.git" ] && [ -f "$DOTFILES_DIR/bootstrap.sh" ]; then
    say "updating $DOTFILES_DIR"
    git -C "$DOTFILES_DIR" pull -q --ff-only ||
      say "warning: couldn't update (local changes?); using the existing checkout"
  else
    die "$DOTFILES_DIR exists but isn't a clone of this repo. Move it, or set DOTFILES_DIR."
  fi

  exec "$DOTFILES_DIR/bootstrap.sh" "$@"
}

say() { printf 'dotfiles: %s\n' "$*"; }
die() {
  printf 'dotfiles: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage: install.sh [package]...

Clones the dotfiles repo (or updates an existing clone), then runs
bootstrap.sh with the given packages. No packages means the default,
tmux-full.

  curl -fsSL https://raw.githubusercontent.com/GrndZero101/dotfiles/main/install.sh | sh
  curl -fsSL https://raw.githubusercontent.com/GrndZero101/dotfiles/main/install.sh | sh -s -- zsh-antidote tmux-minimal

Environment:
  DOTFILES_DIR       where to clone (default: ~/.config/dotfiles)
  DOTFILES_BRANCH    branch to clone (default: main)
  DOTFILES_REPO_URL  repo to clone, e.g. a local path for testing
EOF
}

main "$@"
