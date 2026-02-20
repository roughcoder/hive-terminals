# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What is hive

hive is a single-file bash CLI (~1000 lines) for seamless multi-machine terminal sessions over Tailscale. One always-on Mac is the **core** (runs a persistent tmux session); laptops are **links** (SSH into core via tmux grouped sessions). Each terminal tab gets an independent view of the shared window pool.

## Project structure

- `hive` — The entire CLI tool. Gets installed as `~/.local/bin/hive`.
- `install.sh` — Copies `hive` to `~/.local/bin/hive`, checks for tmux/ssh deps.
- `README.md` — User-facing documentation.

## Architecture

The entire tool is a single bash script organized into sections:

1. **Config** (`~/.hive/config`) — Stores `HIVE_ROLE`, `HIVE_CORE_HOST`, `HIVE_CORE_USER`, `HIVE_MACHINE_NAME`. Sourced via `load_config()`.
2. **Window metadata** — Descriptions stored in two places: tmux window options (`@hive_desc`) for live access, and `~/.hive/meta/` files for persistence across tmux restarts. `get_window_meta()` / `set_window_meta()` handle both.
3. **Connection model** — Links SSH to the core and run `hive _attach`, which creates a tmux grouped session (`new-session -t hive`) with `destroy-unattached`. This gives each connection its own independent window view that auto-cleans on disconnect.
4. **TUI** — A raw terminal UI using ANSI escape sequences and `read -rsn1` for keyboard input. Runs in a loop: refresh windows, draw, read key, dispatch action. Can run standalone or as a tmux popup via `display-popup`.
5. **tmux integration** — Custom tmux config at `~/.hive/tmux.conf` (sourced from `~/.tmux.conf`). Keybindings `prefix + H/N/D` for TUI popup, new window, and describe.
6. **launchd** — `com.hive.tmux.plist` keeps the tmux server alive across reboots on the core.

## Key patterns

- All commands follow the `cmd_<name>` convention (e.g., `cmd_ls`, `cmd_new`). Internal commands use `cmd__<name>` (double underscore).
- Remote execution: link machines delegate commands to core via `ssh hive-core "hive <cmd>"`.
- The `main()` function at the bottom dispatches based on the first argument.
- Color constants are defined at the top; the theme is honey/amber/gold (`#d4a843`, ANSI 214).

## Development

There is no build step, test suite, or linter. The tool is a plain bash script.

```bash
# Run locally without installing
bash hive.sh help
bash hive.sh status

# Test the TUI (requires tmux running)
bash hive.sh _tui

# Install to ~/.local/bin/hive
bash install.sh
```

## Versioning & self-update

- Version is stored in the `VERSION` variable at the top of `hive` (e.g., `VERSION="0.1.0"`).
- `hive update` downloads the latest `hive` from the GitHub raw main branch (`roughcoder/hive-terminals`) and replaces the local script.
- `install.sh` supports both local install (from a cloned repo) and remote install via `curl` pipe (downloads from GitHub if no local `hive` file is found).
- When bumping versions, update only the `VERSION` variable in `hive`. The rest is automatic.

## Conventions

- Bash strict mode: `set -euo pipefail`
- All user-facing output uses the color/symbol constants defined at the top of `hive`
- Version is stored in the `VERSION` variable at the top of `hive`
- Session name is always `hive` (stored in `HIVE_SESSION`)
