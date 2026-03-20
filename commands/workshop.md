Run the Workshop Mode script to arrange your development environment.

Arguments: $ARGUMENTS

If arguments contain "setup" or "configure", tell the user to run `/workshop-setup` instead.

Otherwise, execute: `~/.claude/scripts/workshop/workshop.sh $ARGUMENTS`

Modes:
- No arguments: full workshop activation (arrange windows, play music, etc.)
- `--dry-run`: show the calculated layout without moving anything
- `--detect-only`: show detected screen information

Report the output to the user.
