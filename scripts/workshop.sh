#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Workshop Mode — Main Orchestrator
# Arranges your development environment like Tony Stark's workshop.
# ============================================================================

WORKSHOP_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- Parse arguments --------------------------------------------------------
DRY_RUN=false
DETECT_ONLY=false
CONFIG_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)     DRY_RUN=true; shift ;;
    --detect-only) DETECT_ONLY=true; shift ;;
    --config)      CONFIG_FILE="$2"; shift 2 ;;
    *)             echo "Unknown option: $1"; exit 1 ;;
  esac
done

# --- Load and merge config --------------------------------------------------
CONFIG="$(python3 -c "
import json, sys
def deep_merge(base, override):
    for k, v in override.items():
        if k in base and isinstance(base[k], dict) and isinstance(v, dict):
            deep_merge(base[k], v)
        else:
            base[k] = v
    return base
defaults = json.load(open(sys.argv[1]))
try:
    user = json.load(open(sys.argv[2]))
    print(json.dumps(deep_merge(defaults, user)))
except (FileNotFoundError, json.JSONDecodeError):
    print(json.dumps(defaults))
" "$WORKSHOP_DIR/defaults.json" "${CONFIG_FILE:-$HOME/.claude/workshop.json}")"

# Helper to read config values: cfg <dotted.key> <default>
cfg() {
  echo "$CONFIG" | python3 -c "
import json, sys, functools
data = json.load(sys.stdin)
keys = sys.argv[1].split('.')
val = functools.reduce(lambda d, k: d[k] if isinstance(d, dict) else d, keys, data)
if isinstance(val, bool):
    print('true' if val else 'false')
elif isinstance(val, (dict, list)):
    print(json.dumps(val))
else:
    print(val)
" "$1" 2>/dev/null || echo "${2:-}"
}

# --- Source all modules ------------------------------------------------------
for module in "$WORKSHOP_DIR"/modules/*.sh; do
  # shellcheck source=/dev/null
  source "$module"
done

# --- Step 1: Kill previous instances ----------------------------------------
pkill -f "workshop-briefing" 2>/dev/null || true
pkill -f "edge-tts.*workshop" 2>/dev/null || true

# --- Step 2: Startup sounds -------------------------------------------------
if [ "$(cfg features.startup_sound true)" = "true" ]; then
  afplay /System/Library/Sounds/Glass.aiff &
  sleep 0.3
  afplay /System/Library/Sounds/Glass.aiff &
  sleep 0.3
  afplay /System/Library/Sounds/Hero.aiff &
fi

# --- Step 3: Greeting via speak_script --------------------------------------
GREETING="$(cfg features.greeting "")"
SPEAK_SCRIPT="$(cfg features.jarvis.speak_script "")"
SPEAK_SCRIPT="${SPEAK_SCRIPT/#\~/$HOME}"
if [ -n "$GREETING" ] && [ -n "$SPEAK_SCRIPT" ] && [ -f "$SPEAK_SCRIPT" ]; then
  bash "$SPEAK_SCRIPT" "$GREETING" &
fi

# --- Step 4: Focus mode -----------------------------------------------------
if [ "$(cfg features.focus_mode true)" = "true" ]; then
  workshop_enable_focus
fi

# --- Step 4b: Disable Stage Manager (required for side-by-side apps) --------
workshop_disable_stage_manager

# --- Step 5: Wallpaper ------------------------------------------------------
WALLPAPER="$(cfg features.wallpaper "black")"
if [ "$WALLPAPER" != "none" ]; then
  workshop_save_wallpaper
  workshop_set_wallpaper "$WALLPAPER"
fi

# --- Step 6: Music ----------------------------------------------------------
MUSIC_APP="$(cfg music.app "Spotify")"
if [ "$MUSIC_APP" != "none" ]; then
  MUSIC_TRACK="$(cfg music.track "")"
  workshop_play_music "$MUSIC_APP" "$MUSIC_TRACK" &
fi

# --- Step 7: Docker check ---------------------------------------------------
if [ "$(cfg features.docker_check.enabled false)" = "true" ]; then
  DOCKER_PATTERN="$(cfg features.docker_check.grep_pattern "")"
  DOCKER_DIR="$(cfg features.docker_check.dir "")"
  DOCKER_DIR="${DOCKER_DIR/#\~/$HOME}"
  DOCKER_CMD="$(cfg features.docker_check.cmd "")"
  if [ -n "$DOCKER_PATTERN" ]; then
    (
      if ! docker ps --format '{{.Names}}' 2>/dev/null | grep -q "$DOCKER_PATTERN"; then
        if [ -n "$DOCKER_DIR" ] && [ -n "$DOCKER_CMD" ]; then
          cd "$DOCKER_DIR" && eval "$DOCKER_CMD" 2>/dev/null || true
        fi
      fi
    ) &
  fi
fi

# --- Step 8: Detect screens -------------------------------------------------
SCREENS="$(osascript -l JavaScript "$WORKSHOP_DIR/detect-screens.js")"

# --- Step 9: Detect-only mode -----------------------------------------------
if [ "$DETECT_ONLY" = true ]; then
  echo "$SCREENS" | python3 -m json.tool
  exit 0
fi

# --- Step 10: Get terminal count --------------------------------------------
CONFIG_TERM_COUNT="$(cfg terminals.count 0)"
if [ "$CONFIG_TERM_COUNT" -gt 0 ] 2>/dev/null; then
  TERM_COUNT="$CONFIG_TERM_COUNT"
else
  TERM_COUNT="$(workshop_count_terminals)"
  [ "$TERM_COUNT" -eq 0 ] && TERM_COUNT=1
fi

# --- Step 11: Ensure terminals ----------------------------------------------
workshop_ensure_terminals "$TERM_COUNT"
sleep 0.3

# --- Step 12: Calculate layout ----------------------------------------------
LAYOUT="$(echo "$SCREENS" | python3 "$WORKSHOP_DIR/calculate-layout.py" \
  --config <(echo "$CONFIG") --terminal-count "$TERM_COUNT")"

# --- Step 13: Dry-run mode --------------------------------------------------
if [ "$DRY_RUN" = true ]; then
  echo "=== Screens ==="
  echo "$SCREENS" | python3 -m json.tool
  echo ""
  echo "=== Layout (${TERM_COUNT} terminals) ==="
  echo "$LAYOUT" | python3 -m json.tool
  exit 0
fi

# --- Step 14: Build dynamic app list from config ---------------------------
APP_NAMES="Terminal"
APP_LIST=$(echo "$CONFIG" | python3 -c "
import json, sys
config = json.load(sys.stdin)
apps = config.get('apps', {})
for key, entry in apps.items():
    print(entry.get('app', key))
")
while IFS= read -r app; do
  [ -n "$app" ] && APP_NAMES="$APP_NAMES $app"
done <<< "$APP_LIST"

# --- Step 15: Unminimize all app windows ------------------------------------
workshop_unminimize "$APP_NAMES"
sleep 0.5

# --- Step 16: Apply terminal themes + position (single pass) ----------------
THEMES="$(cfg terminals.themes "[]")"
PROFILE="$(cfg terminals.profile "Homebrew")"
osascript 2>/dev/null -e 'tell application "Terminal" to activate' || true
sleep 0.5
workshop_apply_themes_and_position "$THEMES" "$PROFILE" "$LAYOUT"
sleep 0.3

# --- Step 17: Position non-terminal apps from layout ------------------------
echo "$LAYOUT" | python3 -c "
import sys, json
layout = json.load(sys.stdin)
for k, a in layout.get('apps', {}).items():
    print(a['app'], a['x'], a['y'], a['w'], a['h'])
" | while IFS= read -r line; do
  read -r app_name x y w h <<< "$line"
  workshop_position_window "$app_name" "$x" "$y" "$w" "$h"
done

# --- Step 18: Open browser URLs (if browser app is configured) --------------
BROWSER_APP="$(cfg apps.browser.app "")"
BROWSER_URLS="$(cfg apps.browser.urls "[]")"
if [ -n "$BROWSER_APP" ] && [ "$BROWSER_URLS" != "[]" ]; then
  osascript 2>/dev/null -e "
    tell application \"$BROWSER_APP\"
      activate
      if (count of windows) = 0 then make new window
    end tell
  " || true

  echo "$BROWSER_URLS" | python3 -c "
import json, sys
for url in json.load(sys.stdin): print(url)
" | while IFS= read -r url; do
    osascript 2>/dev/null -e "
      tell application \"$BROWSER_APP\"
        set tabURLs to {}
        repeat with t in tabs of window 1
          set end of tabURLs to URL of t
        end repeat
        if tabURLs does not contain \"$url\" then
          if URL of active tab of window 1 starts with \"about:\" then
            set URL of active tab of window 1 to \"$url\"
          else
            make new tab at end of tabs of window 1 with properties {URL:\"$url\"}
          end if
        end if
      end tell
    " || true
  done
fi

# --- Step 19: Raise all windows (AXRaise for precision) --------------------
workshop_raise_all "$TERM_COUNT" "$APP_NAMES"

# --- Step 20: Send notification ---------------------------------------------
NOTIF_TITLE="$(cfg features.notification.title "Workshop Mode")"
NOTIF_SUBTITLE="$(cfg features.notification.subtitle "All systems online")"
workshop_notify "$NOTIF_TITLE" "$NOTIF_SUBTITLE" "$APP_NAMES arranged."

echo "Workshop online. ${TERM_COUNT} terminals + ${APP_NAMES} arranged."

# --- Step 20: Start JARVIS briefing in background ---------------------------
if [ "$(cfg features.jarvis.enabled false)" = "true" ]; then
  JARVIS_CONFIG="$(cfg features.jarvis "{}")"
  # Add music_app to jarvis config for volume ducking
  JARVIS_CONFIG="$(echo "$JARVIS_CONFIG" | python3 -c "
import json, sys
c = json.load(sys.stdin)
c['music_app'] = '$MUSIC_APP'
print(json.dumps(c))
")"

  workshop_start_jarvis "$JARVIS_CONFIG"

  (
    sleep 6
    workshop_run_briefing "$JARVIS_CONFIG" "$SPEAK_SCRIPT"
    workshop_set_volume "$MUSIC_APP" "$(cfg music.volume_normal 100)"
  ) &
  disown
fi
