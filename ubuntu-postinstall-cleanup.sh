#!/usr/bin/env bash

set -e

echo "Removing unnecessary Ubuntu packages..."

sudo apt-get update

sudo snap remove firefox 2>/dev/null || true

sudo apt-get purge -y \
  gnome-clocks \
  gnome-power-manager \
  baobab \
  gnome-disk-utility \
  evince \
  gnome-logs \
  gnome-characters \
  yelp \
  firefox || true

rm -rf "$HOME/.mozilla/firefox"
rm -rf "$HOME/.cache/mozilla"
rm -rf "$HOME/snap/firefox"

sudo apt-get autoremove -y
sudo apt-get autoclean -y

echo "Cleanup completed successfully."
