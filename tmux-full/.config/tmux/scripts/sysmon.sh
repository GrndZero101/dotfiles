#!/bin/sh
# sysmon.sh [seconds]: cpu, ram, disk usage, disk and network throughput
# for the status line, as one line every few seconds:
#   cpu%|ram%|disk%|disk read|disk write|net down|net up
# tmux runs it once as a #() job that never exits and shows its latest line,
# and the config splits that line into pills. One sampler that streams
# (vmstat on Linux, top on macOS) is the clock, and everything else is read
# from files, so a tick starts no processes; only df, once a minute, does.
# tmux stops the job with SIGTERM to this shell; awk and the sampler then
# exit at their next write, when the pipe to tmux is gone.
set -eu
interval=${1:-5}
cd "$HOME" # df -P . then reports the filesystem holding ~ (on macOS, Data)

case $(uname) in
  Linux) sampler="vmstat -n $interval" ;;
  Darwin) sampler="top -l 0 -s $interval -n 0" ;;
  *) sampler="" ;;
esac
if [ -z "$sampler" ] || ! command -v "${sampler%% *}" >/dev/null 2>&1; then
  # A "?" pill says what's missing without an error in the status line, and
  # waiting instead of exiting stops tmux re-running the job every refresh
  echo '?|?|?|?|?|?|?'
  exec sleep 86400
fi

# Whole disks only. Partitions, device-mapper and md devices repeat I/O
# their disks already count; loop, ram, zram and optical drives are noise
disks=" "
for d in /sys/block/*; do
  case ${d##*/} in
    loop* | ram* | zram* | dm-* | md* | sr* | \*) ;;
    *) disks="$disks${d##*/} " ;;
  esac
done

# mawk (Debian and Ubuntu's awk) reads a pipe in blocks, so it would sit on
# the sampler's lines; -W interactive makes it take each line as it comes.
# Other awks reject or warn about the flag
flags=""
case $(awk -W version 2>&1 </dev/null) in
  mawk*) flags="-W interactive" ;;
esac

# shellcheck disable=SC2086 # both are word lists, split on purpose
$sampler | awk $flags -v iv="$interval" -v disks="$disks" '
# Bytes per second as 1024-based units, like free -h and htop
function human(b, i, u) {
  split("B K M G T", u); i = 1
  while (b >= 1024 && i < 5) { b /= 1024; i++ }
  return sprintf((i == 1 || b >= 10) ? "%.0f%s" : "%.1f%s", b, u[i])
}
# top prints sizes like 15G or 222M
function bytes(s, n) {
  n = s + 0
  if (s ~ /K/) n *= 1024; else if (s ~ /M/) n *= 1048576
  else if (s ~ /G/) n *= 1073741824; else if (s ~ /T/) n *= 1099511627776
  return n
}
# Usage of the filesystem holding ~, as df prints it (63%)
function disk_usage(cmd, line, f) {
  cmd = "df -P ."
  cmd | getline line; cmd | getline line; close(cmd)
  split(line, f, " "); return f[5]
}
function linux_tick(line, f, nf, t, a, rd, wr, rx, tx, out) {
  while ((getline line < "/proc/meminfo") > 0) {
    split(line, f, " ")
    if (f[1] == "MemTotal:") t = f[2]; else if (f[1] == "MemAvailable:") a = f[2]
  }
  close("/proc/meminfo")
  ram = t ? sprintf("%d%%", 100 * (t - a) / t + 0.5) : "?"
  # diskstats sectors are always 512 bytes
  while ((getline line < "/proc/diskstats") > 0) {
    split(line, f, " ")
    if (index(disks, " " f[3] " ")) { rd += f[6] * 512; wr += f[10] * 512 }
  }
  close("/proc/diskstats")
  # Virtual interfaces (containers, bridges) carry traffic the real
  # interface also counts
  while ((getline line < "/proc/net/dev") > 0) {
    if (line !~ /:/) continue
    sub(/^ +/, "", line); split(line, nf, ":"); split(nf[2], f, " ")
    if (nf[1] !~ /^(lo|veth|docker|br-|virbr|cni|flannel)/) { rx += f[1]; tx += f[9] }
  }
  close("/proc/net/dev")
  # The first tick has nothing to compare with
  out = seen ? human((rd - prd) / iv) "|" human((wr - pwr) / iv) "|" \
    human((rx - prx) / iv) "|" human((tx - ptx) / iv) : "-|-|-|-"
  prd = rd; pwr = wr; prx = rx; ptx = tx; seen = 1
  return out
}
function report() {
  if (tick++ % every == 0) disk = disk_usage()
  print cpu "|" ram "|" disk "|" io; fflush()
}
BEGIN { every = int(60 / iv); if (every < 1) every = 1 }
# vmstat: find the idle column in the header; the first data line
# averages since boot, the rest cover one interval each
$1 == "r" && $2 == "b" { for (i = 1; i <= NF; i++) if ($i == "id") idcol = i; next }
idcol && $1 ~ /^[0-9]+$/ { cpu = sprintf("%d%%", 100 - $idcol); io = linux_tick(); report() }
# top: "CPU usage: 6.6% user, 10.0% sys, 83.3% idle"
/^CPU usage:/ { for (i = 2; i <= NF; i++) if ($i ~ /^idle/) cpu = sprintf("%d%%", 100 - $(i - 1) + 0.5) }
# top: "PhysMem: 15G used (2489M wired, ...), 222M unused."
/^PhysMem:/ {
  u = bytes($2); for (i = 2; i <= NF; i++) if ($i ~ /^unused/) free = bytes($(i - 1))
  ram = u + free ? sprintf("%d%%", 100 * u / (u + free) + 0.5) : "?"; io = "|||"; report()
}'
