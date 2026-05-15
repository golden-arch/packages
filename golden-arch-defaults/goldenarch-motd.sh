#!/usr/bin/env bash
# Golden Arch — dynamic terminal greeting
# /etc/profile.d/goldenarch-motd.sh

# Interactive shells only
[[ $- != *i* ]] && return

# ── ANSI palette (actual escape chars) ────────────────────────────────────────
G=$'\e[38;5;178m'    # gold  (#e8b341 approx)
DG=$'\e[38;5;136m'   # dark gold
W=$'\e[0;97m'        # white
D=$'\e[2m'           # dim
B=$'\e[1m'           # bold
GN=$'\e[38;5;107m'   # green
RD=$'\e[38;5;167m'   # red
R=$'\e[0m'           # reset

# ── helpers ───────────────────────────────────────────────────────────────────
_cpu() {
  grep -m1 'model name' /proc/cpuinfo \
    | cut -d: -f2 \
    | sed 's/^[[:space:]]*//; s/(R)//g; s/(TM)//g; s/  */ /g; s/[[:space:]]*$//'
}

_gpu() {
  local g
  g=$(lspci 2>/dev/null \
      | grep -iE 'VGA compatible|3D controller|Display controller' \
      | head -1 \
      | sed 's/.*: //; s/ (rev [0-9a-fA-F]*)//i')
  echo "${g:-n/a}"
}

_bat() {
  local path pct status
  path=$(find /sys/class/power_supply -maxdepth 1 -name 'BAT*' 2>/dev/null | head -1)
  [[ -z "$path" ]] && return 1
  pct=$(cat "$path/capacity" 2>/dev/null)
  status=$(cat "$path/status" 2>/dev/null)
  case "$status" in
    Charging) printf '%s⚡ %s%% (charging)%s'         "$GN" "$pct" "$R" ;;
    Full)     printf '%s● %s%% (full)%s'              "$GN" "$pct" "$R" ;;
    *)
      if [[ "$pct" =~ ^[0-9]+$ ]] && (( pct <= 20 )); then
        printf '%s▼ %s%% (%s)%s' "$RD" "$pct" "${status,,}" "$R"
      else
        printf '%s%% (%s)' "$pct" "${status,,}"
      fi
      ;;
  esac
}

_disk() {
  local mnt="${1:-/}"
  df -h "$mnt" 2>/dev/null | awk -v mnt="$mnt" \
    'NR==2{printf "%s used / %s total  (%s)", $3, $2, $5}'
}

_storage_extra() {
  # Show /home if on a separate partition
  local home_dev root_dev
  root_dev=$(df / | awk 'NR==2{print $1}')
  home_dev=$(df /home 2>/dev/null | awk 'NR==2{print $1}')
  [[ "$home_dev" != "$root_dev" ]] && \
    printf '%s' "$(df -h /home | awk 'NR==2{printf "%s used / %s total  (%s)", $3, $2, $5}')"
}

# ── gather ────────────────────────────────────────────────────────────────────
kernel=$(uname -r)
host=$(hostname)
cpu=$(_cpu)
gpu=$(_gpu)
mem_total=$(awk '/MemTotal/{printf "%.0f",   $2/1024}' /proc/meminfo)
mem_avail=$(awk '/MemAvailable/{printf "%.0f", $2/1024}' /proc/meminfo)
mem_used=$(( mem_total - mem_avail ))
root_disk=$(_disk /)
home_disk=$(_storage_extra)
pkgs=$(pacman -Qq 2>/dev/null | wc -l)
flatpaks=$(flatpak list --app 2>/dev/null | wc -l)
uptime_str=$(uptime -p | sed 's/up //')
ip=$(ip -4 addr show scope global 2>/dev/null \
     | awk '/inet/{print $2}' | head -1 | cut -d/ -f1)
[[ -z "$ip" ]] && ip="offline"
shell_name=$(basename "$SHELL")
bat=$(_bat)

# ── arch art — pre-padded to 16 visual columns ────────────────────────────────
art=(
  "        ▄       "
  "      ▄███▄     "
  "     █████▄     "
  "    ██████▄     "
  "   ███████▄     "
  "  ████████      "
  " █████████      "
  " █████████      "
  "████████████    "
  "                "
  "                "
  "                "
  "                "
  "                "
  "                "
)

# label: gold text left-padded 9 cols (ASCII only, so %-9s is safe) + white value
_row() { printf '%s%-9s%s%s%s' "$G" "$1" "$R" "$W" "$2"; printf '%s' "$R"; }

# ── info lines ────────────────────────────────────────────────────────────────
info=(
  "${B}Golden Arch${R}  ${D}·  rolling${R}"
  "${D}──────────────────────────────────────${R}"
  "$(_row host    "$host")"
  "$(_row kernel  "$kernel")"
  "$(_row shell   "$shell_name")"
  "$(_row cpu     "$cpu")"
  "$(_row gpu     "$gpu")"
  "$(_row memory  "${mem_used} MiB / ${mem_total} MiB")"
  "$(_row root    "$root_disk")"
)
[[ -n "$home_disk" ]] && info+=("$(_row home "$home_disk")")
info+=(
  "$(_row pkgs    "${pkgs} pacman$([ "$flatpaks" -gt 0 ] && echo "  ·  ${flatpaks} flatpak")")"
  "$(_row network "$ip")"
  "$(_row uptime  "$uptime_str")"
)
[[ -n "$bat" ]] && info+=("${G}$(printf '%-9s' battery)${R}${bat}")

# ── print ─────────────────────────────────────────────────────────────────────
printf '\n'
n=$(( ${#art[@]} > ${#info[@]} ? ${#art[@]} : ${#info[@]} ))
for (( i = 0; i < n; i++ )); do
  printf '%s%s%s  %s\n' "$G" "${art[$i]:-                }" "$R" "${info[$i]:-}"
done
printf '\n'
