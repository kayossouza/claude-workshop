#!/usr/bin/env bash
set -euo pipefail

workshop_notify() {
  local title="${1:-}"
  local subtitle="${2:-}"
  local message="${3:-}"

  osascript 2>/dev/null -e "
    display notification \"$message\" with title \"$title\" subtitle \"$subtitle\"
  " || true
}
