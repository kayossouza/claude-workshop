#!/usr/bin/env bash
set -euo pipefail

workshop_enable_focus() {
  # Try Shortcuts first (cleaner approach)
  if shortcuts run "Focus" 2>/dev/null; then
    return 0
  fi
  # Fallback to defaults
  defaults write com.apple.controlcenter DoNotDisturb -bool true 2>/dev/null || true
}

workshop_disable_focus() {
  if shortcuts run "Focus Off" 2>/dev/null; then
    return 0
  fi
  defaults write com.apple.controlcenter DoNotDisturb -bool false 2>/dev/null || true
}

workshop_disable_stage_manager() {
  defaults write com.apple.WindowManager GloballyEnabled -bool false 2>/dev/null || true
  # Restart WindowManager to apply immediately
  killall -HUP WindowManager 2>/dev/null || true
}

workshop_enable_stage_manager() {
  defaults write com.apple.WindowManager GloballyEnabled -bool true 2>/dev/null || true
  killall -HUP WindowManager 2>/dev/null || true
}
