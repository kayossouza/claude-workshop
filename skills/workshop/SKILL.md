---
name: workshop
description: Activate Workshop Mode to arrange your dev environment, or preview the layout with --dry-run
---

Run the Workshop Mode script to arrange your development environment.

Arguments: $ARGUMENTS

If arguments contain "setup" or "configure", tell the user to run `/workshop-mode:workshop-setup` instead.

Otherwise, execute: `${CLAUDE_PLUGIN_ROOT}/scripts/workshop.sh $ARGUMENTS`

Modes:
- No arguments: full workshop activation (arrange windows, play music, etc.)
- `--dry-run`: show the calculated layout without moving anything
- `--detect-only`: show detected screen information

Report the output to the user.
