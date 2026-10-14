# Dotfiles plan

A GNU Stow dotfiles repo for Linux and macOS. It manages the config files of
command-line **tools**: tmux first, then sesh and others. It also has two
deliberately basic **zsh** configs for fresh boxes and containers. This plan
is the brief for the build session: it records what has been decided, what
still needs deciding, and the order of work.

Written 2026-10-14 from a working session on `~/.config/tmux`. Versions in
use on that machine (WSL2 Ubuntu, Linuxbrew): tmux 3.8, GNU Stow 2.4.1,
sesh 2.33.0, fzf 0.74.5, catppuccin/tmux 2.3.1, zsh 5.9.

---

## Scope

**In scope:**
- **Tool configs, in either layout.**
  - "Trad" tools scatter dotfiles in `$HOME` (`~/.foorc`).
  - XDG tools keep theirs under `~/.config/<tool>/`.
  - Stow treats both the same way (see Package conventions).
- **Two tmux configs**, as alternatives:
  - **`tmux-full`**: bells and whistles, the default.
  - **`tmux-minimal`**: pure tmux, no plugins.
- **Two zsh configs**, as alternatives. Both are stowed to zsh's **default
  locations** for a vanilla Ubuntu install or a fresh OS Docker container,
  and both loosely follow the `zsh-clean` and `zsh-zero` profiles from
  [shell-config](https://github.com/GrndZero101/shell-config):
  - **`zsh-minimal`**: native zsh with no plugins and no downloads.
  - **`zsh-antidote`**: the same basics plus **zsh-vi-mode** and **fzf**,
    which install themselves through **antidote** and still work offline.
- **sesh config** ships **inside `tmux-full`** (`tmux-full/.config/sesh/`), because it only exists to serve tmux-full's `prefix + T` picker.

**Where each package applies:**
- **`tmux-*` (and future tool packages)** go on **any** machine,
  including ones where shell-config manages the shell, like this
  workstation. They never touch shell startup files.
- **`zsh-*`** are only for fresh boxes and containers that *don't* use
  shell-config. They're developed and tested **only in Docker containers**,
  never on a shell-config machine.

**Out of scope:**
- **Rich shell setups.** `ZDOTDIR` profiles, profile switching, `csm`, shell
  prompts and plugin ecosystems all belong to **shell-config**. This repo
  must work *alongside* shell-config on machines that use it, and must never
  compete with it (see Coexisting with shell-config).
- **Anything below the user level:** system packages, `/etc`, services. The
  repo only ever writes inside `$HOME`.

---

## The Iron Boomer Doctrine

**Complexity has to earn its place.** Every file, flag, script and plugin in
this repo must have a concrete answer to "what breaks, or gets worse, if we
delete it?" If there's no good answer, it doesn't go in.

In practice:

1. **Built-in beats plugin, plugin beats script, script beats framework.**
   Reach for the next level only when the one before it can't do the job.
2. **No abstraction before the second use.** One default-package variable
   comes before any "profile" system, and a profile system only arrives once
   the same package list keeps being typed by hand.
3. **Plain tools, used directly.** Day-to-day you run `stow`, not a wrapper
   around `stow`. Scripts exist only for things stow can't do (bootstrap a
   fresh machine, validate configs).
4. **Comment the why, never the what.** Every non-obvious line says why it's
   there. That habit already saved us during the tmux 3.7 prompt fix.
5. **Deleting things is progress.** Removing a line that no longer pulls its
   weight counts as work done.
6. **Fail loudly, not cleverly.** Scripts use `set -eu`, print what they're
   about to do, and stop on conflicts instead of "fixing" them.
7. **Must work on a vanilla box.** Every package has to work, or at least
   not error, on a stock Ubuntu install or a fresh container where only its
   own tool is installed. Optional integrations are guarded, never assumed.
   That includes having **no internet**: anything downloaded at runtime must
   fail quietly and fall back.

**The "minimal" packages follow the doctrine with no exceptions.**
`tmux-minimal` and `zsh-minimal` have no plugins and download nothing.

**Exceptions we've accepted** (each with its reasons in its own section):
- **`tmux-full`** uses tpm plugins. It's the bells-and-whistles option by
  definition, and it was migrated as-is.
- **`zsh-antidote`** installs zsh-vi-mode and fzf through antidote. These
  are the only third-party code the repo downloads from shell startup.

---

## What the reference repos do, and where we differ

- **[joshmedeski/dotfiles](https://github.com/joshmedeski/dotfiles)** and
  **[dreamsofcode-io/dotfiles](https://github.com/dreamsofcode-io/dotfiles)**
  both mirror `$HOME` as a **single stow package at the repo root**
  (`stow .`). They use `.stow-local-ignore` to keep README, docs and scripts
  out of `$HOME`, and they gitignore `.config/tmux/plugins` because stow
  folded `~/.config/tmux` into the repo and tpm then installed plugins there.
- Both have install scripts that have gone stale. Josh's `quickstart.sh` has
  a broken shebang, references tools he no longer uses and installs tpm to a
  different path than his config expects. **Lesson: keep scripts tiny so
  they stay true.**

**We use one package per tool variant**, not a single root package. That's
the one structural choice that makes it more complex than the references,
and it earns its place three ways:
1. **Alternatives share one path.** `tmux-full` and `tmux-minimal` both own
   `~/.config/tmux/tmux.conf`; `zsh-minimal` and `zsh-antidote` both own
   `~/.zshrc`. With separate packages, stow itself guarantees only one of
   each pair is installed. If you try to stow both, it refuses with
   "existing target is stowed to a different package".
2. **Machines get different subsets.** Your workstation gets `tmux-full` and
   its sesh config but **no** `zsh-*`, because shell-config owns the shell there. A
   container gets `zsh-antidote` and `tmux-minimal`. A single root package
   can't express that.
3. **Repo-root files are never stowed,** because only named packages are.
   That means README, PLAN and scripts stay out of `$HOME` with no
   `.stow-local-ignore` needed.

---

## Package conventions

These apply to every package: today's, and any tool added later.

1. **One package per tool, or per tool variant.** The name is
   `<tool>` (for example a future `git`) or `<tool>-<variant>`
   (`tmux-full`, `tmux-minimal`, `zsh-antidote`, `zsh-minimal`). Variants
   of the same tool are **alternatives**: install exactly one.
2. **A package mirrors `$HOME` exactly.** What's inside is the path relative
   to `~`:

   | Tool style | Lives at | Package path |
   |---|---|---|
   | Trad | `~/.zshrc` | `zsh-minimal/.zshrc` |
   | XDG | `~/.config/sesh/sesh.toml` | `tmux-full/.config/sesh/sesh.toml` (companion config, convention 8) |
   | XDG + scripts | `~/.config/tmux/scripts/x.sh` | `tmux-full/.config/tmux/scripts/x.sh` |

3. **Prefer XDG when the tool supports it** on the oldest version we care
   about. Use the trad location only when the tool has nothing else, or when
   the trad path is the default a vanilla box expects. That's why zsh uses
   `~/.zshrc`: see the zsh packages.
4. **Assume the default `XDG_CONFIG_HOME`** (`~/.config`). Packages hardcode
   `.config/`. If `XDG_CONFIG_HOME` is set to something else, `check.sh`
   warns. Supporting a moved XDG directory isn't worth the complexity.
5. **Hidden files stay hidden in the repo.** No `stow --dotfiles`
   (`dot-zshrc` renaming). It would add a translation step to save typing
   `ls -A`.
6. **Tool packages are shell-agnostic.** They never edit shell startup files.
   A tool's shell hook (`zoxide init`, `fzf --zsh`) lives in the `zsh-*`
   packages, guarded by "is this tool installed?". On a machine using
   shell-config, those hooks belong in the shell-config profile instead.
7. **Each package works alone** (doctrine rule 7). `tmux-full` without sesh
   installed should not break tmux; at worst, `prefix + T` shows an error.
8. **Companion configs live inside the package they serve.** If a tool's
   config exists **only** to support one package, ship it in that package.
   sesh is the example: its config only serves `tmux-full`'s `prefix + T`
   picker, so it's `tmux-full/.config/sesh/sesh.toml`, not a separate
   `sesh` package. Stow doesn't mind a package spanning two tools' paths.
   **Split it out** (`git mv`) the day it's needed without that package,
   for example sesh used with `tmux-minimal` or straight from the shell.

**Adding a new tool:**
1. Create `<tool>/` that mirrors its path under `~`.
2. Add a line to the README packages table.
3. Run `./check.sh`.

That's all.

---

## Repo layout (target)

```
dotfiles/
├── PLAN.md                  # this file (delete or archive once built)
├── LICENSE                  # MIT, same as shell-config
├── README.md                # packages table, install, switching variants, coexistence notes
├── CLAUDE.md                # doctrine + conventions for future Claude sessions
├── .stowrc                  # --target=~ and --no-folding (see below)
├── .gitignore
├── Brewfile                 # deps for tmux-full + sesh (Linux + macOS via Homebrew)
├── install.sh               # the curl | sh one-liner: clone (or update) the repo, then run bootstrap.sh
├── bootstrap.sh             # check deps, back up conflicts, stow packages
├── check.sh                 # validate: configs parse, scripts lint, stow dry-run
├── test/
│   └── Dockerfile           # vanilla Ubuntu + zsh/tmux/stow/git/curl, for container tests
│
├── tmux-full/               # XDG layout: the bells-and-whistles config (DEFAULT)
│   └── .config/
│       ├── tmux/
│       │   ├── tmux.conf
│       │   └── scripts/
│       │       └── sesh-picker.sh
│       └── sesh/            # companion config (convention 8): serves prefix + T
│           └── sesh.toml
│
├── tmux-minimal/            # XDG layout: pure tmux, no plugins
│   └── .config/tmux/
│       └── tmux.conf
│
├── zsh-minimal/             # trad layout: zsh default location, no plugins
│   └── .zshrc
│
└── zsh-antidote/            # trad layout: zsh-minimal + antidote (zsh-vi-mode, fzf)
    ├── .zshrc
    └── .zsh_plugins.txt
```

### `.stowrc`
```
--target=~
--no-folding
```
- `--target=~` lets the repo live anywhere (here it's under
  `~/projects/github/GrndZero101/dotfiles`, not `~/dotfiles`), and plain
  `stow tmux-full` still links into `$HOME`.
- `--no-folding` makes stow link **files**, not whole directories.
  `~/.config/tmux/` stays a real directory, so tpm's `plugins/` lands there
  and never in the repo. This is the problem the reference repos work around
  with a gitignore entry. It also keeps `~/.config/` itself a real directory
  that other tools can write to.
- Stow reads `.stowrc` from the **current directory**, so stow commands are
  run from the repo root. The scripts `cd` there themselves.

### `.gitignore`
A single defensive line, `plugins/`. It only matters if someone runs stow
without `.stowrc`. It's cheap insurance against committing third-party code.

---

## Everyday use (no wrapper needed)

From the repo root:

| Task | Command |
|---|---|
| Install a package | `stow tmux-full` |
| Remove a package | `stow -D tmux-full` |
| Re-link after adding files | `stow -R tmux-full` |
| Dry run (see what would happen) | `stow -n -v tmux-full` |
| Switch tmux variant | `stow -D tmux-full && stow tmux-minimal` |
| Switch zsh variant (containers) | `stow -D zsh-minimal && stow zsh-antidote` |
| Try tmux-minimal **without** switching | `tmux -L minimal -f "$PWD/tmux-minimal/.config/tmux/tmux.conf" new` |

The last row tries tmux-minimal without installing anything. `-L minimal`
starts a separate tmux server, so your normal sessions aren't touched. The
zsh packages are tried only in a container (Phase 6), never on the host.

**Updating (no pinning, so you always get the latest):**

| What | Command |
|---|---|
| tmux-full plugins | `prefix + U`, then **type `all`** and press Enter (Enter alone cancels), or `~/.config/tmux/plugins/tpm/bin/update_plugins all` |
| zsh-antidote plugins | `antidote update` |
| zsh-antidote's fzf binary | `"$(antidote path junegunn/fzf)/install" --bin`, after `antidote update` |

---

## Helper scripts

Three scripts, all POSIX `sh` with `set -eu`. Each must stay under about
100 lines; if one grows past that, stop and reconsider.
- `install.sh` gets the repo onto the machine.
- `bootstrap.sh` stows packages.
- `check.sh` validates.

`bootstrap.sh` and `check.sh` `cd` to the repo root first.

### `install.sh [package]...`: the one-liner
**It earns its place** because the main use of the minimal packages is a
fresh box or container. "One command from nothing to configured" is the
whole point there, and it's the modern convention people expect from a
README. It mirrors shell-config's installer (same default location, same
env-var style, same "clone, then hand off" shape) but is **POSIX `sh`**,
because a server getting only `tmux-minimal` may not have zsh. Aim for
about 40 lines.

**The README leads with it:**
```sh
# default (tmux-full):
curl -fsSL https://raw.githubusercontent.com/GrndZero101/dotfiles/main/install.sh | sh

# choose packages (everything after `--` is passed to bootstrap.sh):
curl -fsSL https://raw.githubusercontent.com/GrndZero101/dotfiles/main/install.sh | sh -s -- zsh-antidote tmux-minimal

# no curl? wget works the same:
wget -qO- https://raw.githubusercontent.com/GrndZero101/dotfiles/main/install.sh | sh
```

**Behaviour:**
1. **Check for `git`.** If it's missing, print the install hint and exit.
   `curl` or `wget` is already proven by the fact the script is running.
2. **Clone, or reuse an existing clone,** into `DOTFILES_DIR`.
   - If the directory doesn't exist: `git clone --depth 1 --branch
     "$DOTFILES_BRANCH" "$DOTFILES_REPO_URL" "$DOTFILES_DIR"`.
   - If it's already a clone of this repo (it has `.git` and
     `bootstrap.sh`): `git pull --ff-only`. **Re-running the one-liner
     updates.** If the pull fails, for example because of local changes,
     warn and carry on with what's there.
   - If it exists but is something else: **refuse** with a clear message.
     Never overwrite a directory the script doesn't recognise.
3. **Hand off:** `exec "$DOTFILES_DIR/bootstrap.sh" "$@"`. Package
   arguments pass straight through, and no arguments means bootstrap's
   default (`tmux-full`). All the real work, including dependency checks,
   the shell-config guard and conflict backups, stays in one place.

**Environment overrides.** These match shell-config's naming, and each one
has a concrete use:

| Variable | Default | Why it exists |
|---|---|---|
| `DOTFILES_DIR` | `${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles` (same as shell-config's choice) | put the clone elsewhere, for example `~/projects/github/GrndZero101/dotfiles` on this workstation |
| `DOTFILES_BRANCH` | `main` | test the installer from a feature branch **before** merging |
| `DOTFILES_REPO_URL` | `https://github.com/GrndZero101/dotfiles.git` | test from a **local checkout** in a container (`DOTFILES_REPO_URL=/dotfiles`) without pushing |

No command-line flags. Positional arguments are packages, and the three
variables cover everything else. Shell-config's `--dir`/`--repo`/`--branch`
flag parser isn't needed here.

**Pipe-to-shell safety:**
- **The whole body lives in a `main` function, called on the last line.**
  If the download is cut off halfway, `sh` sees an incomplete function
  definition and runs **nothing**, rather than half a script. This is the
  standard guard in curl-pipe installers, and it costs two lines.
- **The README also shows an "inspect first" route** for cautious and
  corporate environments:
  ```sh
  curl -fsSLO https://raw.githubusercontent.com/GrndZero101/dotfiles/main/install.sh
  less install.sh && sh install.sh
  ```
- **No `sudo`, and nothing outside `$HOME`.** The doctrine's scope rule
  applies to the installer too.

### `bootstrap.sh [package]...`
For a fresh machine, or when first adopting the repo on an existing one.
**Arguments are package names.** There are no profiles (doctrine rule 2).

**With no arguments, it installs the default:**
```sh
DEFAULT_PACKAGES="tmux-full"   # change this one line to change the default
```
This is the first non-comment line of the script, so changing the default
is a one-line edit. Any arguments replace the default entirely.

**Common combinations** (for the README, not code):

| Machine | Command |
|---|---|
| Workstation with shell-config (like this one) | `./bootstrap.sh` (the default, `tmux-full`) |
| Server where you only want tmux | `./bootstrap.sh tmux-minimal` |
| Fresh container, full comfort | `./bootstrap.sh zsh-antidote tmux-minimal` |
| Fresh container, nothing downloaded | `./bootstrap.sh zsh-minimal tmux-minimal` |

Steps:
1. **Detect the OS** with `uname -s` (`Linux` or `Darwin`; WSL reports
   `Linux`). This is only used to print the right install hint.
2. **Check dependencies.**
   - Always required: `stow`, `git`.
   - Each package needs its tool: `tmux-*` needs `tmux`, and `zsh-*` needs
     `zsh`.
   - `tmux-full` needs Homebrew for the rest (`brew bundle --file
     Brewfile`). **As built, these only warn**, with the `brew bundle`
     command, and don't exit: they're optional (convention 7), and tmux
     runs without them.
   - If anything is missing, **print** the install command for the OS
     (`brew install …`, `sudo apt install …`) and exit. Don't run `sudo` on
     the user's behalf.
3. **Refuse two variants of the same tool** (for example `tmux-full
   tmux-minimal`) with a clear message. Stow would refuse anyway, but less
   readably.
4. **Guard against shell-config.** When a `zsh-*` package is requested and
   `~/.zshenv` exists, stop with a clear message. Today that file means
   shell-config is managing the shell, so a stowed `~/.zshrc` would be
   ignored silently. This check earns its place because otherwise the only
   symptom is "my config does nothing".
5. **Find conflicts** by running `stow -n` for each package and parsing
   "existing target" conflicts.
6. **Back up conflicts.** Move each conflicting real file to
   `~/.local/state/dotfiles-backup/<timestamp>/<same path>`. Print every move.
   **Never use `stow --adopt`**: it overwrites the repo's version with
   whatever is on the machine, which is the opposite of what we want.
7. **Stow** the packages.
8. **For `tmux-full` only,** bootstrap tpm: clone
   `https://github.com/tmux-plugins/tpm` to `~/.config/tmux/plugins/tpm` if
   it isn't there, then run `~/.config/tmux/plugins/tpm/bin/install_plugins`.
   This must happen **before tmux first starts** (see the known issue under
   Phase 2). Verified 2026-10-14: with no server running, `install_plugins`
   starts a temporary server to read the plugin path, installs everything
   (about 6s), exits 0, and leaves no server behind. If a clone fails it
   prints "download fail"; check its exit status and stop loudly.
9. **Print the next steps.** If a `zsh-*` package was stowed and zsh isn't
   the login shell, print `chsh -s "$(command -v zsh)"`, but don't run it.

### `check.sh`
This earns its place because on 2026-10-14 a single missing `#` stopped
tmux loading the whole config, and nothing caught it.

1. **tmux:** for each `*/.config/tmux/tmux.conf`, parse it on a throwaway
   server: `tmux -L check-$$ -f /dev/null new -d`, then
   `tmux -L check-$$ source-file -n <file>`, then kill that server.
   **These must be three separate `tmux` invocations.** Chained with `\;`
   into one, tmux prints the parse error but exits 0, because the exit
   status comes from the trailing `kill-server` (verified on tmux 3.8). Run
   on its own, `source-file -n` exits 1 on an error.
2. **zsh:** `zsh -n` on each `zsh-*/.zshrc`. This only checks syntax and runs
   nothing, so it's safe on a shell-config host. The real startup tests run
   only inside the Phase 6 container.
3. **Scripts:** run `shellcheck` on every `*.sh` if shellcheck is installed.
   Otherwise warn and skip it, rather than failing.
4. **Stow:** `stow -n` for every package, which reports conflicts without
   changing anything. Run variants of the same tool **separately**, because
   they conflict with each other by design. **As built, the target is an
   empty temporary directory** (`-t` overrides `.stowrc`), so the check
   validates the repo, not this machine. Against `$HOME` it would fail on
   this workstation until Phase 8 (the real `~/.config/tmux`, the stale
   `~/.zshrc`), and conflicts on a real machine are bootstrap's job.
5. **Environment:** warn (don't fail) if `XDG_CONFIG_HOME` is set to
   anything other than `~/.config`.

Exit non-zero on any failure, so it can later become a git pre-commit hook
or a CI step without changes. Neither of those is in scope yet.

---

## The zsh packages: basic zsh for vanilla boxes

**Purpose:** a fresh Ubuntu install or `docker run ubuntu` has no zsh
config. Starting zsh launches the `zsh-newuser-install` wizard, and you get
no history or completion menu. Both packages fix that with `~/.zshrc` in
zsh's **default location**, without `ZDOTDIR`.

| | `zsh-minimal` | `zsh-antidote` |
|---|---|---|
| Files | `.zshrc` | `.zshrc`, `.zsh_plugins.txt` |
| Vi mode | `bindkey -v` | **zsh-vi-mode** (falls back to `bindkey -v`) |
| fzf | uses a system fzf if it supports `--zsh` | **installs its own** latest fzf; falls back to a system one |
| Network at startup | **never** | first run only, then never (it's idempotent) |
| Size target | about 60 lines | about 85 lines |
| Doctrine | no exceptions | accepted exception |

**These are two standalone files.** `zsh-antidote/.zshrc` is
`zsh-minimal/.zshrc` plus one clearly fenced plugin block. They can't
`source` each other, because only one is ever stowed. Write `zsh-minimal`
first, then copy it and add the block. A header comment in each file says
"keep the shared part in step with the other". About 60 duplicated lines
cost less than any mechanism to share them (see the parking lot).

### Files
- **No `.zshenv`.** On machines with shell-config, that file is
  shell-config's selector, so shipping one would compete with it. It would
  also run for every non-interactive `zsh -c`.
- **No `.zprofile`.** `docker exec -it box zsh` starts a non-login shell
  that never reads `.zprofile`. Anything placed there would work in one
  place and silently not in the other. Everything goes in `.zshrc`, as
  `zsh-clean` does.
- `.zlogin` and `.zlogout` aren't needed. zsh-clean ships them empty only
  to fill out its profile contract.
- **`.zsh_plugins.txt`** (in `zsh-antidote` only) is the plugin list. It
  sits next to `.zshrc` because that's antidote's default, so no config is
  needed to find it. It's config you edit, so it's stowed. Everything
  **generated or downloaded** goes to XDG directories instead (see
  Plugins).

### Shared contents: zsh-clean, without the shell-config machinery
Both packages keep zsh-clean's behaviour and drop anything that exists only
to support shell-config:

| Keep from zsh-clean | Why |
|---|---|
| The `setopt` set (AUTO_CD, AUTO_PUSHD, EXTENDED_GLOB, HIST_* dedupe, SHARE_HISTORY, INTERACTIVE_COMMENTS, NO_BEEP, NO_FLOW_CONTROL …) | This is most of the "comfortable shell" value, and it costs nothing |
| `HISTSIZE` and `SAVEHIST` of 50000; **`HISTFILE=${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history`**, created with `mkdir -p` | vanilla zsh saves **no history** without a HISTFILE. XDG state matches shell-config (decided) |
| `compinit -d ${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump` + `zstyle` menu select, case-insensitive matcher, list-colors | completion menu. The dump goes to XDG cache, not `~/.zcompdump` |
| **Vi mode** (decided), plus the emacs comfort keys `^A ^E ^P ^N ^R`, Home and End | same muscle memory as zsh-clean |
| Coloured `user@host:path %` prompt, **yellow host over SSH** | tells you at a glance that you're on a remote box |
| The terminal-title `precmd` hook; `mkcd` | small, and used daily |
| `brew shellenv` **if brew exists** | Linuxbrew and macOS brew on PATH, as zsh-clean does it |

| Drop | Why |
|---|---|
| `emulate -L zsh`, `profile.zsh`, `SHELL_PROFILE_*` state/cache/runtime dirs | That's the shell-config profile contract. Default locations replace it |
| `csm` completion, `zsh-profile-select`, `functions/` fpath | shell-config's tooling |
| Scanning six candidate brew completion directories | Replace it with one line: if brew exists, add `$(brew --prefix)/share/zsh/site-functions` to `fpath` (that's where sesh's completions went) |
| `_approximate` completer, `cdpath` with `~/projects` | personal taste, not a baseline. Add back only if missed |
| `take` (same as `mkcd`) | it's a duplicate |

### `zsh-antidote` only: antidote + zsh-vi-mode + fzf
This is the one zsh package that pulls in third-party code at runtime. **It
earns its place:**
- **zsh-vi-mode** adds what plain `bindkey -v` lacks and you rely on:
  - text objects (`ciw`, `di"`), surround, and visual and visual-line modes
  - a cursor that changes shape between insert and normal mode
  - better undo/redo and increment/decrement
- **fzf** gives fuzzy Ctrl-R history, Ctrl-T file search and Alt-C
  directory jumping. On a stock box it's missing, or too old for
  `fzf --zsh`: apt ships 0.44 on Ubuntu 24.04 and 0.29 on 22.04, and
  `--zsh` needs 0.48+. So self-installing is the only way to get the same
  fzf everywhere.
- **antidote** installs itself and compiles the plugin list into one static
  file (one `source` at startup, no parsing). It also clones fzf, so fzf
  needs **no second download mechanism**: one clone path, one failure
  marker and one update command cover all three. More plugins later are
  just another line in `.zsh_plugins.txt`.

**No pinning (decided): always the latest.** antidote is cloned from its
default branch, and the plugins track their default branches. Updates are
**explicit** (`antidote update`; see Everyday use). Shell startup never
checks for updates, because that would mean network traffic on every new
shell.

**How fzf gets installed:** antidote clones `junegunn/fzf`. Then fzf's own
official `install --bin` downloads the **release binary** that matches the
cloned version into the clone's `bin/`. That script:
- handles Linux amd64, arm64, armv7, riscv64 and others, plus macOS Intel
  and Apple Silicon
- uses `curl` or `wget`
- with `--bin`, **never edits rc files**

This is fzf's documented git-install route, not a hand-rolled downloader.

**Where things go:**

| What | Where | Why |
|---|---|---|
| Plugin list (stowed) | `~/.zsh_plugins.txt` | antidote's default, next to `.zshrc` |
| antidote itself | `${XDG_DATA_HOME:-$HOME/.local/share}/antidote` | downloaded code that should persist (XDG data) |
| Plugin clones | antidote's default `antidote home`, which is XDG cache on Linux and `~/Library/Caches` on macOS. **Verify** with `antidote home` | re-downloadable |
| fzf binary | `$(antidote path junegunn/fzf)/bin/fzf`, put on `PATH` by antidote (`kind:path path:bin`). **Verify** that it's prepended, so it wins over an old apt fzf | lives with its clone; if the cache is purged, it reinstalls itself |
| Compiled load file | `${XDG_CACHE_HOME:-$HOME/.cache}/zsh/plugins.zsh`, via `zstyle ':antidote:static' file …` | generated, so cache. Keeps `~/.zsh_plugins.zsh` out of `$HOME` |
| "Last attempt failed" marker | `${XDG_STATE_HOME:-$HOME/.local/state}/zsh/plugins-failed` | see the guards below |

**`.zsh_plugins.txt` starts with two lines.** The build session should
confirm the exact antidote annotations:
```
jeffreytse/zsh-vi-mode
junegunn/fzf kind:path path:bin
```

**The plugin block in `.zshrc`.** These are requirements; the build session
writes the code. Aim for about 25 lines, placed **before** the comfort keys
and tool hooks.
1. **Set zsh-vi-mode options before loading it.**
   `ZVM_INIT_MODE=sourcing`. By default zsh-vi-mode sets its key bindings
   on the first prompt, which **overwrites fzf's Ctrl-R/Ctrl-T and our
   comfort keys** (documented in its README). With `sourcing`, it
   initialises immediately, so bindings made later in `.zshrc` stick. This
   keeps the file in one top-to-bottom order, with no `zvm_after_init`
   hooks.
2. **If antidote is missing,** clone it with `git clone --depth=1 -q`, but
   **only if** `git` exists **and** there's no recent failure marker. On
   failure, remove any partial clone, write the marker, print **one**
   warning line, and carry on.
3. **If antidote is present, run `antidote load`.** On first run it clones
   zsh-vi-mode and fzf and builds the load file. After that it's a single
   `source` with no network.
4. **Check that the plugin actually loaded** (for example, test that a
   `zvm_*` function exists). If it didn't, **delete the compiled load
   file**, write the marker and print one warning.
   - This guard matters. antidote rebuilds the load file only when
     `.zsh_plugins.txt` changes. A load file built during a failed offline
     clone would otherwise stick around after the network returns, and the
     shell would never retry.
   - The build session must check how antidote behaves when a plugin clone
     fails, and adjust this step to match.
5. **If the fzf clone exists but `bin/fzf` doesn't,** run
   `<clone>/install --bin`, quietly, with `timeout`. Do this only if `curl`
   or `wget` exists and there's no recent failure marker. On failure, write
   the marker and print one warning. It only runs once per clone; after that
   the binary is there.
6. **Fallback:** if zsh-vi-mode isn't loaded, use `bindkey -v` and
   `KEYTIMEOUT=1`, which is exactly what `zsh-minimal` does.

**Guards and their reasons:**

| Situation | Behaviour | Why |
|---|---|---|
| No `git` | Skip the bootstrap silently. Behave like `zsh-minimal` | vanilla box (doctrine rule 7) |
| No network (DNS fails) | The clone fails fast. Write the marker and print one warning. Behave like `zsh-minimal` | offline container |
| Network "hangs" (packets dropped, captive portal) | Wrap all downloads in one `timeout 30` (built as 30, not 10: it covers three clones, not one) **if** `timeout` exists (it does on Linux; on macOS it's `gtimeout`, if anything). The marker stops this happening on every new shell | prevents a 2-minute stall in every new tmux pane |
| Recent failure marker (for example, less than 60 minutes old) | Don't try again. Behave like `zsh-minimal` | a zsh glob qualifier on the marker's age, like `(Nmm-60)`, does this in one line. **The marker earns its place**: without it, an offline box re-attempts the download in every new shell |
| Everything installed | Never touches the network | idempotent. Updates only happen through an explicit `antidote update` |
| `GIT_TERMINAL_PROMPT=0` during the clone | A bad URL can't pop up a credential prompt in the middle of shell startup | — |
| No `curl` and no `wget` (the stock `ubuntu` Docker image has neither) | Skip the fzf binary download silently. Use a system fzf if it supports `--zsh`; otherwise there are no fzf bindings | doctrine rule 7. A vanilla Ubuntu *install* does have curl/wget, but a bare container doesn't |
| fzf binary download fails partway | `install --bin` exits non-zero. Write the marker and print one warning. The next attempt comes after the cooldown | same rules as the git clones |

**Not in scope:** zsh-vi-mode's own clipboard integration. tmux already
does OSC 52, so there's no need for a second mechanism yet.

### Tool hooks, each guarded (convention 6), in both packages
- `zoxide init zsh`. **sesh depends on this:** without the hook, zoxide never
  learns directories, so the sesh picker's directory list stays empty.
- `source <(fzf --zsh)` (fzf 0.48+) for Ctrl-R, Ctrl-T and Alt-C. In
  `zsh-antidote`, it must come **after** zsh-vi-mode loads;
  `ZVM_INIT_MODE=sourcing` makes that order work. Normally the `fzf` found
  is the self-installed one.
  - **Guard against old fzf.** In `zsh-minimal`, or when `zsh-antidote`'s
    own fzf couldn't install, the only fzf may be apt's old one, without
    `--zsh`. Without a guard every shell would print "unknown option".
  - Silence the generator (`fzf --zsh 2>/dev/null`) or check its exit
    status, so old fzf just means "no fzf bindings". Don't parse version
    numbers.

Each hook is a single `if (( $+commands[tool] )); then …; fi` line. On a
vanilla box none of these tools are installed, so none of the hooks run.
Doctrine rule 7 holds.

### Vanilla-box caveats (put these in the README)
- **The Ubuntu Docker image has no zsh.** `apt install zsh`, as bootstrap's
  dependency check will say.
- **Ubuntu's `/etc/zsh/zshrc` already runs `compinit`,** so ours runs a
  second time. We **accept** this. The fix (`skip_global_compinit=1`) has to
  go in `~/.zshenv`, which is shell-config's file. It costs a few
  milliseconds; note it and move on.
- **macOS `/etc/zprofile` runs `path_helper`,** which reorders PATH for login
  shells. Running `brew shellenv` in `.zshrc` (after that point) keeps brew
  first. The build session should verify this on a Mac.

### Coexisting with shell-config
- **Tool packages (`tmux-*`) are always safe** on shell-config
  machines. They only link files under `~/.config/<tool>/`, which
  shell-config never touches.
- **Machines using shell-config** (like this one: `~/.zshenv` →
  shell-config, `ZDOTDIR` → `zsh-tll-citadel-dev-fortress`) **don't stow
  `zsh-*`.** The default doesn't include them, and bootstrap refuses them
  when `~/.zshenv` exists.
- **Vanilla machines** get a `zsh-*` package from this repo. To move one up
  to shell-config later, run `stow -D zsh-antidote` (or `zsh-minimal`) and
  then install shell-config.
- **The two never overlap.** This repo never ships `~/.zshenv`, and
  shell-config never relies on `~/.zshrc` (its `.zshrc` lives in
  `ZDOTDIR`). Stale `~/.zshrc` and `~/.zprofile` files on this machine are
  ignored today, and stay untouched.

---

## The two tmux configs

### `tmux-full` (the default): what we have today
This is `~/.config/tmux` as of commit **`778c78c`**. Nothing in it is new;
it's being migrated.
- tmux **3.8+** only. It uses `command-prompt -P`, the 3.7+ `fill` handling
  in `message-style`, and floating-pane-era defaults.
- Plugins via tpm, **unpinned (decided)**: tmux-sensible,
  vim-tmux-navigator (with a `claude` process-name pattern so `C-j` reaches
  Claude Code), tmux-yank, tmux-cpu, tmux-weather, catppuccin (mocha,
  loaded twice on purpose, documented inline), and
  tmux-nerd-font-window-name.
- `prefix + T` opens the sesh session picker
  (`scripts/sesh-picker.sh`). It's an fzf popup themed from catppuccin's
  `@thm_*` palette.
- External tools: `sesh`, `fzf`, `fd`, `zoxide`, `gitmux`. These go in the
  `Brewfile`.

### `tmux-minimal`: pure tmux, written from scratch
Same muscle memory, no plugins, no external tools, every line justified.

**Target tmux 3.2+**, not 3.8. That's what you meet on servers and
containers: Ubuntu 22.04 ships 3.2a, 24.04 ships 3.4, Debian 12 ships 3.3a,
RHEL 9 ships 3.2a. A minimal config that only runs on the newest tmux would
miss the point.

| Feature | How, in pure tmux | Replaces |
|---|---|---|
| Prefix `C-Space` | `set -g prefix C-Space`, plus `bind C-Space send-prefix` | — (decided: Option A, see Already decided) |
| Mouse | `set -g mouse on` | — |
| Windows/panes from 1, renumbered | `base-index 1`, `pane-base-index 1`, `renumber-windows on` | — |
| Splits/new windows keep cwd | `-c "#{pane_current_path}"` on `"`, `%`, `c` | — |
| Pane navigation | `bind h/j/k/l select-pane -L/-D/-U/-R` (**prefixed**) | vim-tmux-navigator |
| Pane resize | `bind -r H/J/K/L resize-pane …` | — |
| Vi copy mode | `mode-keys vi`; `v` begin-selection, `y` copy-selection-and-cancel | tmux-yank |
| System clipboard | `set -g set-clipboard on` (OSC 52, works **over SSH**) | tmux-yank |
| Sensible defaults | `escape-time 10`, `history-limit 50000`, `focus-events on`, `display-time 4000` | tmux-sensible |
| Reload | `bind r source-file -F "#{config_files}" \; display "reloaded"`. Reloads whichever file was loaded, so the `tmux -L minimal -f <repo file>` trial doesn't reload tmux-full's `~/.config/tmux/tmux.conf`. Verified on 3.2a, 3.4 and 3.8 | sensible's `R` |
| True colour | `terminal-features` RGB line (same as full) | — |
| Status line | Built-in only: session name on the left, host name and `%H:%M` on the right, **named colours** (no hex, so it looks right without RGB). The host name shows which box an SSH'd or nested tmux is on | catppuccin, cpu, weather |

**Deliberately left out:**
- **Vim-aware `C-h/j/k/l`.** That needs a `ps` call on every keypress, and
  it's what stole `C-j` from Claude Code. Prefixed `h/j/k/l` has neither
  problem. You lose one keystroke and gain a config with no special cases.
- **Themes, status widgets and the session picker.** Use `prefix + s`
  (`choose-tree`) on 3.2+, and 3.8's built-in fuzzy `switch-mode`
  (`prefix + Tab` / `Shift-Tab`) where available.
- **Anything version-gated** (`%if` on tmux version). If a feature needs a
  version check, it doesn't belong in tmux-minimal.

Clipboard caveat for the build session: `set-clipboard on` relies on the
terminal accepting OSC 52. Windows Terminal, iTerm2, Ghostty, WezTerm and
kitty do. Verify it on WSL and macOS, and write the result in the README.
**WSL: verified 2026-10-14** (copy in tmux-minimal, paste into a Windows
app). It only works from a tmux that isn't nested inside tmux-full, whose
default `set-clipboard external` drops OSC 52 from programs inside it,
including an inner tmux. macOS is still to check (Phase 9).

---

## Project conventions (match modern DevOps tool repos)

The repo should feel familiar to anyone who has used a modern CLI or DevOps
tool repo. Look at starship, mise, lazygit, k9s, sesh or atuin, and at your
own shell-config. Follow their conventions **where they help a reader**;
the doctrine still applies to the docs.

### README.md structure
In this order, and keep it scannable:
1. **Title and a one-line tagline**: what this is, in one sentence.
2. **Badges.** Only badges that are **true and useful**: the license (MIT)
   now, and a CI status badge only once CI exists. No vanity badges.
3. **Quick start.** **The one-liner first**, with the default and the
   choose-packages forms, then "inspect first", then prerequisites.
4. **Packages.** A table of package, what it is, its requirements, and
   whether it's safe on shell-config machines. Then the "common
   combinations" table.
5. **Usage.** Switching variants, trying `tmux-minimal` without switching,
   and the key bindings that differ from stock tmux and zsh.
6. **Updating.** Re-run the one-liner; plugin updates (tpm, antidote, the
   fzf binary).
7. **Uninstalling.** Every serious tool README has this:
   `stow -D <package>`, where backups live
   (`~/.local/state/dotfiles-backup/`), and which caches are safe to delete.
8. **Coexisting with shell-config**, briefly, with a link to it.
9. **Testing on a fresh box**: the Docker recipe.
10. **Design.** The Iron Boomer Doctrine in five lines, plus a link to the
    full version in `CLAUDE.md`.
11. **License.**

### GitHub Markdown features (use them where they add meaning)
GitHub renders these natively. **Use each one for its intended purpose, not
as decoration.** If a page is covered in alerts, nobody reads any of them.

| Feature | Use it for | Example in this README |
|---|---|---|
| **Alerts:** `> [!NOTE]`, `> [!TIP]`, `> [!IMPORTANT]`, `> [!WARNING]`, `> [!CAUTION]` | Things a reader must not miss. Aim for **about 5 in the whole README** | `[!CAUTION]` before `curl \| sh` ("inspect first" link); `[!IMPORTANT]` on "don't stow `zsh-*` on shell-config machines"; `[!NOTE]` "tmux-full needs tmux 3.8+"; `[!TIP]` "try tmux-minimal without switching"; `[!WARNING]` "`prefix + U` needs `all` typed; Enter alone cancels" |
| **Collapsible sections:** `<details><summary>…</summary>` | Long reference material that most readers skip | the full key-binding list per package, the offline-guard table for zsh-antidote, troubleshooting |
| **Keyboard keys:** `<kbd>` | Every key binding | <kbd>C-Space</kbd> <kbd>T</kbd> for the sesh picker; <kbd>C-Space</kbd> <kbd>C-Space</kbd> for nested tmux |
| **Mermaid diagram** (a fenced `mermaid` block) | **One** diagram, only where a picture beats prose | the install flow: `curl \| sh` → `install.sh` → clone or pull → `bootstrap.sh` → `stow` |
| **Tables** | packages, combinations, environment variables, update commands | as above |
| **Language-tagged code fences** (`sh`, `tmux`, `toml`, `zsh`) | every code block | syntax highlighting and a working copy button |
| **Relative links** | `CLAUDE.md`, `LICENSE`, the package folders | links work on GitHub and in clones |

GitHub builds the table of contents automatically (the outline button), so
**don't maintain one by hand**. That's doctrine rule 5 applied to docs.

### Other conventions
- **Commit messages** follow Conventional Commits (`feat:`, `fix:`,
  `docs:`, `chore:`, `test:`), as the existing tmux repo history does.
  Scope by package where it helps: `feat(tmux-minimal): …`.
- **Script output** uses a consistent prefix (`dotfiles: …`), as
  shell-config's installer uses `install:`. It goes to stdout for progress
  and stderr for errors. Exit codes matter: 0 means done, and non-zero
  means nothing was half-done.
- **`install.sh -h` / `--help`** prints usage: the one-liner forms and the
  three environment variables. Every installer in this space does this, and
  it costs about 10 lines. It's the only flag.
- **Not now** (in the parking lot): `CHANGELOG.md`, release tags,
  `CONTRIBUTING.md`, `SECURITY.md`, `.editorconfig`. They're common in tool
  repos, but they haven't earned their place in a personal dotfiles repo
  yet.

---

## Phases

Each phase finishes with its acceptance check passing. Commit after each one.

### Phase 0: freeze the old repo ✅ DONE (2026-10-14)
- The outstanding work is committed in `~/.config/tmux` as **`778c78c`**
  ("feat: in-pane command prompt and sesh session picker"). It includes
  `bind : command-prompt -P`, `detach-on-destroy off`, the `prefix + T` sesh
  binding and `scripts/sesh-picker.sh`.
- ✅ `git -C ~/.config/tmux status` is clean. **`778c78c` is the source
  commit for Phase 2.**

### Phase 1: skeleton
- `git init` (already done before the build session started); add:
  - `README.md`: a stub laid out in the final structure (see Project
    conventions), with headings in place and the packages table filled in
  - `CLAUDE.md`: the doctrine, package conventions, the shell-config
    boundary and the project conventions (README style, Conventional
    Commits, script output)
  - `LICENSE` (MIT, copied from shell-config's)
  - `.stowrc` and `.gitignore`
- Create the public GitHub repo `GrndZero101/dotfiles` (for example
  `gh repo create GrndZero101/dotfiles --public --source . --remote origin`).
  **Confirm with the user before the first push.** Publishing is
  outward-facing.
- ✅ `.stowrc` is honoured. Plain `stow -n -v` can't show it: with no
  packages it exits 1 ("No packages to stow or unstow"). Instead, dry-run a
  throwaway package: `mkdir -p zz/.config/zz && touch zz/.config/zz/x &&
  stow -n -vv zz; rm -rf zz`. Expect target `$HOME` (so `~` is expanded)
  and a `LINK` for the **file** `.config/zz/x`, not the folded directory
  (so `--no-folding` is active). Verified on Stow 2.4.1, 2026-10-14.

### Phase 2: migrate `tmux-full`
- Copy `tmux.conf` and `scripts/sesh-picker.sh` into
  `tmux-full/.config/tmux/`, keeping the executable bit. **Copy, don't
  move.** The old repo stays intact until Phase 9.
- Record in the migration commit message where the files came from:
  `~/.config/tmux` @ `778c78c`. History stays in the archived old repo.
  Don't bring in `git subtree`/`filter-repo` for four commits.
- **Known issue, resolved:** on a fresh machine with no plugins, tmux
  starts but reports **four** errors, not one: both `run` lines (catppuccin
  and tpm) return 127, and both post-tpm `message-style` overrides are
  invalid because `@thm_*` is empty. **Decision: bootstrap installs plugins
  before tmux first starts (step 8); the config is unchanged.** Why:
  - Guarding would take three `if-shell` blocks, not one, and still leave a
    degraded config with no theme or widgets. Installing is the real fix.
  - `install_plugins` works with no server running (verified), so
    bootstrap can do it before tmux is ever launched.
  - Running plain `stow tmux-full` on a fresh box without bootstrap still
    shows the errors. That's doctrine rule 6 (fail loudly): they point
    straight at the missing plugins. The README must say to use bootstrap,
    or `prefix + I`, on a fresh machine.
- **Testing with a fake `HOME` needs tmux isolation.** The tmux socket
  depends on the uid and `$TMUX`, not on `$HOME`, and a shell inside tmux
  inherits `TMUX_PLUGIN_MANAGER_PATH`, which tpm trusts over its own
  detection. Without isolation, tpm reads the **real** plugin directory and
  reports everything as "Already installed". Isolate with
  `env -u TMUX -u TMUX_PANE -u TMUX_PLUGIN_MANAGER_PATH TMUX_TMPDIR=<short dir>`.
  Keep `TMUX_TMPDIR` short: socket paths over about 108 bytes fail with
  "File name too long". This affects tests only. On a real machine the
  inherited value is the correct one.
- ✅ The parse check (written by hand for now, folded into `check.sh` in
  Phase 5) passes.

### Phase 3: write `tmux-minimal`
- Write the config from the table above. Aim for **under 60 lines**,
  comments included, with a short header explaining the doctrine.
- ✅ It parses on tmux 3.8 (this machine) and on tmux 3.2a
  (`docker run --rm ubuntu:22.04`, then `apt install tmux`).
- ✅ Try it live with `tmux -L minimal -f …`. Check that splits, `h/j/k/l`,
  copy then paste into the host OS, and reload all work.

### Phase 4: write `zsh-minimal`, then `zsh-antidote`
- Write `zsh-minimal/.zshrc` first (about 60 lines). Then copy it into
  `zsh-antidote/.zshrc`, add the fenced plugin block (about 25 lines) and
  `zsh-antidote/.zsh_plugins.txt`.
- **Test in containers only.** This host runs shell-config; don't start the
  repo's zsh configs here.
- ✅ `zsh -n` is clean on the host for both files (syntax only).
- ✅ **Basics, for both packages.** In a throwaway container (the Phase 6
  recipe, run early), `zsh -i -c exit` exits 0 with an empty stderr. In an
  interactive shell there:
  - history persists across two shells, in
    `~/.local/state/zsh/history`
  - the completion menu appears on Tab
  - `Esc`/`i` switch vi modes
- ✅ **`zsh-minimal` makes no network calls,** even on first run. Verify with
  `--network none`: no warnings, everything works.
- ✅ **The `zsh-antidote` bootstrap**, one scenario per fresh container:

  | Scenario | How to simulate | Expected |
  |---|---|---|
  | First run, online | default network | antidote and zsh-vi-mode install; `ciw`, visual mode and cursor shape work; **second shell start doesn't touch the network** |
  | First run, offline | `docker run --network none …` | one warning line, then the same behaviour as `zsh-minimal`, exit 0 |
  | GitHub unreachable, DNS working | `--add-host github.com:127.0.0.1` | same as offline: it fails fast |
  | Network hangs | `--add-host github.com:10.255.255.1` (a black-hole IP) | gives up after about 10s, **then** the next shell skips retrying (marker) |
  | Network comes back | first run offline, then run the next shell with network after the marker expires (or delete it) | installs on its own; no stale broken load file |
  | No `git` | image built without git (build arg) | no warning noise, same behaviour as `zsh-minimal` |
  | fzf self-install | default image (has curl) | after the first run, `command -v fzf` points into antidote's fzf clone; `fzf --version` matches the clone's version; Ctrl-R opens fzf **with zsh-vi-mode loaded** (proves the `ZVM_INIT_MODE=sourcing` ordering) |
  | fzf wins over old apt fzf | image also has `apt install fzf` (0.44) | our fzf comes first on `PATH`; Ctrl-R is fzf |
  | No curl, no wget | image built without curl (build arg) | zsh-vi-mode still installs (it only needs git); fzf binary skipped **silently**; no fzf bindings; exit 0 |
  | No curl, old apt fzf | as above, plus `apt install fzf` | no "unknown option" noise; just no fzf bindings |
  | Update | `antidote update`, then the fzf `install --bin` one-liner | plugins and the fzf binary move to the latest versions |

**Built 2026-10-14. Every row above passed**, plus `zsh-minimal` with
apt's fzf 0.44 (24.04) and 0.29 (22.04, zsh 5.8.1), and `zsh-antidote` on
22.04. Versions: antidote 2.3.0, fzf 0.74.5. The scenarios ran with
`test/Dockerfile` (created early) and image variants built with `PKGS`.

Where the build departs from this brief, and why:
1. **`antidote bundle` in a subshell, not `antidote load`.** This is the
   static-file pattern from antidote's own README. Run as a subshell, the
   whole download (antidote plus both plugin clones) sits under one
   `timeout`. `antidote load` is a shell function, so it can't be wrapped.
   The bundle goes to `plugins.zsh.tmp` and is moved into place only on
   success (`antidote bundle` exits 1 if any clone fails). A failed run
   can't leave a stale load file, so **plugin-block step 4 (check the
   plugin loaded, delete the load file) isn't needed.** `antidote` is
   autoloaded from its `functions/` directory, so `antidote update` still
   works.
2. **`timeout 30`, not 10**, because it covers three clones. A black-holed
   GitHub costs the first shell about 30s; the marker then skips retries
   for an hour.
3. **The fzf hook also needs a terminal (`[[ -t 0 ]]`), in both
   packages.** fzf's `--zsh` script saves and restores every option,
   including `zle`, which prints "can't change option: zle" twice in an
   interactive shell without a tty (`zsh -i -c exit`,
   `docker exec box zsh -ic …`). Key bindings are useless there anyway.
4. **Hooks use `if …; fi`, not `&&`.** With `&&`, a missing tool on the
   last line makes `.zshrc` return 1, and `zsh -i -c exit` exits 1.

Also: **brew's `fpath` line was dropped.** Homebrew 7's `shellenv zsh`
already adds `site-functions`; it only has to run before `compinit`. And
`.zshrc` has to look for brew at its standard paths, because unlike under
shell-config, nothing has put brew on `PATH` yet. Sizes: `zsh-minimal`
67 lines; `zsh-antidote` 122 lines (the plugin block is about 55 lines
rather than 25, because the guards above are written out plainly).

### Phase 5: scripts and Brewfile
- `check.sh` first (Phases 2–4 already rely on its logic), then
  `bootstrap.sh`, then `install.sh`, then `Brewfile`. The Brewfile covers
  `tmux-full` and its sesh picker: tmux, stow, git, fzf, fd, zoxide, sesh,
  gitmux, eza. (**`bat` was dropped:** nothing in the repo uses it. The
  picker calls sesh, fzf, fd and zoxide; gitmux feeds the status line; eza
  is for Phase 7's preview.)
- ✅ `shellcheck` is clean on all three scripts. Check `install.sh` with
  `--shell=sh`, because it must not contain bashisms.
- ✅ `install.sh` refuses an existing `DOTFILES_DIR` that isn't a clone of
  this repo. Test it with a throwaway directory.
- ✅ `HOME=$(mktemp -d) ./bootstrap.sh` (no arguments) stows `tmux-full`, the
  default, on the host, and installs its plugins into the temporary `HOME`.
  It must run with the tmux isolation from Phase 2 (`env -u TMUX -u
  TMUX_PANE -u TMUX_PLUGIN_MANAGER_PATH TMUX_TMPDIR=<short dir>`), or it
  talks to the live tmux server.
- ✅ Changing `DEFAULT_PACKAGES` to `tmux-minimal` and re-running the same
  command stows `tmux-minimal` instead. Then change it back.
- ✅ `./bootstrap.sh tmux-full tmux-minimal` is refused with a clear message.
- The `zsh-*` packages are bootstrapped in Phase 6.

**Built 2026-10-14; every check above passed.** Also verified:
- `check.sh` fails (exit 1, with the reason) on a tmux parse error, a zsh
  syntax error and an unstowable package.
- bootstrap backs up a real file in the way, refuses `zsh-*` when
  `~/.zshenv` exists, exits 1 when a variant is already stowed or a tpm
  plugin download fails, and a re-run is a no-op.
- `install.sh` runs nothing from a truncated download (cut at 4 points),
  and without git it prints the hint and exits 1.

shellcheck wasn't on this host, so it ran from `koalaman/shellcheck:stable`
(0.11.0) through a shim on `PATH`, which also exercised `check.sh`'s
shellcheck branch. Sizes: install.sh 58 lines, bootstrap.sh 96, check.sh 74.

### Phase 6: the vanilla-box test (the doctrine's real exam)
Prove the container combinations work on a stock OS.

**Build a test image first.** `--network none` blocks `apt install`, so the
offline scenarios (Phase 4) need the packages already installed. Use one
small `test/Dockerfile` (about 6 lines):
- `ARG UBUNTU=24.04`, then `FROM ubuntu:$UBUNTU`
- `ARG PKGS="zsh tmux stow git curl"`, then `apt install $PKGS`
- `useradd -m -s /bin/zsh tester`, then `USER tester`

This earns its place: it makes the network scenarios repeatable, and it's
a file, not a framework. Build args select `ubuntu:22.04` for tmux 3.2a,
and `PKGS` drops git or curl, or adds apt's `fzf`, for the Phase 4
scenarios. curl is in the default set because a vanilla Ubuntu *install*
has it, even though the bare Docker image doesn't.

Install through **the installer itself**, from the local checkout, so the
one-liner path is tested too:
```sh
docker build -t dotfiles-box test/                       # once (needs network)
docker run --rm -it -v "$PWD":/dotfiles:ro dotfiles-box bash
# inside (as tester):
git config --global --add safe.directory /dotfiles       # mounted repo has a different owner
DOTFILES_REPO_URL=/dotfiles DOTFILES_BRANCH="<branch under test>" \
  sh /dotfiles/install.sh zsh-antidote tmux-minimal      # or: zsh-minimal tmux-minimal
zsh   # no newuser wizard, no errors, prompt and completion work
tmux  # tmux-minimal config loads, status line shows, h/j/k/l work
# offline / unreachable scenarios: add --network none or --add-host to `docker run`
```
The installer clones **committed** work from `DOTFILES_BRANCH`, so commit
(no push needed) before testing. For quick iteration on uncommitted
changes, `cp -r /dotfiles ~/dotfiles && ~/dotfiles/bootstrap.sh …` still
works.
- ✅ Both combinations work on `ubuntu:24.04` and on `ubuntu:22.04` (for
  tmux 3.2a).
- ✅ Switching works in place: `stow -D zsh-minimal && stow zsh-antidote`,
  then a new shell.
- ✅ Both work with **no** optional tools installed (no fzf, zoxide or brew),
  so all the guards hold.
- ✅ Both work with `--network none`: `zsh-minimal` silently,
  `zsh-antidote` with one warning line. The repo comes from the local
  mount, so the installer needs no network either.
- ✅ **Re-running the installer is safe.** A second
  `sh /dotfiles/install.sh …` reuses the clone (`git pull --ff-only`) and
  re-stows without errors.
- ✅ **The real one-liner, once the repo is pushed.** In a fresh **bare**
  `ubuntu:24.04` container, as root for the `apt` step:
  ```sh
  apt update && apt install -y curl git zsh tmux stow
  curl -fsSL https://raw.githubusercontent.com/GrndZero101/dotfiles/main/install.sh | sh -s -- zsh-antidote tmux-minimal
  ```
  ends with a working zsh and tmux. Also run it once **without** git
  installed and confirm it prints a clear "install git" hint, not a stack
  of errors.
- Save the commands as a short "Testing on a fresh box" section in the
  README, not as a script. Promote it to a script only if it's run often.
- **Finish the README** to the structure in Project conventions: the
  one-liner first, alerts used sparingly and for their real purpose,
  `<kbd>` for every binding, one mermaid install-flow diagram, and
  `<details>` for the long reference tables.
- ✅ Preview it on GitHub after pushing, because alerts, mermaid and
  `<details>` only render there. Check that every alert still reads
  correctly in plain-text `cat README.md` too.

### Phase 7: sesh starter config (inside `tmux-full`)
- Small `tmux-full/.config/sesh/sesh.toml`:
  - a `tmux config` session (alias `tc`, opens `nvim tmux.conf`), pointing at
    **the repo** path, not `~/.config/tmux`
  - a `dotfiles` session (alias `df`)
  - a `[[wildcard]]` giving `~/projects/github/*/*` a git icon
  - a `[default_session]` preview of `eza` plus `git status --short`
  - `blacklist = ["^scratch$"]`
- Patterns come from the sesh author's own config
  ([joshmedeski/dotfiles `.config/sesh/`](https://github.com/joshmedeski/dotfiles/tree/main/.config/sesh)).
  Copy only what's used today.
- Optional: `bind L run-shell "sesh last"` in `tmux-full`. It replaces
  tmux's default `L`, and `sesh last` does that job better.
- **Note for shell-config:** the workstation's zoxide hook has to live in the
  active shell-config profile, not here (convention 6). Check that it's
  there; otherwise sesh's directory list never grows.
- ✅ The `prefix + T` picker shows the configured sessions; typing `tc`
  auto-connects.

### Phase 8: cut over on this machine
1. Detach or close tmux sessions you care about, or accept that the running
   server keeps its in-memory config. That's fine: it already references
   `~/.config/tmux/scripts/sesh-picker.sh`, and that path is still valid
   afterwards.
2. `mv ~/.config/tmux ~/.config/tmux.pre-dotfiles`. This archives the old
   repo with its git history and its `plugins/`.
3. `./bootstrap.sh` (the default, `tmux-full`, including sesh config). No `zsh-*`, so shell-config keeps the
   shell.
4. Optionally copy `plugins/` across from the archive instead of
   re-downloading.
5. Restart the tmux server (`tmux kill-server`, then start tmux again) to
   prove a cold start works.
- ✅ Status bar, catppuccin colours, `prefix + T`, `prefix + :` (in-pane),
  and `C-j` inside Claude Code all behave as before.
- ✅ `ls -la ~/.config/tmux` shows `tmux.conf` as a symlink into the repo,
  and `plugins/` as a real directory.

### Phase 9: macOS check, then delete the archive
- Run `./bootstrap.sh` (the default) on a Mac. The tool packages apply
  there whether or not shell-config is in use. The `zsh-*` packages stay
  container-only.
- Note any OS-specific fixes **in the README**, not as OS branches in the
  configs, unless a branch is truly unavoidable.
- Once you're confident: `rm -rf ~/.config/tmux.pre-dotfiles`.

---

## Portability

- **Linux and macOS** are first-class.
  - `tmux-full` assumes Homebrew on both (Linuxbrew is already in
    use here), so there's one package manager and one `Brewfile`.
  - `tmux-minimal`, `zsh-minimal` and `zsh-antidote` need only `zsh`,
    `tmux`, `stow` and `git` from any package manager, plus `curl` or `wget`
    for zsh-antidote's fzf. That's what makes them suitable for containers.
- Watch out for apt's renamed binaries if anything ever stops relying on
  brew: Debian/Ubuntu ship `fd` as `fdfind` and `bat` as `batcat`.
- `scripts/sesh-picker.sh` uses bash arrays and process substitution. Both
  work in macOS's bash 3.2, so no Homebrew bash is needed. The build session
  should confirm this on a Mac.
- **Windows:** WSL counts as Linux and is already the main machine. Native
  Windows has no tmux and no zsh, and stow needs Perl and symlink
  privileges. **Out of scope.** Revisit only if a real need appears.

---

## Decisions

**Open:** none. The build session can start straight away.

**Already decided (2026-10-14):**
- **Stow package names:** `tmux-full`, `tmux-minimal`, `zsh-antidote`,
  `zsh-minimal`. Variants of the same tool are alternatives.
- **sesh config ships inside `tmux-full`** (convention 8), not as its own
  package. It only serves `tmux-full`'s `prefix + T` picker, and this way
  the default `./bootstrap.sh` installs the picker and its sessions
  together. Split it out if sesh is ever wanted without `tmux-full`.
- **tmux-minimal keeps the `C-Space` prefix** (Option A). If you run tmux
  inside tmux (for example local `tmux-full`, then SSH to a server running
  `tmux-minimal`), the outer tmux catches `C-Space`. Press it **twice** to
  reach the inner one (`C-Space C-Space c`); both configs bind `C-Space` to
  `send-prefix`. Nesting is expected to be rare, so one set of muscle memory
  wins over a second prefix (`C-b`).
- **Default:** `bootstrap.sh` with no arguments installs **`tmux-full`**.
  It's set by one `DEFAULT_PACKAGES` line at the top of the script, so it's
  easy to change.
- **No pinning, anywhere: always the latest.** tpm plugins track their
  default branches. antidote, zsh-vi-mode and fzf track theirs. Updates are
  explicit commands (see Everyday use), never automatic at shell or tmux
  startup.
- **GitHub repo:** `GrndZero101/dotfiles`, the same name as the directory.
  It's **public**. There are no secrets, and `check.sh` plus review before
  each push keeps it that way.
- **License: MIT**, the same as shell-config (`Copyright (c) 2026
  GrndZero101`).
  - MIT is short and permissive, and corporate legal teams pre-approve it
    almost everywhere, so cloning the repo into work environments is fine.
  - Having **no license** would be worse: legally it means "all rights
    reserved", which is what blocks corporate use.
  - Public-domain-style licenses (Unlicense, 0BSD) are sometimes *less*
    welcome to legal teams than MIT, and Apache-2.0's patent clauses add
    nothing for config files.
  - The third-party snippets we adapted are also MIT: the sesh README
    binding, catppuccin/fzf's colour mapping and catppuccin/tmux. Keep the
    credit comments that are already in those files.
- **zsh history** goes in XDG state: `${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history`.
- **zsh editing mode** is vi in both packages. `zsh-antidote` uses
  **zsh-vi-mode** through **antidote**, which installs itself, can run
  repeatedly without harm, and works offline. `zsh-minimal` uses plain
  `bindkey -v`.
- **fzf in `zsh-antidote` installs itself** through antidote and fzf's own
  `install --bin`, with the same guards. It needs `curl` or `wget`; without
  them it's silently skipped.
- **The canonical shell-config** is the one actually in use:
  `~/projects/github/GrndZero101/tboss/shell-config` (the `~/.zshenv`
  target and `$ZDOTDIR`). Compare the zsh packages against its `zsh-clean`
  and `zsh-zero`.

---

## Deliberately not now (parking lot)

Each item needs a concrete reason before it moves up:
- **More tool packages:** `nvim`, `git`, `bat`, `gitmux`. For `git`, the WSL
  config points `credential.helper` at a Windows `.exe` that fails with
  "Exec format error" inside WSL, so there's a real bug to fix when that
  package arrives. `git` supports XDG (`~/.config/git/config`), so it would
  follow convention 3.
- **Bootstrap profiles** (named package lists). The "common combinations"
  table in the README covers this until the same list keeps being typed by
  hand (doctrine rule 2).
- **More shells:** bash for boxes without zsh. The `zsh-*` packages assume
  you're willing to `apt install zsh`.
- **More zsh plugins:** for example zsh-autosuggestions or syntax
  highlighting, in `zsh-antidote` only. The mechanism is ready (add a line
  to `.zsh_plugins.txt`), but each plugin needs its own "what does it earn?"
  answer, and the Phase 4 offline tests must still pass.
- **zsh-vi-mode's clipboard integration** (OSC 52 or `clip.exe`): only if
  tmux's OSC 52 turns out to be insufficient.
- **Overlap with shell-config:** sharing anything with it, or having it
  consume this repo's tool packages. Keep the boundary clean first, and
  revisit once both repos are stable.
- **Automation:**
  - CI: GitHub Actions running `check.sh` and the Phase 6 container test on
    Ubuntu and macOS.
  - A pre-commit hook running `check.sh`.
- **Shared bases between variants:** one `base.conf` for both tmux configs,
  or a shared zsh core file. Only worth it if the duplicated lines start
  drifting. Today the overlap is about 20 lines for tmux and 60 for zsh,
  and standalone files are easier to understand.
- **Machine-local overrides:** `source-file -q ~/.config/tmux/local.conf`,
  or `~/.zshrc.local`. Add one when the first machine-specific tweak
  appears.
- **Heavier tools:** chezmoi, Nix/home-manager, secrets management.
- **Repo furniture:** `CHANGELOG.md`, release tags, `CONTRIBUTING.md`,
  `SECURITY.md`, `.editorconfig`. They're standard in tool repos; add each
  one when a real reader or a real need appears. A CI badge arrives
  together with CI.
- **Popup command prompt:** the tmux 3.8 modal-pane prompt experiment works,
  but it's brittle and nobody else uses it. Revisit when floating panes
  settle, which is expected around tmux 3.9.

---

## Handy references

- GNU Stow: `.stowrc` is read from `~` and the current directory. Conflicts
  abort the whole run with no partial changes, and `-n` is a dry run.
- shell-config profiles to align with, from the **canonical** checkout
  (the one in use: the `~/.zshenv` target and `$ZDOTDIR`):
  `~/projects/github/GrndZero101/tboss/shell-config/zsh-clean/.zshrc` and
  `…/zsh-zero/.zshrc`. Ignore the other copy at
  `~/projects/github/GrndZero101/shell-config`.
- tmux 3.7/3.8 changes: `/home/linuxbrew/.linuxbrew/Cellar/tmux/3.8/CHANGES`
- catppuccin prompt bug: [catppuccin/tmux#600](https://github.com/catppuccin/tmux/issues/600),
  [PR #606](https://github.com/catppuccin/tmux/pull/606) (still open).
  Keep the post-tpm `message-style` override until it merges.
- antidote: [README](https://github.com/mattmc3/antidote). Static mode
  rebuilds the load file only when `.zsh_plugins.txt` is newer, or when
  `$ANTIDOTE_HOME/.antidote.load` is missing. Override the location with
  `zstyle ':antidote:static' file …`.
- zsh-vi-mode: [README](https://github.com/jeffreytse/zsh-vi-mode). Needs
  zsh 5.1+. See `ZVM_INIT_MODE=sourcing`, the `zvm_after_init` hooks and
  the cursor-style options.
- fzf: `install --bin` downloads the release binary for the clone's version
  using curl or wget, and never touches rc files.
- sesh: [README](https://github.com/joshmedeski/sesh),
  [author's config](https://github.com/joshmedeski/dotfiles/tree/main/.config/sesh)
- catppuccin fzf colours: [catppuccin/fzf](https://github.com/catppuccin/fzf)
