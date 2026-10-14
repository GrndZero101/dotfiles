# dotfiles

GNU Stow dotfiles for tmux, sesh and basic zsh, on Linux and macOS.

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

> [!IMPORTANT]
> Under construction. All four packages are in the repo, but there's no
> installer yet; [`PLAN.md`](PLAN.md) tracks the build.

## Quick start

_Coming with `install.sh`._

## Packages

| Package | What it is | Requires | Safe on shell-config machines |
|---|---|---|---|
| `tmux-full` | **Default.** Bells-and-whistles tmux: tpm plugins, catppuccin, sesh session picker (ships its sesh config) | tmux 3.8+, Homebrew (see `Brewfile`) | ✅ |
| `tmux-minimal` | Pure tmux, no plugins, same muscle memory | tmux 3.2+ | ✅ |
| `zsh-minimal` | Basic `~/.zshrc` for fresh boxes: history, completion, vi mode. No plugins, no downloads | zsh | ❌ containers and fresh boxes only |
| `zsh-antidote` | `zsh-minimal` plus zsh-vi-mode and fzf, self-installed via antidote, offline-safe | zsh, git; curl or wget for fzf | ❌ containers and fresh boxes only |

Variants of the same tool are alternatives: install exactly one.

**Common combinations:**

| Machine | Packages |
|---|---|
| Workstation with shell-config | `tmux-full` (the default) |
| Server where you only want tmux | `tmux-minimal` |
| Fresh container, full comfort | `zsh-antidote tmux-minimal` |
| Fresh container, nothing downloaded | `zsh-minimal tmux-minimal` |

## Usage

_Coming soon._

## Updating

_Coming soon._

## Uninstalling

_Coming soon._

## Coexisting with shell-config

_Coming soon._

## Testing on a fresh box

_Coming soon._

## Design

_Coming soon._ Until then, see [`CLAUDE.md`](CLAUDE.md).

## License

[MIT](LICENSE)
