# zsh-antidote: zsh-minimal plus zsh-vi-mode and fzf, installed by antidote.
# This is zsh-minimal/.zshrc plus the fenced plugin block below: keep the
# shared parts of the two files in step.
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

# ---- plugin block (the only part not in zsh-minimal) -----------------------
# The first shell downloads the plugins; after that, startup is one `source`
# with no network. Offline, or without git, it behaves like zsh-minimal.
# Bind keys while sourcing, not at the first prompt, so the bindings below
# (ours and fzf's) aren't overwritten by zsh-vi-mode
ZVM_INIT_MODE=sourcing
antidote_dir=${XDG_DATA_HOME:-$HOME/.local/share}/antidote
plugins_zsh=$zsh_cache/plugins.zsh
plugins_failed=$zsh_state/plugins-failed
# One timeout around all downloads, so a black-holed network can't hang the
# shell, and no retry within an hour of a failure, so offline boxes don't
# pay that timeout in every new shell
net=()
(( $+commands[timeout] )) && net=(timeout 30)
recent_failure=( $plugins_failed(Nmm-60) )

# Build the load file when it's missing or older than the plugin list, in a
# subshell so the timeout covers it. It's written to .tmp and moved only on
# success, so a failed run never leaves a broken load file behind
if [[ ! $plugins_zsh -nt ~/.zsh_plugins.txt ]] && (( $+commands[git] && ! $#recent_failure )); then
  print -nu2 'zshrc: installing plugins... '
  if GIT_TERMINAL_PROMPT=0 $net zsh -fc '
      [[ -f $1/antidote.zsh ]] || { rm -rf $1 && git clone -q --depth=1 https://github.com/mattmc3/antidote $1 } &&
      source $1/antidote.zsh && antidote bundle <~/.zsh_plugins.txt >|$2.tmp' _ $antidote_dir $plugins_zsh 2>/dev/null
  then
    mv -f $plugins_zsh.tmp $plugins_zsh && print -u2 done
  else
    rm -f $plugins_zsh.tmp; : >| $plugins_failed
    print -u2 'failed; using built-ins, retrying in an hour'
  fi
fi
[[ -r $plugins_zsh ]] && source $plugins_zsh
# Makes `antidote update` work, loading antidote only when it's first used
fpath+=($antidote_dir/functions)
autoload -Uz antidote

# fzf's own installer fetches the release binary for the cloned version. It
# only runs while the binary is missing, and needs curl or wget
fzf_bin=${path[(r)*/junegunn/fzf/bin]}
if [[ -n $fzf_bin && ! -x $fzf_bin/fzf ]] && (( ($+commands[curl] || $+commands[wget]) && ! $#recent_failure )); then
  print -nu2 'zshrc: installing fzf... '
  if $net $fzf_bin:h/install --bin >/dev/null 2>&1; then
    rehash; print -u2 done
  else
    : >| $plugins_failed
    print -u2 'failed; retrying in an hour'
  fi
fi
unset antidote_dir plugins_zsh plugins_failed net recent_failure fzf_bin

# Plain vi mode if zsh-vi-mode didn't load, exactly as in zsh-minimal
if (( ! $+functions[zvm_init] )); then
  bindkey -v
  KEYTIMEOUT=1
fi
# ---- end of plugin block ----------------------------------------------------

# The emacs keys that muscle memory still reaches for
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
