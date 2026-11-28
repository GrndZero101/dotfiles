# Everything tmux-full and git use, on Linux (Linuxbrew) and macOS:
#   brew bundle --file Brewfile
# Only tmux, stow and git are required; without the rest, the sesh picker
# (prefix + T) or the git status segment stop working, but tmux still runs.
brew "tmux"   # 3.8+: tmux-full uses command-prompt -P
brew "stow"
brew "git"    # latest: the git package's settings assume it (zdiff3)
brew "git-delta" # the git package's pager; plain less without it
brew "sesh"   # session manager behind the prefix + T picker
brew "fzf"    # the picker's UI
brew "fd"     # the picker's directory search
brew "zoxide" # the picker's frequent directories
brew "gitmux" # git status in the status line
brew "fswatch" # refreshes it when a file in the repo changes
brew "eza"    # directory preview in sesh's default session
