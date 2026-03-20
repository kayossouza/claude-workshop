#!/usr/bin/env bash
set -euo pipefail

workshop_start_jarvis() {
  local config_json="$1"

  local enabled api_port server_script
  enabled=$(echo "$config_json" | python3 -c "import sys,json; c=json.load(sys.stdin); print(c.get('enabled', False))" 2>/dev/null || echo "False")
  [[ "$enabled" != "True" ]] && return 0

  api_port=$(echo "$config_json" | python3 -c "import sys,json; print(json.load(sys.stdin).get('api_port', 3456))" 2>/dev/null)
  server_script=$(echo "$config_json" | python3 -c "import sys,json; print(json.load(sys.stdin).get('server_script', ''))" 2>/dev/null)

  [[ -z "$server_script" ]] && return 0
  [[ ! -f "$server_script" ]] && return 0

  # Check if already running
  if curl -s "http://localhost:${api_port}/health" >/dev/null 2>&1; then
    return 0
  fi

  # Start the server
  local server_dir
  server_dir=$(dirname "$server_script")
  nohup bun run "$server_script" > /tmp/jarvis-server.log 2>&1 &

  # Wait briefly for startup
  for i in {1..5}; do
    sleep 1
    if curl -s "http://localhost:${api_port}/health" >/dev/null 2>&1; then
      return 0
    fi
  done
}

workshop_run_briefing() {
  local config_json="$1"
  local speak_script="${2:-}"

  local enabled api_port music_app
  enabled=$(echo "$config_json" | python3 -c "import sys,json; c=json.load(sys.stdin); print(c.get('enabled', False))" 2>/dev/null || echo "False")
  [[ "$enabled" != "True" ]] && return 0
  [[ -z "$speak_script" || ! -f "$speak_script" ]] && return 0

  api_port=$(echo "$config_json" | python3 -c "import sys,json; print(json.load(sys.stdin).get('api_port', 3456))" 2>/dev/null)
  music_app=$(echo "$config_json" | python3 -c "import sys,json; print(json.load(sys.stdin).get('music_app', 'none'))" 2>/dev/null || echo "none")

  # Fetch briefing
  local briefing_response
  briefing_response=$(curl -s "http://localhost:${api_port}/briefing" 2>/dev/null || echo "")
  [[ -z "$briefing_response" ]] && return 0

  local status
  status=$(echo "$briefing_response" | python3 -c "import sys,json; print(json.load(sys.stdin).get('status', ''))" 2>/dev/null || echo "")

  # Handle 202 (generating) — wait and retry once
  if [[ "$status" == "generating" ]]; then
    sleep 10
    briefing_response=$(curl -s "http://localhost:${api_port}/briefing" 2>/dev/null || echo "")
    [[ -z "$briefing_response" ]] && return 0
  fi

  local briefing_text
  briefing_text=$(echo "$briefing_response" | python3 -c "import sys,json; print(json.load(sys.stdin).get('text', ''))" 2>/dev/null || echo "")
  [[ -z "$briefing_text" ]] && return 0

  # Lower music volume during speech
  workshop_set_volume "$music_app" 15

  # Speak the briefing
  bash "$speak_script" "$briefing_text"

  # Fetch and speak summary
  local summary_response summary_text
  summary_response=$(curl -s "http://localhost:${api_port}/summary" 2>/dev/null || echo "")
  if [[ -n "$summary_response" ]]; then
    summary_text=$(echo "$summary_response" | python3 -c "import sys,json; print(json.load(sys.stdin).get('text', ''))" 2>/dev/null || echo "")
    if [[ -n "$summary_text" ]]; then
      bash "$speak_script" "$summary_text"
    fi
  fi

  # Restore music volume
  workshop_set_volume "$music_app" 50
}
