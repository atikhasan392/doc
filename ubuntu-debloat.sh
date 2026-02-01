#!/usr/bin/env bash
set -euo pipefail

YES=1

LOG_DIR="/var/log/ubuntu-debloat"
LOG_FILE="$LOG_DIR/debloat-$(date +%F-%H%M%S).log"

need_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "Run as root"
    exit 1
  fi
}

log_setup() {
  mkdir -p "$LOG_DIR"
  touch "$LOG_FILE"
  exec > >(tee -a "$LOG_FILE") 2>&1
}

clear_stale_locks() {
  if pgrep -x dpkg >/dev/null 2>&1 || pgrep -x apt >/dev/null 2>&1; then
    return 0
  fi
  rm -f /var/lib/dpkg/lock-frontend
  rm -f /var/lib/dpkg/lock
  rm -f /var/cache/apt/archives/lock
  rm -f /var/lib/apt/lists/lock
  dpkg --configure -a || true
}

apt_purge() {
  apt-get purge -y "$@" || true
}

main() {
  need_root
  log_setup

  apt-get update -y

  # Core bloat
  apt_purge     aisleriot gnome-mahjongg gnome-mines gnome-sudoku     cheese rhythmbox totem shotwell simple-scan     thunderbird transmission-gtk remmina     gnome-contacts gnome-weather gnome-maps     gnome-clocks gnome-calendar yelp gnome-tour     ubuntu-docs gnome-user-docs deja-dup     whoopsie apport popularity-contest modemmanager

  # Office
  apt-get purge -y 'libreoffice*' || true

  # Document viewers
  apt_purge evince evince-common atril xreader okular poppler-utils

  # Image viewers
  apt_purge eog eog-plugins gthumb ristretto imagemagick

  # Language support and input methods
  apt-get purge -y     language-selector-common     language-selector-gnome     ibus ibus-gtk ibus-gtk3 ibus-table     fcitx fcitx-frontend-gtk2 fcitx-frontend-gtk3     fcitx-module-dbus fcitx-module-kimpanel || true

  apt-get purge -y 'language-pack-*' 'language-pack-gnome-*' 'myspell-*' 'hunspell-*' || true

  # Characters (GNOME Characters)
  apt_purge gnome-characters

  # Passwords and Keys
  apt_purge seahorse gnome-keyring gnome-keyring-pkcs11 gnome-keyring-secrets

  # Snap
  if command -v snap >/dev/null 2>&1; then
    snap list | awk 'NR>1 {print $1}' | while read -r s; do
      snap remove --purge "$s" || true
    done
  fi
  apt-get purge -y snapd || true
  rm -rf /snap /var/snap /var/lib/snapd /home/*/snap || true

  # Flatpak and software center
  apt-get purge -y flatpak gnome-software packagekit || true
  rm -rf /var/lib/flatpak || true

  # Tracker
  systemctl --user mask tracker-miner-fs-3.service tracker-extract-3.service tracker-miner-rss-3.service 2>/dev/null || true
  tracker3 reset --hard 2>/dev/null || true

  # Cleanup
  rm -rf /var/cache/apt/archives/* || true
  rm -rf /var/lib/apt/lists/* || true
  mkdir -p /var/lib/apt/lists/partial

  journalctl --vacuum-time=7d || true

  rm -rf /tmp/* /var/tmp/* || true
  rm -rf /home/*/.cache/* || true

  apt-get autoremove --purge -y || true
  apt-get autoclean -y || true
  apt-get clean -y || true

  clear_stale_locks

  echo "DONE. REBOOT RECOMMENDED."
}

main
