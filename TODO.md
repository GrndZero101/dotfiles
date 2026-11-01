# TODO

Open work first, then parked ideas. Tick an item when it's done and
verified; delete it once the result is recorded where it belongs (README,
CLAUDE.md, or a comment in the config).

## macOS check

Carried over from the build plan's last phase (2026-10-17). Everything
below was built and tested on Linux (WSL) only.

- [ ] **Install on a Mac.** The tool packages apply there whether or not
  shell-config is in use; the `zsh-*` packages stay container-only.

  ```sh
  git clone https://github.com/GrndZero101/dotfiles ~/.config/dotfiles
  cd ~/.config/dotfiles
  ./bootstrap.sh                 # tmux-full, plus its plugins
  # or by hand: stow tmux-full, start tmux, press C-Space I
  ```

- [ ] **Record OS-specific fixes in the README**, not as OS branches in the
  configs, unless a branch is truly unavoidable.
- [ ] **`sesh-picker.sh` under macOS's bash 3.2.** It uses arrays and
  process substitution, which should work without Homebrew bash.

### Status modules, in the four tpm variants

Switch with `./bootstrap.sh tmux-raidboss`, or by hand:
`tmux kill-server && stow -D tmux-full && stow tmux-raidboss`, then start
tmux and press <kbd>C-Space</kbd> <kbd>I</kbd>.

- [ ] **`sysmon.sh` (all four):** `top -l 0 -s 5 -n 0` must hand awk each
  sample as it comes through the pipe, and its `CPU usage:` and `PhysMem:`
  lines must parse. The cpu and ram pills show `?` if `top` is missing.
- [ ] **Disk usage (all but quiet):** sysmon's `df -P .` from `~` should
  report the Data volume (`/System/Volumes/Data`), not the read-only
  system volume at `/`.
- [ ] **Clock (all four):** `%Z` prints a zone name, or an offset for zones
  without one.
- [ ] **Battery (raidboss):** on a MacBook the pill appears
  (`pmset -g batt` lists `InternalBattery`); on a desktop Mac it's left out.
- [x] **Disk IO, IOPS and net (all but quiet):** `sysmon.sh` reads them
  from the `top` it already runs (`-d`, per-sample counts); checked with a
  2 GB write and a 100 MB download (2026-11-01). Network includes lo0.
- [ ] **GPU (raidboss):** left out without `nvidia-smi`. Apple silicon has
  no cheap GPU-load command, so leaving it out is probably right.
- [ ] **Load and uptime (raidboss):** catppuccin parses `uptime` output,
  which differs between macOS and Linux.
- [ ] **Weather, kube and pomodoro (raidboss)** behave as on Linux.

## Upstream

- [ ] **Report the tmux-nerd-font-window-name regression.** Since #68
  (2026-08-20) the plugin names windows with a bash job per window, about
  once a second while a pane has output, though its `CONTRIBUTING.md` still
  says configs without regex sections get the plain format. Our configs
  build that format with its `generate-tmux-format` after tpm; drop the
  override once upstream does it again.

## Parked

Not now: each needs a concrete reason before it moves up.

- **A shared base for `tmux-full`, `tmux-raidboss`, `tmux-compact` and
  `tmux-quiet`.** 45 of tmux-full's 47 command lines are also in raidboss,
  quiet is tmux-full minus four modules, and compact is tmux-full with
  other throughput fields, an IOPS pill and the status line on top. Build
  one the first time a fix lands in one and not the others. (The zsh pair
  shares about 60 lines and hasn't drifted.)
- **A tmux variant without the system pills** (cpu, ram, disk, IO, net),
  keeping everything else, for when even one long-running job is too much.
- **raidboss's other HUD jobs** (load, uptime, battery, weather, kube,
  pomodoro) still start about 300 processes a minute, all re-run each
  refresh. Fine for a box that's over the top on purpose; move them to
  long-running jobs if that changes.
- **CI:** GitHub Actions running `./check.sh` and the container test
  (README, Testing on a fresh box) on Ubuntu and macOS. A CI badge comes
  with it.
- **More tool packages:** `nvim`, `git`, `bat`. For `git`, this machine's
  config points `credential.helper` at a Windows `.exe` that fails with
  "Exec format error" inside WSL: a real bug to fix when it arrives. It
  would use `~/.config/git/config` (XDG).
- **More zsh plugins** (autosuggestions, syntax highlighting), in
  `zsh-antidote` only. One line in `.zsh_plugins.txt` each, but each needs
  its own "what does it earn?" and must pass the offline container tests.
- **Machine-local overrides:** `source-file -q ~/.config/tmux/local.conf`
  or `~/.zshrc.local`, when the first machine-specific tweak appears.
- **gitleaks** in the hooks, if `detect-private-key` and the pre-push
  review stop being enough.
- **Popup command prompt:** tmux 3.8's modal-pane prompt works but is
  brittle and nobody else uses it. Revisit when floating panes settle,
  expected around tmux 3.9.
