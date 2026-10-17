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

## Parked

Not now: each needs a concrete reason before it moves up.

- **A shared base for `tmux-full` and `tmux-raidboss`.** 45 of tmux-full's
  47 command lines are also in raidboss. Build one the first time a fix
  lands in one and not the other. (The zsh pair shares about 60 lines and
  hasn't drifted.)
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
