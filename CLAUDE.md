# CLAUDE.md

GNU Stow dotfiles for Linux and macOS: config for command-line **tools**
(tmux, sesh, …) plus two deliberately basic **zsh** configs for fresh boxes
and containers. Open and parked work lives in `TODO.md`. Decisions live
where they apply: this file for the rules, the README's Design section for
readers, and the why next to each line in the configs and scripts. The
build history (`PLAN.md`, retired 2026-10-17) is in git.

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
purpose over the top), `tmux-quiet` (tmux-full with fewer status jobs, for
endpoint-protected laptops) and `zsh-antidote` (zsh-vi-mode and fzf via
antidote).

## Package conventions

1. **One package per tool, or per tool variant:** `<tool>` or
   `<tool>-<variant>`. Variants of one tool are alternatives; install
   exactly one. Stow enforces this because they own the same paths. It's
   also how machines get different subsets, and why repo-root files (README,
   scripts) are never stowed.
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
   When variants need the same companion file, an identical one is a
   relative symlink to the first variant's copy (it can't drift); one that
   differs is a copy. `tmux-raidboss` and `tmux-quiet` do both with
   `tmux-full`'s files.

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
- The canonical shell-config checkout is whichever one `~/.zshenv` links
  to (`readlink -f ~/.zshenv`); on 2026-10-17 that was
  `~/projects/github/GrndZero101/shell-config`. Compare the zsh packages
  with its `zsh-clean` and `zsh-zero`.

## Portability

- **Linux and macOS are first-class; WSL counts as Linux.** Native Windows
  is out of scope (no tmux, no zsh, and stow needs Perl and symlink rights).
- `tmux-full`, `tmux-raidboss` and `tmux-quiet` get their extras from
  Homebrew on both (`Brewfile`). The minimal and zsh packages need only
  distro packages, so they suit containers.
- **No pinning, anywhere: always the latest.** tpm plugins, antidote,
  zsh-vi-mode and fzf track their default branches. Updates are explicit
  commands (README, Updating), never automatic at startup.
- If anything stops relying on brew: Debian/Ubuntu ship `fd` as `fdfind`
  and `bat` as `batcat`.

## Testing changes

- **tmux with a fake `HOME` needs its own server.** The socket follows the
  uid and `$TMUX`, not `$HOME`, and tpm trusts an inherited
  `TMUX_PLUGIN_MANAGER_PATH` over its own detection. Use
  `env -u TMUX -u TMUX_PANE -u TMUX_PLUGIN_MANAGER_PATH HOME=<tmp>` plus
  `tmux -L <name>`, or a `tmux` wrapper on `PATH` that adds `-L`, so tpm's
  calls are isolated too. `TMUX_TMPDIR` paths over about 108 bytes fail
  ("File name too long").
- **stow expands the `~` in `.stowrc` from `$HOME`,** so `HOME=<tmp>
  ./bootstrap.sh` links only inside `<tmp>`.
- **To see a status line,** attach a client from a second server
  (`tmux -L outer -f /dev/null new -d "tmux -L <name> attach"`) and
  `capture-pane -p` it; `#()` jobs need a few seconds to fill in.
- **The interactive shell on this workstation is zsh,** which doesn't
  word-split `$var`: pass flag lists as arrays, or test under `sh -c`.

## Project conventions

- **Commits:** Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`,
  `test:`), scoped by package where it helps: `feat(tmux-minimal): …`.
- **Scripts:** POSIX `sh`, `set -eu`, about 100 lines max each
  (`bootstrap.sh`, about 135 with variant switching, is the accepted
  exception), shellcheck clean (`install.sh` with `--shell=sh`), formatted
  with `shfmt --indent=2 --case-indent`. Output is prefixed `dotfiles: `;
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
- **License: MIT,** like shell-config: legal teams pre-approve it, so the
  repo can be cloned at work. Adapted snippets (the sesh README binding,
  catppuccin/fzf colours, catppuccin/tmux) are MIT too; keep their credit
  comments.
- **Git hooks:** `.pre-commit-config.yaml`, run by prek (`prek install`
  once per clone). Each commit runs `./check.sh`, the built-in hygiene
  hooks, a pinned shellcheck and shfmt on `*.sh`, a pinned rumdl on
  Markdown (`.rumdl.toml`), and checks the message is Conventional
  Commits. It uses prek's `repo: builtin`, so plain `pre-commit` can't run
  it.
- **Not yet:** CHANGELOG, release tags, CONTRIBUTING, SECURITY,
  `.editorconfig`, CI (parked in `TODO.md`). Each needs a real reason first.
