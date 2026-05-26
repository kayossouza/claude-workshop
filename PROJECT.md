# Claude Workshop

Stage: Paused
Owner: Kayo Souza
Type: infra/tooling
Status: paused
Updated: 2026-05-26
Workspace: /Users/kayosouza/work/claude-workshop
Primary Repo: /Users/kayosouza/work/claude-workshop

Mission: Transform your Mac into a developer workshop with a single voice trigger — terminals snap into a grid, music starts, apps tile across screens. Claude Code plugin that orchestrates the local environment.

MVP Scope: Voice/text trigger phrase → invoke `install.sh` flow → arrange terminals + music + apps via macOS automation. Plugin packaged for Claude Code (hooks + skills + workshop.json config).

Current Focus: Paused since 2026-03-20. No recent activity.

Last Validated: 2026-03-20 — commit 3305cba "fix: remove duplicate hooks reference from plugin.json". Plugin refactor (commit 7044f24) and initial feature (1b2b6a7) shipped earlier same month.

## Active Blockers

No active blockers — tool is feature-complete but dormant.

## External Links

| Label | URL / Path | Notes |
|---|---|---|
| Install script | [install.sh](install.sh) | |
| Uninstall script | [uninstall.sh](uninstall.sh) | |
| Workshop config sample | [workshop.json.example](workshop.json.example) | |
| Hooks | [hooks/](hooks/) | Claude Code plugin hooks |
| Skills | [skills/](skills/) | Claude Code skills |
| Scripts | [scripts/](scripts/) | |

## Project Shape

| Surface | Path | Notes |
|---|---|---|
| Hooks | [hooks/](hooks/) | Claude Code plugin hooks |
| Skills | [skills/](skills/) | Claude Code skills |
| Scripts | [scripts/](scripts/) | Setup/orchestration scripts |
| Install/Uninstall | [install.sh](install.sh) + [uninstall.sh](uninstall.sh) | |
| Backlog | [BACKLOG.md](BACKLOG.md) | |

## Notes

- **Equity**: Kayo 0% (personal infra tool)
- **Plugin format**: Claude Code plugin per refactor in commit 7044f24
- **Branch**: main, no uncommitted changes detected at last check
- **Last commit**: 2026-03-20 — paused indefinitely until Kayo needs the workshop trigger again
