# TODO

Open work, newest last. Tick an item when it's done and verified; delete
it once the result is recorded where it belongs (README, CLAUDE.md, or a
comment in the config).

## macOS check

Moved from `PLAN.md` Phase 9 on 2026-10-17. Everything below was built
and tested on Linux (WSL) only.

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

### Status modules, in `tmux-full` and then `tmux-raidboss`

Switch with `./bootstrap.sh tmux-raidboss`, or by hand:
`tmux kill-server && stow -D tmux-full && stow tmux-raidboss`, then start
tmux and press <kbd>C-Space</kbd> <kbd>I</kbd>.

- [ ] **Disk usage (both):** `df -P ~` should report the Data volume
  (`/System/Volumes/Data`), not the read-only system volume at `/`.
- [ ] **Clock (both):** `%Z` prints a zone name, or an offset for zones
  without one.
- [ ] **Battery (raidboss):** on a MacBook the pill appears
  (`pmset -g batt` lists `InternalBattery`); on a desktop Mac it's left out.
- [ ] **Disk IO and net (raidboss):** left out, since there's no `/proc`.
  Decide whether a macOS version (`iostat`, `netstat -ib`) earns its place
  in `hud-io.sh`.
- [ ] **GPU (raidboss):** left out without `nvidia-smi`. Apple silicon has
  no cheap GPU-load command, so leaving it out is probably right.
- [ ] **Load and uptime (raidboss):** catppuccin parses `uptime` output,
  which differs between macOS and Linux.
- [ ] **Weather, kube and pomodoro (raidboss)** behave as on Linux.

## This machine

- [ ] **Delete the pre-dotfiles archive** once you trust the cut-over
  (`PLAN.md` Phase 8). It holds the old `~/.config/tmux` repo and plugins:
  ```sh
  rm -rf ~/.config/tmux.pre-dotfiles
  ```
