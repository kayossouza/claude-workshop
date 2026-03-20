#!/usr/bin/env bash
set -euo pipefail

workshop_play_music() {
  local app="${1:-none}"
  local track_uri="${2:-}"

  case "$app" in
    Spotify)
      osascript 2>/dev/null -e "tell application \"Spotify\" to play track \"$track_uri\"" || true
      ;;
    "Apple Music")
      osascript 2>/dev/null -e "tell application \"Music\" to play track \"$track_uri\"" || true
      ;;
    none|"")
      return 0
      ;;
  esac
}

workshop_set_volume() {
  local app="${1:-none}"
  local volume="${2:-50}"

  case "$app" in
    Spotify)
      osascript 2>/dev/null -e "tell application \"Spotify\" to set sound volume to $volume" || true
      ;;
    "Apple Music")
      osascript 2>/dev/null -e "tell application \"Music\" to set sound volume to $volume" || true
      ;;
    none|"")
      return 0
      ;;
  esac
}
