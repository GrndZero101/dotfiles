#!/bin/sh
# sysmon.sh [seconds] [fields]: system stats for the status line, one line
# every few seconds of named fields:
#   |cpu=12%|ram=45%|disk=63%           cpu, ram, disk usage of ~
#   |disk_r=0B|disk_w=24K|disk_t=24K    disk bytes/s: read, write, total
#   |iops_r=0|iops_w=3|iops_t=3         disk operations/s, the same
#   |net_d=1.2K|net_u=340B|net_t=1.5K   network bytes/s: down, up, total
# tmux runs it as a #() job that never exits and shows its latest line;
# each pill takes one field by name. A sampler that streams (vmstat on
# Linux, top on macOS) is the clock and the rest is read from files, so a
# tick starts no processes; only df, once a minute, does. fields is a comma
# list of cpu, ram, disk, io, iops, net (default: all). cpu and ram come
# with the sampler; leaving out the others skips their df or reads and
# leaves their fields empty. tmux stops the job with SIGTERM to this
# shell; awk and the sampler exit at their next write.
set -eu
interval=${1:-5}
fields=${2:-cpu,ram,disk,io,iops,net}
cd "$HOME" # df -P . then reports the filesystem holding ~ (on macOS, Data)

# A "?" pill says something is wrong without an error in the status line,
# and waiting instead of exiting stops tmux re-running the job every refresh
broken() {
  echo '|cpu=?|ram=?|disk=?|disk_r=?|disk_w=?|disk_t=?|iops_r=?|iops_w=?|iops_t=?|net_d=?|net_u=?|net_t=?'
  exec sleep 86400
}

want=" "
IFS=,
for f in $fields; do
  case $f in
    cpu | ram | disk | io | iops | net) want="$want$f " ;;
    *) broken ;; # a typo in the config
  esac
done
unset IFS

case $(uname) in
  Linux) sampler="vmstat -n $interval" ;;
  Darwin) sampler="top -l 0 -s $interval -n 0" ;;
  *) sampler="" ;;
esac
if [ -z "$sampler" ] || ! command -v "${sampler%% *}" >/dev/null 2>&1; then
  broken
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

# mawk (Debian and Ubuntu's awk) reads a pipe in blocks, sitting on the
# sampler's lines; -W interactive fixes that. Other awks reject the flag
flags=""
case $(awk -W version 2>&1 </dev/null) in
  mawk*) flags="-W interactive" ;;
esac

# shellcheck disable=SC2086 # both are word lists, split on purpose
$sampler | awk $flags -v iv="$interval" -v disks="$disks" -v want="$want" '
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
# A counter per second: empty if not wanted, "-" on the first tick, which
# has nothing to compare with
function rate(wanted, now, prev, inbytes, r) {
  if (!wanted) return ""
  if (!seen) return "-"
  r = (now - prev) / iv
  return inbytes ? human(r) : sprintf("%.0f", r)
}
function linux_tick(line, f, nf, t, a, rd, wr, ro, wo, rx, tx) {
  while ((getline line < "/proc/meminfo") > 0) {
    split(line, f, " ")
    if (f[1] == "MemTotal:") t = f[2]; else if (f[1] == "MemAvailable:") a = f[2]
  }
  close("/proc/meminfo")
  ram = t ? sprintf("%d%%", 100 * (t - a) / t + 0.5) : "?"
  # Reads and writes completed, and sectors, which are always 512 bytes
  while ((wio || wiops) && (getline line < "/proc/diskstats") > 0) {
    split(line, f, " ")
    if (index(disks, " " f[3] " ")) { ro += f[4]; rd += f[6] * 512; wo += f[8]; wr += f[10] * 512 }
  }
  close("/proc/diskstats")
  # Virtual interfaces (containers, bridges) carry traffic the real
  # interface also counts
  while (wnet && (getline line < "/proc/net/dev") > 0) {
    if (line !~ /:/) continue
    sub(/^ +/, "", line); split(line, nf, ":"); split(nf[2], f, " ")
    if (nf[1] !~ /^(lo|veth|docker|br-|virbr|cni|flannel)/) { rx += f[1]; tx += f[9] }
  }
  close("/proc/net/dev")
  dr = rate(wio, rd, prd, 1); dw = rate(wio, wr, pwr, 1); dt = rate(wio, rd + wr, prd + pwr, 1)
  ir = rate(wiops, ro, pro); iw = rate(wiops, wo, pwo); it = rate(wiops, ro + wo, pro + pwo)
  nd = rate(wnet, rx, prx, 1); nu = rate(wnet, tx, ptx, 1); nt = rate(wnet, rx + tx, prx + ptx, 1)
  prd = rd; pwr = wr; pro = ro; pwo = wo; prx = rx; ptx = tx; seen = 1
}
function report() {
  if (wdisk && tick++ % every == 0) disk = disk_usage()
  print "|cpu=" cpu "|ram=" ram "|disk=" disk "|disk_r=" dr "|disk_w=" dw "|disk_t=" dt \
    "|iops_r=" ir "|iops_w=" iw "|iops_t=" it "|net_d=" nd "|net_u=" nu "|net_t=" nt
  fflush()
}
BEGIN {
  every = int(60 / iv); if (every < 1) every = 1
  wdisk = index(want, " disk "); wio = index(want, " io "); wnet = index(want, " net ")
  wiops = index(want, " iops ")
}
# vmstat: find the idle column in the header; the first data line
# averages since boot, the rest cover one interval each
$1 == "r" && $2 == "b" { for (i = 1; i <= NF; i++) if ($i == "id") idcol = i; next }
idcol && $1 ~ /^[0-9]+$/ { cpu = sprintf("%d%%", 100 - $idcol); linux_tick(); report() }
# top: "CPU usage: 6.6% user, 10.0% sys, 83.3% idle"
/^CPU usage:/ { for (i = 2; i <= NF; i++) if ($i ~ /^idle/) cpu = sprintf("%d%%", 100 - $(i - 1) + 0.5) }
# top: "PhysMem: 15G used (2489M wired, ...), 222M unused."
/^PhysMem:/ {
  u = bytes($2); for (i = 2; i <= NF; i++) if ($i ~ /^unused/) free = bytes($(i - 1))
  ram = u + free ? sprintf("%d%%", 100 * u / (u + free) + 0.5) : "?"; report()
}'
