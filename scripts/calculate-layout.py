#!/usr/bin/env python3
"""Calculate window layout positions based on screen info and config."""

import argparse
import json
import math
import sys


GRID = {
    1: (1, 1), 2: (2, 1), 3: (3, 1), 4: (2, 2),
    5: (3, 2), 6: (3, 2), 7: (3, 3), 8: (3, 3),
    9: (3, 3), 10: (3, 4), 11: (3, 4), 12: (3, 4),
}


def resolve_screen(screens, ref):
    """Resolve a screen reference to a screen dict."""
    if isinstance(ref, int):
        if 0 <= ref < len(screens):
            return screens[ref]
        return screens[0]

    ref = str(ref).lower()
    if ref == "largest":
        return screens[0]  # already sorted by area desc
    if ref in ("primary", "main"):
        for s in screens:
            if s["isMain"]:
                return s
        return screens[0]
    if ref == "secondary":
        # "secondary" means "not the largest" (i.e., the other screen)
        if len(screens) > 1:
            return screens[1]
        return screens[0]
    if ref == "smallest":
        return screens[-1]

    # Try parsing as int
    try:
        idx = int(ref)
        if 0 <= idx < len(screens):
            return screens[idx]
    except (ValueError, TypeError):
        pass

    return screens[0]


def calculate_terminal_grid(screen, count, width_pct):
    """Calculate terminal window positions in a grid on the given screen.

    Each column independently divides the full screen height by its item count,
    so columns with fewer items get taller terminals (filling 100% height).
    """
    term_w = int(screen["w"] * width_pct / 100)
    term_x = screen["x"]
    term_y = screen["y"]
    term_h = screen["h"]

    cols, rows = GRID.get(count, (3, (count + 2) // 3))
    cell_w = term_w // cols

    # Distribute terminals across columns (fill columns left to right)
    col_counts = [0] * cols
    for i in range(count):
        col_counts[i % cols] += 1

    terminals = []
    idx = 0
    for c in range(cols):
        items_in_col = col_counts[c]
        if items_in_col == 0:
            continue
        col_cell_h = term_h // items_in_col

        for r in range(items_in_col):
            x = term_x + c * cell_w
            y = term_y + r * col_cell_h

            # Last column takes remaining width
            w = (term_x + term_w - x) if c == cols - 1 else cell_w
            # Last row in this column takes remaining height
            h = (term_y + term_h - y) if r == items_in_col - 1 else col_cell_h

            terminals.append({
                "index": idx + 1,
                "x": x,
                "y": y,
                "w": w,
                "h": h,
            })
            idx += 1

    return terminals


def calculate_app_position(screen, position, width_pct):
    """Calculate app window position on the given screen."""
    sx, sy, sw, sh = screen["x"], screen["y"], screen["w"], screen["h"]

    if position == "full":
        return {"x": sx, "y": sy, "w": sw, "h": sh}

    if position == "left":
        w = int(sw * width_pct / 100)
        return {"x": sx, "y": sy, "w": w, "h": sh}

    if position == "right":
        w = int(sw * width_pct / 100)
        x = sx + sw - w
        return {"x": x, "y": sy, "w": w, "h": sh}

    if position == "top-left":
        return {"x": sx, "y": sy, "w": sw // 2, "h": sh // 2}

    if position == "top-right":
        return {"x": sx + sw // 2, "y": sy, "w": sw - sw // 2, "h": sh // 2}

    if position == "bottom-left":
        return {"x": sx, "y": sy + sh // 2, "w": sw // 2, "h": sh - sh // 2}

    if position == "bottom-right":
        return {"x": sx + sw // 2, "y": sy + sh // 2, "w": sw - sw // 2, "h": sh - sh // 2}

    # Default to full
    return {"x": sx, "y": sy, "w": sw, "h": sh}


def dry_run_output(layout, screens):
    """Print human-readable layout description."""
    print("=== Screen Layout ===")
    for s in screens:
        main_tag = " (MAIN)" if s["isMain"] else ""
        print(f"  Screen {s['index']}{main_tag}: {s['w']}x{s['h']} at ({s['x']}, {s['y']}) area={s['area']}")

    print(f"\n=== Terminal Grid ({len(layout['terminals'])} windows) ===")
    for t in layout["terminals"]:
        print(f"  Terminal {t['index']}: {t['w']}x{t['h']} at ({t['x']}, {t['y']})")

    print(f"\n=== App Windows ({len(layout['apps'])} apps) ===")
    for name, app in layout["apps"].items():
        print(f"  {name} ({app['app']}): {app['w']}x{app['h']} at ({app['x']}, {app['y']})")


def main():
    parser = argparse.ArgumentParser(description="Calculate window layout positions")
    parser.add_argument("--screens", help="Path to screens JSON file (or read from stdin)")
    parser.add_argument("--config", required=True, help="Path to merged config JSON")
    parser.add_argument("--terminal-count", type=int, required=True, help="Number of terminal windows")
    parser.add_argument("--dry-run", action="store_true", help="Print human-readable layout")
    args = parser.parse_args()

    # Load screens
    if args.screens:
        with open(args.screens) as f:
            screens = json.load(f)
    else:
        screens = json.load(sys.stdin)

    # Load config
    with open(args.config) as f:
        config = json.load(f)

    # Terminal config
    term_config = config.get("terminals", {})
    term_screen_ref = term_config.get("screen", "largest")
    term_width_pct = term_config.get("width_pct", 50)
    term_screen = resolve_screen(screens, term_screen_ref)

    # Calculate terminal grid
    terminals = calculate_terminal_grid(term_screen, args.terminal_count, term_width_pct)

    # Calculate app positions
    apps = {}
    apps_config = config.get("apps", {})
    for key, app_entry in apps_config.items():
        app_name = app_entry.get("app", key)
        app_screen_ref = app_entry.get("screen", "largest")
        app_screen = resolve_screen(screens, app_screen_ref)
        position = app_entry.get("position", "full")
        app_width_pct = app_entry.get("width_pct", 50)

        pos = calculate_app_position(app_screen, position, app_width_pct)
        apps[key] = {"app": app_name, **pos}

    layout = {"terminals": terminals, "apps": apps}

    if args.dry_run:
        dry_run_output(layout, screens)
    else:
        print(json.dumps(layout, indent=2))


if __name__ == "__main__":
    main()
