#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Claude Workshop Mode — Uninstaller
# ============================================================================

INSTALL_DIR="$HOME/.claude/scripts/workshop"
COMMANDS_FILE="$HOME/.claude/commands/workshop.md"
CONFIG_FILE="$HOME/.claude/workshop.json"
SETTINGS_FILE="$HOME/.claude/settings.json"

echo "=== Claude Workshop Mode — Uninstaller ==="
echo ""

# --- Remove hook from settings.json -----------------------------------------
if [ -f "$SETTINGS_FILE" ]; then
  echo "Removing workshop hook from $SETTINGS_FILE..."
  python3 -c "
import json, os

settings_path = os.path.expanduser('$SETTINGS_FILE')
hook_cmd = '$INSTALL_DIR/check-trigger.sh'

try:
    with open(settings_path) as f:
        settings = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    print('No settings file found, skipping.')
    exit(0)

hooks = settings.get('hooks', {})
if 'UserPromptSubmit' in hooks:
    original_count = len(hooks['UserPromptSubmit'])
    # Filter out entries whose nested hooks contain the workshop command
    hooks['UserPromptSubmit'] = [
        entry for entry in hooks['UserPromptSubmit']
        if not (isinstance(entry, dict) and any(
            isinstance(h, dict) and h.get('command') == hook_cmd
            for h in entry.get('hooks', [])
        ))
    ]
    removed = original_count - len(hooks['UserPromptSubmit'])
    # Clean up empty hook list
    if not hooks['UserPromptSubmit']:
        del hooks['UserPromptSubmit']
    if not hooks:
        del settings['hooks']
    with open(settings_path, 'w') as f:
        json.dump(settings, f, indent=2)
    print(f'Removed {removed} hook(s).')
else:
    print('No workshop hook found.')
"
fi

# --- Remove scripts ---------------------------------------------------------
if [ -d "$INSTALL_DIR" ]; then
  echo "Removing $INSTALL_DIR..."
  rm -rf "$INSTALL_DIR"
  echo "Done."
else
  echo "Scripts directory not found (already removed?)."
fi

# --- Remove slash command ---------------------------------------------------
if [ -f "$COMMANDS_FILE" ]; then
  echo "Removing $COMMANDS_FILE..."
  rm "$COMMANDS_FILE"
  echo "Done."
else
  echo "Slash command not found (already removed?)."
fi

# --- Optionally remove config ----------------------------------------------
if [ -f "$CONFIG_FILE" ]; then
  echo ""
  read -rp "Remove config at $CONFIG_FILE? [y/N] " answer
  case "$answer" in
    [yY]|[yY][eE][sS])
      rm "$CONFIG_FILE"
      echo "Config removed."
      ;;
    *)
      echo "Config kept at $CONFIG_FILE."
      ;;
  esac
fi

# --- Summary ----------------------------------------------------------------
echo ""
echo "=== Uninstall Complete ==="
echo ""
echo "Removed:"
echo "  Scripts:   $INSTALL_DIR"
echo "  Command:   $COMMANDS_FILE"
echo "  Hook:      UserPromptSubmit entry from $SETTINGS_FILE"
echo ""
echo "Workshop mode has been deactivated."
