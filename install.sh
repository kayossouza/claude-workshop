#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Claude Workshop Mode — Interactive Installer
# ============================================================================

SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="$HOME/.claude/scripts/workshop"
COMMANDS_DIR="$HOME/.claude/commands"
CONFIG_FILE="$HOME/.claude/workshop.json"
SETTINGS_FILE="$HOME/.claude/settings.json"

echo ""
echo "  Workshop Mode — Setup"
echo "  ====================="
echo ""
echo "  Transform your Mac into a dev workshop with a voice trigger."
echo "  Terminals auto-arrange, music plays, apps snap into place."
echo ""

# --- Interactive config questions -------------------------------------------

# Trigger phrase
read -rp "  Trigger phrase [i'm home baby]: " TRIGGER
TRIGGER="${TRIGGER:-i\'m home baby}"

# Music
echo ""
echo "  Music player:"
echo "    1) Spotify (default)"
echo "    2) Apple Music"
echo "    3) None"
read -rp "  Choice [1]: " MUSIC_CHOICE
case "${MUSIC_CHOICE:-1}" in
  2) MUSIC_APP="Apple Music" ;;
  3) MUSIC_APP="none" ;;
  *) MUSIC_APP="Spotify" ;;
esac

MUSIC_TRACK=""
if [ "$MUSIC_APP" = "Spotify" ]; then
  echo ""
  echo "  Paste a Spotify link or URI (or press Enter for AC/DC - Back in Black):"
  read -rp "  > " MUSIC_INPUT
  if [ -n "$MUSIC_INPUT" ]; then
    # Convert Spotify URL to URI if needed
    if echo "$MUSIC_INPUT" | grep -q "open.spotify.com/track/"; then
      TRACK_ID=$(echo "$MUSIC_INPUT" | sed 's/.*track\///' | sed 's/[?].*//')
      MUSIC_TRACK="spotify:track:$TRACK_ID"
    else
      MUSIC_TRACK="$MUSIC_INPUT"
    fi
  else
    MUSIC_TRACK="spotify:track:08mG3Y1vljYA6bvDt4Wqkj"
  fi
elif [ "$MUSIC_APP" = "Apple Music" ]; then
  echo ""
  read -rp "  Song name or Apple Music URI (or Enter to skip): " MUSIC_TRACK
fi

# Terminal count
echo ""
echo "  How many terminal windows? (0 = use however many are open)"
read -rp "  Count [0]: " TERM_COUNT
TERM_COUNT="${TERM_COUNT:-0}"

# Apps
echo ""
echo "  Which apps to arrange on your MacBook screen?"

read -rp "  Arrange Slack? [Y/n]: " USE_SLACK
USE_SLACK="${USE_SLACK:-y}"

read -rp "  Arrange Spotify on MacBook? [Y/n]: " USE_SPOTIFY_MAC
USE_SPOTIFY_MAC="${USE_SPOTIFY_MAC:-y}"

# Greeting
echo ""
read -rp "  Startup greeting (or Enter for default): " GREETING
GREETING="${GREETING:-Welcome back! Initializing workshop mode.}"

echo ""
echo "  Installing..."
echo ""

# --- Create directories -----------------------------------------------------
mkdir -p "$INSTALL_DIR/modules"
mkdir -p "$COMMANDS_DIR"

# --- Copy scripts -----------------------------------------------------------
cp -R "$SOURCE_DIR/scripts/"* "$INSTALL_DIR/"
echo "  Scripts    -> $INSTALL_DIR/"

# --- Copy slash commands ----------------------------------------------------
for cmd in "$SOURCE_DIR"/commands/*.md; do
  [ -f "$cmd" ] && cp "$cmd" "$COMMANDS_DIR/"
done
echo "  Commands   -> $COMMANDS_DIR/"

# --- Make all scripts executable --------------------------------------------
find "$INSTALL_DIR" -name "*.sh" -exec chmod +x {} \;
chmod +x "$INSTALL_DIR/detect-screens.js" 2>/dev/null || true

# --- Generate user config from answers -------------------------------------
if [ ! -f "$CONFIG_FILE" ]; then
  python3 -c "
import json, sys, re

trigger = sys.argv[1]
music_app = sys.argv[2]
music_track = sys.argv[3]
term_count = int(sys.argv[4])
use_slack = sys.argv[5].lower().startswith('y')
use_spotify_mac = sys.argv[6].lower().startswith('y')
greeting = sys.argv[7]

# Build trigger regex from phrase
# Escape special regex chars, make flexible
phrase = trigger.lower().strip()
# Simple: wrap in a loose regex
trigger_regex = re.escape(phrase).replace(r\"\ \", r\".?\")

config = {}

if trigger_regex != r\"i.?\'m.?home.?baby\":
    config['trigger'] = trigger_regex

if music_app != 'Spotify' or music_track != 'spotify:track:08mG3Y1vljYA6bvDt4Wqkj':
    config['music'] = {}
    if music_app != 'Spotify':
        config['music']['app'] = music_app
    if music_track and music_track != 'spotify:track:08mG3Y1vljYA6bvDt4Wqkj':
        config['music']['track'] = music_track

if term_count > 0:
    config['terminals'] = {'count': term_count}

apps = {}
if use_slack:
    apps['chat'] = {'app': 'Slack', 'screen': 'primary', 'position': 'left', 'width_pct': 50}
if use_spotify_mac and music_app == 'Spotify':
    apps['music_player'] = {'app': 'Spotify', 'screen': 'primary', 'position': 'right', 'width_pct': 50}

if apps:
    config['apps'] = apps

if greeting != 'Welcome back! Initializing workshop mode.':
    config.setdefault('features', {})['greeting'] = greeting

# Only write non-default values
if config:
    print(json.dumps(config, indent=2))
else:
    print('{}')
" "$TRIGGER" "$MUSIC_APP" "$MUSIC_TRACK" "$TERM_COUNT" "$USE_SLACK" "$USE_SPOTIFY_MAC" "$GREETING" > "$CONFIG_FILE"
  echo "  Config     -> $CONFIG_FILE"
else
  echo "  Config     -> $CONFIG_FILE (kept existing)"
fi

# --- Register hook in settings.json -----------------------------------------
HOOK_CMD="$INSTALL_DIR/check-trigger.sh"

python3 -c "
import json, os

settings_path = os.path.expanduser('$SETTINGS_FILE')
hook_cmd = '$HOOK_CMD'

try:
    with open(settings_path) as f:
        settings = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    settings = {}

if 'hooks' not in settings:
    settings['hooks'] = {}
if 'UserPromptSubmit' not in settings['hooks']:
    settings['hooks']['UserPromptSubmit'] = []

hook_list = settings['hooks']['UserPromptSubmit']
already_registered = False
for entry in hook_list:
    if not isinstance(entry, dict):
        continue
    for h in entry.get('hooks', []):
        if isinstance(h, dict) and h.get('command') == hook_cmd:
            already_registered = True
            break

if not already_registered:
    hook_list.append({
        'matcher': '',
        'hooks': [{'type': 'command', 'command': hook_cmd}]
    })
    with open(settings_path, 'w') as f:
        json.dump(settings, f, indent=2)
"
echo "  Hook       -> settings.json"

# --- Validate: run screen detection -----------------------------------------
echo ""
SCREEN_COUNT=$(osascript -l JavaScript "$INSTALL_DIR/detect-screens.js" 2>/dev/null | python3 -c "import json,sys; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "0")
echo "  Detected $SCREEN_COUNT screen(s)"

# --- Summary ----------------------------------------------------------------
echo ""
echo "  Done! Workshop Mode is ready."
echo ""
echo "  Trigger:   Type \"$TRIGGER\" in Claude Code"
echo "  Config:    $CONFIG_FILE"
echo "  Customize: /workshop setup"
echo "  Test:      /workshop --dry-run"
echo ""
