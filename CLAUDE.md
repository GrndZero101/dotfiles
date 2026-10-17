# CLAUDE.md

GNU Stow dotfiles for Linux and macOS: config for command-line **tools**
(tmux, sesh, …) plus two deliberately basic **zsh** configs for fresh boxes
and containers. While `PLAN.md` exists, it is the build brief: follow its
phases and decisions, and don't re-open what it marks as decided.

## The Iron Boomer Doctrine

**Complexity has to earn its place.** Every file, flag, script and plugin
must have a concrete answer to "what breaks, or gets worse, if we delete
it?" If there's no good answer, it doesn't go in.

1. **Built-in beats plugin, plugin beats script, script beats framework.**
   Reach for the next level only when the one before it can't do the job.
2. **No abstraction before the second use.** No profiles, no shared base
   files, no helpers until the same thing is repeated by hand.
3. **Plain tools, used directly.** Day-to-day is `stow`, not a wrapper.
   Scripts exist only for what stow can't do (bootstrap, validate).
4. **Comment the why, never the what.** Every non-obvious line says why
   it's there.
5. **Deleting things is progress.**
6. **Fail loudly, not cleverly.** Scripts use `set -eu`, print what they're
   about to do, and stop on conflicts instead of "fixing" them.
7. **Must work on a vanilla box.** Every package works, or at least doesn't
   error, on stock Ubuntu or a fresh container with only its own tool
   installed, and with **no internet**. Optional integrations are guarded,
   never assumed.

`tmux-minimal` and `zsh-minimal` follow the doctrine with **no exceptions**:
no plugins, no downloads. The accepted exceptions are `tmux-full` (tpm
plugins), `tmux-raidboss` (tmux-full plus a HUD of plugin modules, on
purpose over the top) and `zsh-antidote` (zsh-vi-mode and fzf via antidote).

## Package conventions

1. **One package per tool, or per tool variant:** `<tool>` or
   `<tool>-<variant>`. Variants of one tool are alternatives; install
   exactly one. Stow enforces this because they own the same paths.
2. **A package mirrors `$HOME` exactly.** `tmux-full/.config/tmux/tmux.conf`
   lands at `~/.config/tmux/tmux.conf`; `zsh-minimal/.zshrc` at `~/.zshrc`.
3. **Prefer XDG** when the tool supports it on the oldest version we care
   about. Use the trad `~/.foorc` path only when there's nothing else, or
   when it's the default a vanilla box expects (zsh's `~/.zshrc`).
4. **Assume the default `XDG_CONFIG_HOME`** (`~/.config`). Packages
   hardcode `.config/`; `check.sh` warns if it's set to anything else.
5. **Hidden files stay hidden in the repo.** No `stow --dotfiles`.
6. **Tool packages are shell-agnostic.** They never edit shell startup
   files. Tool shell hooks (`zoxide init`, `fzf --zsh`) live in the `zsh-*`
   packages, each guarded by "is this tool installed?".
7. **Each package works alone.** A missing optional tool degrades one
   feature, never the whole config.
8. **Companion configs live inside the package they serve.** sesh's config
   only serves `tmux-full`'s picker, so it's `tmux-full/.config/sesh/`.
   Split it out with `git mv` the day it's needed without that package.

**Adding a tool:** create `<tool>/` mirroring its path under `~`, add a
line to the README packages table, run `./check.sh`.

Stow reads `.stowrc` (`--target=~ --no-folding`) from the **current
directory**, so run stow from the repo root. `--no-folding` keeps
`~/.config/<tool>/` a real directory, so tool-written files such as tpm's
`plugins/` never land in the repo.

## The shell-config boundary

[shell-config](https://github.com/GrndZero101/shell-config) owns rich shell
setups: `ZDOTDIR` profiles, `csm`, prompts, plugin ecosystems. This repo must
work **alongside** it and never compete.

- **Never ship `~/.zshenv`.** It's shell-config's profile selector.
- **`tmux-*` and other tool packages** are safe everywhere, including
  shell-config machines.
- **`zsh-*` packages are for fresh boxes and containers only.** Develop and
  test them **only in Docker**, never by starting them on a shell-config
  host. `zsh -n` (syntax only) is the one thing safe to run on the host.
  `bootstrap.sh` refuses `zsh-*` when `~/.zshenv` exists.
- This workstation runs shell-config. Tool shell hooks it needs (e.g.
  zoxide for sesh) belong in the active shell-config profile, not here.
- Nothing is ever written outside `$HOME`. No `sudo`, no `/etc`, no system
  packages: print the install hint instead.

## Project conventions

- **Commits:** Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`,
  `test:`), scoped by package where it helps: `feat(tmux-minimal): …`.
- **Scripts:** POSIX `sh`, `set -eu`, about 100 lines max each, shellcheck
  clean (`install.sh` with `--shell=sh`). Output is prefixed `dotfiles: `;
  progress to stdout, errors to stderr. Exit 0 means done; non-zero means
  nothing was half-done. Never use `stow --adopt`.
- **README:** order is title and tagline, badges (only true ones: MIT now,
  CI once it exists), quick start (one-liner first), packages, usage,
  updating, uninstalling, coexisting with shell-config, testing on a fresh
  box, design, license.
- **GitHub Markdown, used for meaning, not decoration:** about 5 alerts in
  the whole README, `<details>` for long reference tables, `<kbd>` for
  every key binding, one mermaid diagram (the install flow), language-tagged
  code fences, relative links. No hand-maintained table of contents.
- **The repo is public.** No secrets; review before every push. Confirm
  with the user before pushing.
- **Not yet:** CHANGELOG, release tags, CONTRIBUTING, SECURITY,
  `.editorconfig`, CI, pre-commit hooks. Each needs a real reason first.
