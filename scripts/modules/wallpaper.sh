#!/usr/bin/env bash
set -euo pipefail

workshop_save_wallpaper() {
  local current
  current=$(osascript 2>/dev/null -e '
    tell application "System Events"
      get picture of current desktop
    end tell
  ' || echo "")
  echo "$current" > /tmp/workshop-original-wallpaper.txt
}

workshop_set_wallpaper() {
  local path_or_preset="$1"

  if [[ "$path_or_preset" == "black" ]]; then
    path_or_preset="/System/Library/Desktop Pictures/Solid Colors/Black.png"
  fi

  osascript 2>/dev/null -e "
    tell application \"System Events\"
      set picture of every desktop to \"$path_or_preset\"
    end tell
  " || true
}

workshop_restore_wallpaper() {
  if [[ -f /tmp/workshop-original-wallpaper.txt ]]; then
    local saved
    saved=$(cat /tmp/workshop-original-wallpaper.txt)
    if [[ -n "$saved" ]]; then
      workshop_set_wallpaper "$saved"
    fi
  fi
}
