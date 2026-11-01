#!/bin/sh
# gitmon.sh socket [seconds]: gitmux for the status line, run when something
# changes instead of on every redraw. Its status line shows each session's
# @gitmux, which this sets. Events, none of which start a process:
#   - a tmux control client (tmux -C) subscribed to the path and command of
#     the pane each attached client is looking at: cd, switching panes or
#     sessions, and a command starting or finishing (git commit, vim)
#   - fswatch, one per repo on screen, if installed: edited, new and deleted
#     files, and .git itself (staging, commits, fetches). Changes are
#     batched over [seconds] (default 5), so a build churning files costs
#     at most one gitmux a batch. Without fswatch it's once a minute.
# Each refresh runs gitmux once (about 5 processes, its git calls).
# tmux keeps a #() job per client, so a second copy waits on standby and
# takes over if the first one's client goes. tmux stops the job with
# SIGTERM; the control client, awk and the fswatches go with it.
set -eu
sock=$1
latency=${2:-5}
dir=$sock.gitmon # next to the socket: one per server, and private
owner="" ctl="" mon=""
echo # tmux shows "<... not ready>" until a job prints something

# Exiting would make tmux re-run the job on every redraw, so wait instead
command -v gitmux >/dev/null 2>&1 || exec sleep 86400

cleanup() {
  trap - EXIT
  [ -n "$owner" ] || return 0
  for f in "$dir"/watch.*; do
    [ -s "$f" ] && read -r p <"$f" && kill "$p" 2>/dev/null || :
  done
  kill "$ctl" "$mon" 2>/dev/null || :
  rm -rf "$dir"
}
trap cleanup EXIT
trap 'exit 0' HUP INT TERM

# One owner per server: mkdir is atomic. A standby blocks reading the
# owner's "alive" FIFO, which ends when the owner (and every process that
# inherited it) has gone. A lock whose owner died without cleanup is stale.
until mkdir "$dir" 2>/dev/null; do
  if read -r p <"$dir/pid" 2>/dev/null && kill -0 "$p" 2>/dev/null; then
    read -r _ <"$dir/alive" || :
  else
    rm -rf "$dir"
  fi
done
owner=1
echo $$ >"$dir/pid" # first, so a standby never sees a lock without it
mkfifo "$dir/alive" "$dir/ev" "$dir/cmd"
exec 9<>"$dir/alive"

fswatch=""
if command -v fswatch >/dev/null 2>&1; then fswatch=fswatch; fi
flags=""
case $(awk -W version 2>&1 </dev/null) in
  mawk*) flags="-W interactive" ;; # see sysmon.sh
esac

# Each end opens the FIFO it writes first, so the two opens pair up
tmux -S "$sock" -C attach -f ignore-size,no-output <"$dir/cmd" >"$dir/ev" 2>/dev/null &
ctl=$!
# shellcheck disable=SC2086 # a word list, split on purpose
awk $flags -v dir="$dir" -v fswatch="$fswatch" -v latency="$latency" '
# Quoted for sh and tmux alike: a quote inside closes, escapes, reopens
function q(s) { gsub(/\047/, "\047\\\047\047", s); return "\047" s "\047" }
# The repo holding a path: the nearest parent with .git/HEAD, or a .git
# file (worktrees, submodules). Reading files starts no processes
function root(d, line) {
  while (d != "") {
    if ((getline line < (d "/.git/HEAD")) > 0) { close(d "/.git/HEAD"); return d }
    close(d "/.git/HEAD")
    if ((getline line < (d "/.git")) > 0 && line ~ /^gitdir: /) { close(d "/.git"); return d }
    close(d "/.git")
    sub(/\/[^\/]*$/, "", d)
  }
  return ""
}
function watch(r, f) {
  if (fswatch == "" || r in wpid) return
  f = dir "/watch." ++nw; wfile[r] = f
  system("fswatch -r -l " latency " --batch-marker=gitmon-batch " q(r) \
    " >>" q(dir "/ev") " 2>/dev/null & echo $! >" q(f))
  getline wpid[r] < f; close(f)
}
function unwatch(r) {
  system("kill " wpid[r] " 2>/dev/null")
  printf "" > wfile[r]; close(wfile[r]) # so cleanup skips it
  delete wpid[r]; delete wfile[r]
}
# gitmux once for a repo, then @gitmux for each session showing it, if
# it changed. GIT_OPTIONAL_LOCKS=0 stops git status rewriting .git/index,
# which fswatch would report, which would refresh again, forever
function refresh(r, cmd, out, line, s) {
  out = ""
  if (r != "") {
    cmd = "GIT_OPTIONAL_LOCKS=0 gitmux -cfg \"$HOME/.gitmux.conf\" " q(r)
    while ((cmd | getline line) > 0) out = out line
    close(cmd)
  }
  for (s in repo) if (repo[s] == r && !(s in shown && shown[s] == out)) {
    print "set -t " q(s) " @gitmux " q(out); shown[s] = out
  }
  fflush()
}
BEGIN {
  # Per attached client (not this one): session id, pane path and
  # command, tab-separated, records ended by \036
  print "refresh-client -B " q("gitmon::#{L:#{?client_control_mode,,#{S:#{?#{==:#{session_name},#{client_session}},#{session_id}\t#{pane_current_path}\t#{pane_current_command}\036,}}}}")
  # Without fswatch, a clock: tmux checks subscriptions every second, and
  # this one changes every minute. (A bare % would start a tmux directive.)
  if (fswatch == "") print "set -g @gitmon_clock " q("%M") "\nrefresh-client -B " q("gitmon_clock::#{T:@gitmon_clock}")
  fflush()
}
/^%exit/ { exit }
/^%subscription-changed gitmon / {
  n = split(substr($0, index($0, " : ") + 3), recs, "\036")
  delete now; delete need
  for (i = 1; i < n; i++) {
    split(recs[i], f, "\t"); s = f[1]; now[s] = 1
    if (seen[s] != f[2] "\t" f[3]) { seen[s] = f[2] "\t" f[3]; repo[s] = root(f[2]); stale[repo[s]] = 1 }
  }
  for (s in repo) if (!(s in now)) { delete repo[s]; delete seen[s]; delete shown[s] }
  for (s in repo) if (repo[s] != "") need[repo[s]] = 1
  for (r in wpid) if (!(r in need)) unwatch(r)
  for (r in need) watch(r)
  for (r in stale) refresh(r)
  delete stale; next
}
/^%subscription-changed gitmon_clock / { for (r in need) refresh(r); next }
# fswatch: changed paths, then a marker when the batch ends
/^\// { for (r in wpid) if (index($0, r "/") == 1) stale[r] = 1; next }
$0 == "gitmon-batch" { for (r in stale) refresh(r); delete stale }
' >"$dir/cmd" <"$dir/ev" &
mon=$!
wait "$mon" || :
