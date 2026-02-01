#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=0
YES=0

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    -y|--yes) YES=1 ;;
    *) ;;
  esac
done

run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "[dry-run] $*"
  else
    eval "$@"
  fi
}

is_installed_apt() {
  dpkg -s "$1" >/dev/null 2>&1
}

is_installed_snap() {
  command -v snap >/dev/null 2>&1 || return 1
  snap list "$1" >/dev/null 2>&1
}

echo "Ubuntu cleanup (conservative)"
echo "Dry-run: $DRY_RUN | Auto-yes: $YES"
echo

if [ "$YES" -ne 1 ] && [ "$DRY_RUN" -ne 1 ]; then
  echo "This will remove selected apps. Continue? (y/N)"
  read -r ans
  if [[ "${ans:-N}" != "y" && "${ans:-N}" != "Y" ]]; then
    echo "Aborted."
    exit 0
  fi
fi

APT_REMOVE=()
SNAP_REMOVE=()

# Clocks
APT_REMOVE+=(gnome-clocks)

# Characters
APT_REMOVE+=(gnome-characters)

# Help / Docs
APT_REMOVE+=(yelp gnome-user-docs ubuntu-docs gnome-getting-started-docs)

# Document viewer
APT_REMOVE+=(evince)

# App Center / Software (varies by Ubuntu release)
APT_REMOVE+=(ubuntu-software gnome-software)
SNAP_REMOVE+=(snap-store)

# LibreOffice
APT_REMOVE+=(libreoffice*)

# Firefox (snap or apt transitional)
APT_REMOVE+=(firefox)
SNAP_REMOVE+=(firefox)

echo "Updating package lists..."
run "sudo apt-get update -y"

echo
echo "Purging selected APT packages (only if installed)..."
TO_PURGE=()
for pkg in "${APT_REMOVE[@]}"; do
  if [[ "$pkg" == *"*"* ]]; then
    TO_PURGE+=("$pkg")
  else
    if is_installed_apt "$pkg"; then
      TO_PURGE+=("$pkg")
    fi
  fi
done

if [ "${#TO_PURGE[@]}" -gt 0 ]; then
  run "sudo apt-get purge -y ${TO_PURGE[*]}"
fi

echo
echo "Removing selected Snap packages (only if installed)..."
for spkg in "${SNAP_REMOVE[@]}"; do
  if is_installed_snap "$spkg"; then
    run "sudo snap remove --purge $spkg"
  fi
done

echo
echo "Autoremoving unused dependencies..."
run "sudo apt-get autoremove --purge -y"

echo
echo "Cleaning apt cache..."
run "sudo apt-get clean"

echo
echo "Done."
echo "Tip: reboot recommended."
