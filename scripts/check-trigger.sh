#!/usr/bin/env bash
# Hook trigger script for Claude Code UserPromptSubmit hook.
# Reads stdin JSON, checks if prompt matches the workshop trigger regex,
# and launches workshop.sh in background if it matches.
# Always exits 0 to never block Claude Code.

set -uo pipefail

# Support both plugin mode (CLAUDE_PLUGIN_ROOT) and standalone install
WORKSHOP_DIR="${CLAUDE_PLUGIN_ROOT:+${CLAUDE_PLUGIN_ROOT}/scripts}"
WORKSHOP_DIR="${WORKSHOP_DIR:-$(cd "$(dirname "$0")" && pwd)}"
CONFIG_FILE="$HOME/.claude/workshop.json"
DEFAULTS_FILE="$WORKSHOP_DIR/defaults.json"

# Read stdin (Claude Code hook sends JSON with a "prompt" field)
INPUT="$(cat)"

# Extract prompt text
PROMPT="$(echo "$INPUT" | python3 -c "import json,sys; print(json.load(sys.stdin).get('prompt',''))" 2>/dev/null || echo "")"

if [ -z "$PROMPT" ]; then
  exit 0
fi

# Get trigger regex from user config, falling back to defaults
TRIGGER="$(python3 -c "
import json, sys
trigger = None
try:
    with open('$CONFIG_FILE') as f:
        cfg = json.load(f)
        trigger = cfg.get('trigger')
except (FileNotFoundError, json.JSONDecodeError):
    pass
if not trigger:
    try:
        with open('$DEFAULTS_FILE') as f:
            trigger = json.load(f).get('trigger', '')
    except (FileNotFoundError, json.JSONDecodeError):
        trigger = 'i.?(a?m|am) home.? baby'
print(trigger)
" 2>/dev/null || echo "i.?(a?m|am) home.? baby")"

# Check if prompt matches trigger regex (case-insensitive)
MATCH="$(python3 -c "
import re, sys
prompt = sys.argv[1]
trigger = sys.argv[2]
if re.search(trigger, prompt, re.IGNORECASE):
    print('yes')
else:
    print('no')
" "$PROMPT" "$TRIGGER" 2>/dev/null || echo "no")"

if [ "$MATCH" = "yes" ]; then
  "$WORKSHOP_DIR/workshop.sh" &>/dev/null &
  disown
fi

exit 0
