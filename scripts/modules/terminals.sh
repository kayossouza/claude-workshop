#!/usr/bin/env bash
set -euo pipefail

workshop_count_terminals() {
  local count
  # Use System Events count (only sees windows on current Space — matches positioning)
  count=$(osascript 2>/dev/null -e 'tell application "System Events" to tell process "Terminal" to count of windows' || echo "0")
  echo "$count"
}

workshop_ensure_terminals() {
  local desired="${1:-1}"
  local current
  current=$(workshop_count_terminals)

  while (( current < desired )); do
    osascript 2>/dev/null -e 'tell application "Terminal" to do script ""' || true
    current=$((current + 1))
  done
}

workshop_apply_themes() {
  local themes_json="$1"
  local profile="${2:-Homebrew}"

  local terminal_count
  terminal_count=$(workshop_count_terminals)

  # Generate the full AppleScript in one python call for efficiency
  local applescript
  applescript=$(echo "$themes_json" | python3 -c "
import sys, json
themes = json.load(sys.stdin)
count = int('$terminal_count')
profile = '$profile'
lines = ['tell application \"Terminal\"']
for i in range(1, count + 1):
    t = themes[(i - 1) % len(themes)]
    r, g, b = t['color']
    title = f\"{t['emoji']} {t['name']}\"
    lines.append(f'  set current settings of window {i} to settings set \"{profile}\"')
    lines.append(f'  set normal text color of current settings of window {i} to {{{r}, {g}, {b}}}')
    lines.append(f'  set custom title of window {i} to \"{title}\"')
lines.append('end tell')
print(chr(10).join(lines))
")

  osascript 2>/dev/null -e "$applescript" || true
}

# Two-pass theme + position
# Pass 1: themes via Terminal.app (creation order) + capture order mapping
# Pass 2: position via System Events using the mapped order
workshop_apply_themes_and_position() {
  local themes_json="$1"
  local profile="${2:-Homebrew}"
  local layout_json="$3"

  # Pass 1: apply themes via Terminal.app (stable creation order)
  workshop_apply_themes "$themes_json" "$profile"

  # Wait for profile-change resize to fully settle
  sleep 1.5

  # Build a mapping: get Terminal.app creation-order positions, then match
  # to System Events z-order by current position. After resize, all windows
  # are roughly the same size but at their current positions.

  # Get creation-order positions from Terminal.app
  local term_count
  term_count=$(python3 -c "import json,sys; print(len(json.loads(sys.argv[1]).get('terminals',[])))" "$layout_json")

  # Position all windows using System Events sequential order.
  # We KNOW the z-order hasn't changed since we only did tell application "Terminal"
  # (not System Events), and haven't activated any other apps.
  local position_script
  position_script=$(python3 -c "
import sys, json
layout = json.loads(sys.argv[1])
terminals = layout.get('terminals', [])
count = len(terminals)
lines = ['tell application \"System Events\" to tell process \"Terminal\"']
for i, t in enumerate(terminals):
    idx = i + 1
    lines.append(f'  set position of window {idx} to {{{t[\"x\"]}, {t[\"y\"]}}}')
    lines.append(f'  set size of window {idx} to {{{t[\"w\"]}, {t[\"h\"]}}}')
lines.append('end tell')
print(chr(10).join(lines))
" "$layout_json")

  osascript 2>/dev/null -e "$position_script" || true
}
