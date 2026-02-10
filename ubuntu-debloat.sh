#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

run() { echo "+ $*"; eval "$@"; }

is_installed_apt() {
  dpkg -s "$1" >/dev/null 2>&1
}

is_installed_snap() {
  command -v snap >/dev/null 2>&1 || return 1
  snap list "$1" >/dev/null 2>&1
}

echo "=== Ubuntu Safe Debloat (fixed, auto-yes) ==="

sudo -v
run "sudo apt-get update -y"

APT_CANDIDATES=(
  gnome-clocks
  gnome-characters
  aisleriot
  gnome-mines
  gnome-sudoku
  gnome-mahjongg
  cheese
  shotwell
  rhythmbox
  totem
  transmission-gtk
  yelp
  ubuntu-docs
  gnome-user-docs
  gnome-getting-started-docs
  evince
)

# LibreOffice packages vary; handle separately via dpkg query
LIBREOFFICE_PKGS=()

while read -r pkg; do
  LIBREOFFICE_PKGS+=("$pkg")
done < <(dpkg-query -W -f='${Package}\n' 2>/dev/null | grep -E '^libreoffice' || true)

TO_PURGE=()
for p in "${APT_CANDIDATES[@]}"; do
  if is_installed_apt "$p"; then
    TO_PURGE+=("$p")
  fi
done

for p in "${LIBREOFFICE_PKGS[@]}"; do
  if is_installed_apt "$p"; then
    TO_PURGE+=("$p")
  fi
done

echo
echo "APT packages to purge: ${#TO_PURGE[@]}"
if [ "${#TO_PURGE[@]}" -gt 0 ]; then
  run "sudo apt-get purge -y ${TO_PURGE[*]}"
else
  echo "Nothing to purge via APT."
fi

echo
echo "Removing unused dependencies..."
run "sudo apt-get autoremove --purge -y"

echo
echo "Cleaning apt cache..."
run "sudo apt-get clean"

echo
echo "Cleaning systemd journal logs (keep 7 days)..."
run "sudo journalctl --vacuum-time=7d || true"

echo
echo "Cleaning old crash reports..."
run "sudo rm -rf /var/crash/* || true"

echo
echo "Cleaning thumbnail cache..."
run "rm -rf \"$HOME/.cache/thumbnails/\"* 2>/dev/null || true"

echo
echo "Cleaning safe user caches..."
run "rm -rf \"$HOME/.cache/fontconfig/\"* 2>/dev/null || true"
run "rm -rf \"$HOME/.cache/mozilla/firefox/\"*/cache2 2>/dev/null || true"
run "rm -rf \"$HOME/.cache/google-chrome\" 2>/dev/null || true"
run "rm -rf \"$HOME/.cache/chromium\" 2>/dev/null || true"

echo
echo "Cleaning trash & recent files list..."
run "rm -rf \"$HOME/.local/share/Trash/\"* 2>/dev/null || true"
run "rm -f \"$HOME/.local/share/recently-used.xbel\" 2>/dev/null || true"

echo
echo "Disabling apport (crash reporting)..."
run "sudo systemctl disable apport.service >/dev/null 2>&1 || true"
run "sudo sed -i 's/enabled=1/enabled=0/' /etc/default/apport 2>/dev/null || true"

# Optional snap removals (safe defaults off): snap-store, firefox
echo
echo "Checking optional Snap apps..."
for s in snap-store firefox; do
  if is_installed_snap "$s"; then
    echo "Snap installed: $s (not removing by default)"
  fi
done

echo
echo "Syncing filesystem..."
run "sync"

echo
echo "=== Done. Log out/in or reboot to refresh app menu. ==="