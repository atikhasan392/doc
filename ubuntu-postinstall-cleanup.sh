#!/usr/bin/env bash

set -u

LOG_FILE="$HOME/ubuntu-postinstall-cleanup.log"
DRY_RUN=false

if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
fi

APT_PACKAGES=(
  gnome-clocks
  gnome-power-manager
  baobab
  gnome-disk-utility
  evince
  gnome-logs
  gnome-characters
  yelp
  firefox
)

SNAP_PACKAGES=(
  firefox
)

USER_PATHS=(
  "$HOME/.mozilla/firefox"
  "$HOME/.cache/mozilla"
  "$HOME/snap/firefox"
)

print_header() {
  echo "============================================================"
  echo "$1"
  echo "============================================================"
}

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

run_cmd() {
  if $DRY_RUN; then
    log "[DRY-RUN] $*"
  else
    eval "$@" >>"$LOG_FILE" 2>&1
  fi
}

require_sudo() {
  if [[ $EUID -eq 0 ]]; then
    log "Do not run this script as root directly. Run as a normal user with sudo access."
    exit 1
  fi

  if ! sudo -v; then
    log "Sudo authentication failed."
    exit 1
  fi
}

package_installed() {
  dpkg -s "$1" &>/dev/null
}

snap_installed() {
  command -v snap &>/dev/null && snap list "$1" &>/dev/null
}

purge_apt_package() {
  local pkg="$1"

  if package_installed "$pkg"; then
    log "Purging APT package: $pkg"
    run_cmd "sudo apt-get purge -y $pkg" || log "Warning: Failed to purge $pkg"
  else
    log "APT package not installed, skipping: $pkg"
  fi
}

remove_snap_package() {
  local pkg="$1"

  if snap_installed "$pkg"; then
    log "Removing Snap package: $pkg"
    run_cmd "sudo snap remove $pkg" || log "Warning: Failed to remove snap $pkg"
  else
    log "Snap package not installed, skipping: $pkg"
  fi
}

remove_user_path() {
  local path="$1"

  if [[ -e "$path" ]]; then
    log "Removing user data: $path"
    if $DRY_RUN; then
      log "[DRY-RUN] rm -rf $path"
    else
      rm -rf "$path" || log "Warning: Failed to remove $path"
    fi
  else
    log "User data path not found, skipping: $path"
  fi
}

cleanup_system() {
  log "Running autoremove"
  run_cmd "sudo apt-get autoremove -y" || log "Warning: autoremove failed"

  log "Running autoclean"
  run_cmd "sudo apt-get autoclean -y" || log "Warning: autoclean failed"
}

main() {
  print_header "Ubuntu Post-Install Cleanup Script"
  log "Script started"

  require_sudo

  log "Refreshing package lists"
  run_cmd "sudo apt-get update" || log "Warning: apt update failed"

  print_header "Removing Snap packages"
  for pkg in "${SNAP_PACKAGES[@]}"; do
    remove_snap_package "$pkg"
  done

  print_header "Purging APT packages"
  for pkg in "${APT_PACKAGES[@]}"; do
    purge_apt_package "$pkg"
  done

  print_header "Removing user-level leftovers"
  for path in "${USER_PATHS[@]}"; do
    remove_user_path "$path"
  done

  print_header "Final cleanup"
  cleanup_system

  log "Cleanup completed"
  print_header "Done"
  echo "Log file saved to: $LOG_FILE"
}

main "$@"
