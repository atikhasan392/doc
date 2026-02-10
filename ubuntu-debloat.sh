#!/usr/bin/env bash
set -euo pipefail

echo "=== Ubuntu Safe Debloat Started ==="

echo
echo "Removing safe preinstalled apps..."

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
  libreoffice*

echo
echo "Removing unused dependencies..."
sudo apt-get autoremove --purge -y

echo
echo "Cleaning apt cache..."
sudo apt-get clean

echo
echo "Cleaning systemd journal logs..."
sudo journalctl --vacuum-time=7d

echo
echo "Cleaning old crash reports..."
sudo rm -rf /var/crash/*

echo
echo "Cleaning thumbnail cache..."
rm -rf ~/.cache/thumbnails/*

echo
echo "Cleaning user cache (safe)..."
rm -rf ~/.cache/fontconfig/*
rm -rf ~/.cache/mozilla/firefox/*/cache2 2>/dev/null || true
rm -rf ~/.cache/google-chrome 2>/dev/null || true
rm -rf ~/.cache/chromium 2>/dev/null || true

echo
echo "Removing orphan config directories (safe)..."
rm -rf ~/.local/share/Trash/*
rm -rf ~/.local/share/recently-used.xbel

echo
echo "Disabling apport (crash reporting)..."
sudo systemctl disable apport.service >/dev/null 2>&1 || true
sudo sed -i 's/enabled=1/enabled=0/' /etc/default/apport || true

echo
echo "Syncing filesystem..."
sync

echo
echo "=== Ubuntu Safe Debloat Completed ==="
echo "Reboot recommended."