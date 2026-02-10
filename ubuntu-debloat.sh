#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

echo "=== Ubuntu Safe Debloat (Auto-Yes) ==="

# Ensure sudo session (will ask password once if needed)
sudo -v

echo
echo "Step 1) Purging safe preinstalled apps (NOT removing Text Editor / Fonts / Image Viewer)..."

sudo apt-get update -y

sudo apt-get purge -y \
  gnome-clocks \
  gnome-characters \
  aisleriot \
  gnome-mines \
  gnome-sudoku \
  gnome-mahjongg \
  cheese \
  shotwell \
  rhythmbox \
  totem \
  transmission-gtk \
  yelp \
  ubuntu-docs \
  gnome-user-docs \
  gnome-getting-started-docs \
  libreoffice* || true

echo
echo "Step 2) Removing unused dependencies..."
sudo apt-get autoremove --purge -y

echo
echo "Step 3) Cleaning apt cache..."
sudo apt-get clean

echo
echo "Step 4) Cleaning system logs (journalctl: keep last 7 days)..."
sudo journalctl --vacuum-time=7d || true

echo
echo "Step 5) Cleaning old crash reports..."
sudo rm -rf /var/crash/* || true

echo
echo "Step 6) Cleaning thumbnail cache..."
rm -rf "$HOME/.cache/thumbnails/"* 2>/dev/null || true

echo
echo "Step 7) Cleaning safe user caches..."
rm -rf "$HOME/.cache/fontconfig/"* 2>/dev/null || true
rm -rf "$HOME/.cache/mozilla/firefox/"*/cache2 2>/dev/null || true
rm -rf "$HOME/.cache/google-chrome" 2>/dev/null || true
rm -rf "$HOME/.cache/chromium" 2>/dev/null || true

echo
echo "Step 8) Cleaning trash & recent files list..."
rm -rf "$HOME/.local/share/Trash/"* 2>/dev/null || true
rm -f "$HOME/.local/share/recently-used.xbel" 2>/dev/null || true

echo
echo "Step 9) Disabling apport (crash reporting service)..."
sudo systemctl disable apport.service >/dev/null 2>&1 || true
sudo sed -i 's/enabled=1/enabled=0/' /etc/default/apport 2>/dev/null || true

echo
echo "Syncing filesystem..."
sync

echo
echo "=== Done. Reboot recommended. ==="