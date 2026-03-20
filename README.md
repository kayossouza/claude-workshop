# Claude Workshop Mode

Transform your Mac into a developer workshop with a single voice trigger. Type your phrase in Claude Code and your entire environment arranges itself — terminals snap into a grid, music starts playing, apps tile across your screens.

![Workshop Mode](screenshot.png)

## Install

```bash
git clone https://github.com/kayosouza/claude-workshop.git
cd claude-workshop
./install.sh
```

The installer walks you through setup:
- **Trigger phrase** — what you type to activate (default: "i'm home baby")
- **Music** — Spotify, Apple Music, or none
- **Terminal count** — fixed number or auto-detect
- **Apps** — which apps to arrange on your screens

## Usage

Type your trigger phrase in Claude Code. That's it.

```
> i'm home baby
Workshop online. 6 terminals + Spotify + Slack arranged.
```

Or use slash commands:

```
/workshop              # Full activation
/workshop --dry-run    # Preview layout without moving windows
/workshop --detect-only # Show detected screens
/workshop-setup        # Reconfigure interactively with Claude
```

## How It Works

1. Detects all connected screens via macOS native APIs
2. Calculates an optimal grid layout for your terminals
3. Arranges app windows across screens (Slack, Spotify, Chrome, etc.)
4. Applies color themes to each terminal window
5. Optionally plays music, enables Focus Mode, sets wallpaper

Terminals fill the external monitor in a 3-column adaptive grid — columns with fewer windows get taller terminals so every pixel is used.

Apps tile on your MacBook screen (e.g., Slack left + Spotify right).

## Configuration

Edit `~/.claude/workshop.json` or run `/workshop-setup` for guided configuration.

You only need to specify what differs from defaults. A minimal config:

```json
{
  "music": {
    "track": "spotify:track:4cOdK2wGLETKBW3PvgPWqT"
  },
  "terminals": {
    "count": 6
  }
}
```

### All Options

| Key | Description | Default |
|-----|-------------|---------|
| `trigger` | Regex to match your trigger phrase | `i.?(a?m\|am) home.? baby` |
| `music.app` | `"Spotify"`, `"Apple Music"`, or `"none"` | `"Spotify"` |
| `music.track` | Spotify URI or song identifier | Back in Black |
| `terminals.count` | Number of terminals (`0` = auto) | `0` |
| `terminals.screen` | Which screen: `"largest"`, `"primary"` | `"largest"` |
| `terminals.width_pct` | Percentage of screen width | `100` |
| `terminals.profile` | Terminal.app profile name | `"Homebrew"` |
| `terminals.themes` | Array of `{name, emoji, color}` | 9 anime themes |
| `apps.*.app` | macOS app name | varies |
| `apps.*.screen` | `"largest"`, `"primary"`, `"secondary"` | varies |
| `apps.*.position` | `"left"`, `"right"`, `"full"` | varies |
| `apps.*.width_pct` | Width percentage on screen | `50` |
| `features.focus_mode` | Enable Do Not Disturb | `true` |
| `features.wallpaper` | `"black"`, `"none"`, or file path | `"black"` |
| `features.startup_sound` | Play startup sounds | `true` |
| `features.greeting` | Text spoken on activation | `"Welcome back!..."` |

### Screen References

| Value | Meaning |
|-------|---------|
| `"largest"` | Screen with most pixels (usually external monitor) |
| `"primary"` | macOS main screen (has the menu bar) |
| `"secondary"` | The other screen (not the largest) |
| `"smallest"` | Screen with fewest pixels |
| `0`, `1`, `2` | Screen by index |

## Requirements

- macOS (uses AppleScript and JXA)
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code)
- Terminal.app
- Python 3 (ships with macOS)

## Uninstall

```bash
cd claude-workshop
./uninstall.sh
```

## License

MIT
