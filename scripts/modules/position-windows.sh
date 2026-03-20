#!/usr/bin/env bash
set -euo pipefail

workshop_unminimize() {
  local app_names="$1"
  for app in $app_names; do
    osascript 2>/dev/null -e "
      tell application \"System Events\"
        tell process \"$app\"
          set allWindows to every window
          repeat with w in allWindows
            try
              set value of attribute \"AXMinimized\" of w to false
            end try
          end repeat
        end tell
      end tell
    " || true
  done
}

workshop_position_window() {
  local app_name="$1"
  local x="$2" y="$3" w="$4" h="$5"

  osascript 2>/dev/null -e "
    tell application \"$app_name\" to activate
    delay 0.3
    tell application \"System Events\"
      tell process \"$app_name\"
        set position of window 1 to {$x, $y}
        set size of window 1 to {$w, $h}
      end tell
    end tell
  " || true
}

workshop_position_terminal() {
  local index="$1"
  local x="$2" y="$3" w="$4" h="$5"

  osascript 2>/dev/null -e "
    tell application \"System Events\"
      tell process \"Terminal\"
        set position of window $index to {$x, $y}
        set size of window $index to {$w, $h}
      end tell
    end tell
  " || true
}

workshop_position_all_from_layout() {
  local layout_json="$1"

  # Parse terminal positions and batch them in a single osascript
  local terminal_script
  terminal_script=$(echo "$layout_json" | python3 -c "
import sys, json
layout = json.load(sys.stdin)
terminals = layout.get('terminals', [])
lines = []
for i, t in enumerate(terminals):
    idx = i + 1
    lines.append(f'set position of window {idx} to {{{t[\"x\"]}, {t[\"y\"]}}}')
    lines.append(f'set size of window {idx} to {{{t[\"w\"]}, {t[\"h\"]}}}')
print('\n'.join(lines))
")

  if [[ -n "$terminal_script" ]]; then
    osascript 2>/dev/null -e "
      tell application \"System Events\"
        tell process \"Terminal\"
          $terminal_script
        end tell
      end tell
    " || true
  fi

  # Position each app individually
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    local app_name x y w h
    read -r app_name x y w h <<< "$line"
    workshop_position_window "$app_name" "$x" "$y" "$w" "$h"
  done < <(echo "$layout_json" | python3 -c "
import sys, json
layout = json.load(sys.stdin)
for k, a in layout.get('apps', {}).items():
    print(a['app'], a['x'], a['y'], a['w'], a['h'])
")
}

workshop_raise_all() {
  local terminal_count="${1:-0}"
  local app_names="${2:-}"

  # Raise terminal windows
  if (( terminal_count > 0 )); then
    osascript 2>/dev/null -e "
      tell application \"System Events\"
        tell process \"Terminal\"
          repeat with i from 1 to $terminal_count
            try
              perform action \"AXRaise\" of window i
            end try
          end repeat
        end tell
      end tell
    " || true
  fi

  # Raise app windows
  for app in $app_names; do
    osascript 2>/dev/null -e "
      tell application \"System Events\"
        tell process \"$app\"
          try
            perform action \"AXRaise\" of window 1
          end try
        end tell
      end tell
    " || true
  done
}
