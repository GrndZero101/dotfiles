# zsh-minimal: a comfortable native zsh for fresh boxes and containers.
# No plugins, no downloads. zsh-antidote/.zshrc is this file plus one fenced
# plugin block: keep the shared parts of the two files in step.
# Not for shell-config machines: there ~/.zshenv sets ZDOTDIR, so zsh never
# reads this file.

# Homebrew isn't on PATH in a fresh shell. Its shellenv also puts brew's
# completions on fpath, so it must run before compinit
for brew in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
  if [[ -x $brew ]]; then
    eval "$($brew shellenv zsh)"
    break
  fi
done
unset brew
# Nested shells would otherwise prepend brew's dirs again
typeset -U path fpath

zsh_state=${XDG_STATE_HOME:-$HOME/.local/state}/zsh
zsh_cache=${XDG_CACHE_HOME:-$HOME/.cache}/zsh
mkdir -p $zsh_state $zsh_cache

setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT EXTENDED_GLOB
setopt INTERACTIVE_COMMENTS NO_BEEP NO_FLOW_CONTROL

# Vanilla zsh keeps no history at all without HISTFILE
HISTFILE=$zsh_state/history
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY HIST_FCNTL_LOCK HIST_IGNORE_ALL_DUPS HIST_SAVE_NO_DUPS
setopt HIST_FIND_NO_DUPS HIST_EXPIRE_DUPS_FIRST HIST_IGNORE_SPACE HIST_REDUCE_BLANKS

# Completion menu; case-insensitive, and `f-b<Tab>` completes foo-bar
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' 'r:|[._-]=* r:|=*'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
autoload -Uz compinit
compinit -d $zsh_cache/zcompdump

# Vi mode, plus the emacs keys that muscle memory still reaches for
bindkey -v
KEYTIMEOUT=1
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line
bindkey '^P' up-line-or-search
bindkey '^N' down-line-or-search
bindkey '^R' history-incremental-search-backward
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line

# user@host:path, with a yellow host over SSH so a remote box stands out
PROMPT='%F{blue}%n@%m%f:%F{green}%~%f %# '
[[ -n $SSH_CONNECTION ]] && PROMPT=${PROMPT/blue/yellow}

autoload -Uz add-zsh-hook
set_title() { print -Pn '\e]0;%n@%m: %~\a' }
add-zsh-hook precmd set_title
mkcd() { mkdir -p -- "$1" && builtin cd -- "$1" }

# Tool hooks, each only if the tool exists (`if`, not `&&`, so a missing tool
# doesn't make .zshrc return non-zero). zoxide feeds sesh's directory list.
# fzf needs 0.48+ for --zsh; an older fzf errors, so it gets silenced and
# simply means no fzf key bindings. fzf's script also prints "can't change
# option: zle" when there's no terminal (`docker exec box zsh -ic …`), where
# key bindings are useless anyway
if (( $+commands[zoxide] )); then eval "$(zoxide init zsh)"; fi
if (( $+commands[fzf] )) && [[ -t 0 ]]; then source <(fzf --zsh 2>/dev/null); fi
