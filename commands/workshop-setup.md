Help the user configure their Workshop Mode setup interactively.

Read the current config from `~/.claude/workshop.json` and the defaults from `~/.claude/scripts/workshop/defaults.json`.

Walk through each section conversationally, showing current values and asking what they'd like to change. Use AskUserQuestion for choices.

## Sections to configure:

1. **Trigger phrase** — what they type to activate (currently a regex in `trigger` field). Show the current phrase and ask if they want to change it.

2. **Music** — app (Spotify/Apple Music/none), track URI. If Spotify, help them: they can paste a Spotify URL and you convert it to a URI (`spotify:track:TRACKID`). Or they can describe a song and you can suggest the URI format.

3. **Terminals** — count (0=auto), which screen ("largest" for external, "primary" for MacBook), column layout. Explain that 0 means "use however many are open".

4. **Apps layout** — which apps to arrange and where. Show current setup. Each app has: app name, screen (largest/primary/secondary), position (left/right/full), width_pct. Common setups:
   - External monitor: all terminals. MacBook: Slack left + Spotify right (current default)
   - External: terminals left 60% + Spotify right 40%. MacBook: Chrome left + Slack right
   - Single monitor: terminals top, apps bottom

5. **Features** — focus mode, wallpaper, startup sounds, greeting text, notification text. Show which are enabled/disabled.

6. **Terminal themes** — show current theme list (character names + colors). Ask if they want to customize.

## After each section:

Write the updated config to `~/.claude/workshop.json` using a deep merge (only override changed values, keep the rest).

## At the end:

Run `~/.claude/scripts/workshop/workshop.sh --dry-run` to show them the calculated layout, so they can verify before trying it live.

## Important:
- Only write fields that differ from defaults — keep the config minimal
- Convert Spotify URLs (open.spotify.com/track/XXXXX) to URIs (spotify:track:XXXXX)
- Use `~/.claude/scripts/workshop/defaults.json` as reference for all default values
- Be friendly and brief — this should feel like a quick chat, not a form
