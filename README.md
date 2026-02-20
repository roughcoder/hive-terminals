# ⬡ hive

Seamless multi-machine terminal sessions over Tailscale.

Your always-on Mac is the **core**. Your laptops are **links**. Every terminal tab is a window into the same hive — open a tab on any machine and you're in the same workspace, with all your processes running, all your context preserved.

## How it works

```
┌─────────────────┐     Tailscale      ┌────────────────────┐
│  MacBook (link)  │ ──── SSH ────────▶ │  Mac Mini (core)   │
│                  │                    │                    │
│  Warp Tab 1 ─────┼───────────────────▶│  tmux window 1     │
│  Warp Tab 2 ─────┼───────────────────▶│  tmux window 2     │
│  Warp Tab 3 ─────┼───────────────────▶│  tmux window 3     │
└─────────────────┘                    └────────────────────┘
                                              ▲
┌─────────────────┐                           │
│  Mac Mini local  │                          │
│                  │                          │
│  Warp Tab 4 ─────┼──────────────────────────┘ (same windows!)
└─────────────────┘
```

- **Close your laptop** — processes keep running on the core
- **Open a new tab** — it's a new view into the same hive
- **Switch machines** — pick up exactly where you left off
- **Independent views** — each tab controls its own visible window (no fighting over focus)

## Prerequisites

Before installing hive, make sure you have:

| Dependency | Install | Required on |
|-----------|---------|-------------|
| **tmux** | `brew install tmux` | Core + Links |
| **Tailscale** | [tailscale.com/download](https://tailscale.com/download) | Core + Links |
| **SSH keys** | See [setup](#ssh-key-setup) below | Core + Links |

Both machines need to be on the same Tailscale network and able to reach each other.

### SSH key setup

If you haven't already set up SSH key access from your laptop to your core machine:

```bash
# On your laptop, generate a key (if you don't already have one)
ssh-keygen -t ed25519

# Copy it to the core machine (use the Tailscale hostname or IP)
ssh-copy-id youruser@your-mac-mini

# Test it — this should log in without asking for a password
ssh youruser@your-mac-mini "echo 'SSH keys working'"
```

## Install

### One-liner (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/roughcoder/hive-terminals/main/install.sh | bash
```

This checks for dependencies, downloads `hive` from GitHub, and installs it to `~/.local/bin/hive`.

### From the repo

```bash
git clone https://github.com/roughcoder/hive-terminals.git
cd hive-terminals
bash install.sh
```

If prompted to add to your PATH:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### Verify it installed

```bash
hive version
# => hive v0.1.0

hive help
# => shows all commands
```

## Updating

```bash
hive update            # Download and install the latest version
hive update --check    # Check for updates without installing
```

## Setup

Hive has two roles. You configure each machine once.

### 1. Core (the always-on Mac)

Run this on the machine that will host all your sessions (e.g. a Mac Mini, Mac Studio, or any Mac that stays on):

```bash
hive init core
```

This does the following:
- Creates `~/.hive/config` with `HIVE_ROLE="core"`
- Generates a tmux config at `~/.hive/tmux.conf` with the hive theme and keybindings
- Sources that config from `~/.tmux.conf`
- Creates a launchd agent (`com.hive.tmux`) to keep the tmux server running across reboots
- Starts the persistent `hive` tmux session

**Verify the core is working:**

```bash
hive status
# Should show:
#   ⬢ your-hostname (core)
#   ● Hive session active
#   Windows: 1  Connected: 0

hive ls
# Should show one default "main" window
```

### 2. Link (each laptop)

Run this on every machine you want to connect from:

```bash
hive init link
```

It will prompt you for:
- **Core hostname** — the Tailscale hostname or IP of your core machine (e.g. `mac-mini` or `100.x.x.x`)
- **Core username** — defaults to your current username

This does the following:
- Creates `~/.hive/config` with `HIVE_ROLE="link"` and the core connection info
- Adds an SSH config block (`Host hive-core`) with keepalive and multiplexing settings
- Tests the connection to the core

**Verify the link is working:**

```bash
hive status
# Should show:
#   ⬡ your-laptop (link)
#   Core: youruser@mac-mini
#   Connection: reachable
```

### 3. Connect

From a link machine, just run:

```bash
hive
```

This SSHs into the core and attaches to the hive tmux session. Each connection gets its own independent grouped session — you can look at different windows in different tabs without interfering with each other.

## Testing on a single machine

You can try hive without a second machine. Just init as core and use it locally:

```bash
# Install and init
hive init core

# Attach to the hive session
hive

# You're now in tmux. Try these:
hive new api "Working on the API"
hive new logs "Tailing production logs"
hive ls

# Open the interactive TUI
hive join

# Or press prefix + H for the TUI as a popup
# (prefix is Ctrl+B by default in tmux)

# Tag the current window with a description
hive tag "Testing hive for the first time"

# Check status
hive status
```

## Commands

| Command | What it does |
|---------|-------------|
| `hive` | Smart default — TUI if already in tmux, SSH connect if on a link |
| `hive init core` | Set up this machine as the always-on core |
| `hive init link` | Set up this machine as a link to the core |
| `hive connect` | Connect to core from a link (or attach locally on core) |
| `hive join` | Interactive window picker (TUI) |
| `hive ls` | List all windows with their descriptions |
| `hive new [name] [desc]` | Create a new window (optionally named and described) |
| `hive tag "desc"` | Set or update the description on the current window |
| `hive rename <name>` | Rename the current window |
| `hive close [window]` | Close a window (prompts for confirmation in TUI) |
| `hive status` | Show machine role, session info, and connection status |
| `hive update` | Update hive to the latest version |
| `hive update --check` | Check for updates without installing |
| `hive shell-init` | Print shell integration code for aliases and auto-connect |
| `hive help` | Show help |
| `hive version` | Print version |

## Interactive TUI

Run `hive` or `hive join` inside tmux to get the interactive picker:

```
  ⬡ hive  mac-mini  2 connected
  ──────────────────────────────────────────────────

  ▸ ● 1 api-work  — Fixing the OMS migration endpoints
    ○ 2 frontend  — Dinky Diaries React Native
    ○ 3 zsh       bash
    ○ 4 logs      — Watching Aurora logs

  ──────────────────────────────────────────────────
  ↑↓ navigate  ⏎ join  n new  d describe  r rename  x close  q quit
```

| Key | Action |
|-----|--------|
| `↑` / `↓` | Navigate between windows |
| `Enter` | Switch to the selected window |
| `n` | Create a new window |
| `d` | Add or update description on selected window |
| `r` | Rename selected window |
| `x` | Close selected window (with confirmation) |
| `q` / `Esc` | Exit the TUI |

You can also press `prefix + H` inside any tmux session to open the TUI as a floating popup.

## tmux keybindings

These are available inside a hive session (added by `hive init core`):

| Binding | Action |
|---------|--------|
| `prefix + H` | Open the hive TUI as a popup |
| `prefix + N` | Create a new named window (prompts for name) |
| `prefix + D` | Describe the current window (prompts for description) |

The default tmux prefix is `Ctrl+B`.

## Shell integration

Add to your `~/.zshrc` (or `~/.bashrc`):

```bash
eval "$(hive shell-init)"
```

This gives you short aliases:

| Alias | Expands to |
|-------|-----------|
| `h` | `hive` |
| `hl` | `hive ls` |
| `hn` | `hive new` |
| `ht` | `hive tag` |

The shell-init output also includes commented-out auto-connect blocks. Uncomment them to automatically attach to the hive session whenever you open a new terminal tab:

- **On a link** — every new tab SSHs to the core and attaches
- **On the core** — every new tab joins the local hive session

## Window metadata

Every window can have a description attached to it. Descriptions are stored in two places for resilience:

1. **tmux window options** (`@hive_desc`) — used for live lookups while the session is running
2. **`~/.hive/meta/` files** — persist across tmux server restarts

Set descriptions via `hive tag`, the TUI (`d` key), or `prefix + D`.

## AI-friendly

Window descriptions can be set programmatically, making it easy for AI coding tools or scripts to label what they're doing:

```bash
hive new "deploy" "Running staging deployment"
hive tag "Claude Code: refactoring auth module"
```

This makes `hive ls` a quick way to see what's happening across all your workspaces at a glance.

## How connections work

When a link connects to the core, hive creates a **tmux grouped session** — a separate session that shares the same window pool as the main `hive` session. Each grouped session:

- Has its own independently selected "current window" (no tab fighting)
- Auto-destroys when the SSH connection drops (`destroy-unattached`)
- Leaves all windows and processes intact on the core

SSH connections use `ControlMaster` multiplexing for fast reconnection. The first connection opens the SSH tunnel; subsequent connections reuse it with near-instant startup.

## File layout

```
~/.hive/
├── config          # Machine role and core connection info
├── meta/           # Persistent window descriptions
├── tmux.conf       # Hive tmux theme and keybindings (core only)
├── tmux.log        # tmux server stdout (core only)
└── tmux.err        # tmux server stderr (core only)

~/.local/bin/
└── hive            # The CLI itself

~/Library/LaunchAgents/
└── com.hive.tmux.plist   # Keeps tmux alive on boot (core only)
```

## Troubleshooting

### "hive: command not found"

Make sure `~/.local/bin` is in your PATH:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### Link can't connect to core

1. Check both machines are on the same Tailscale network: `tailscale status`
2. Test SSH directly: `ssh youruser@core-hostname "echo ok"`
3. If that fails, copy your SSH key: `ssh-copy-id youruser@core-hostname`
4. Check the hive SSH config: `cat ~/.ssh/config` (look for the `Host hive-core` block)

### "No hive session" on core

The tmux session may have been killed. Restart it:

```bash
hive init core   # Re-creates the launchd agent and session
# or manually:
tmux new-session -d -s hive -n main
```

### Tmux server not starting on boot

Check the launchd agent:

```bash
launchctl list | grep hive
cat ~/Library/LaunchAgents/com.hive.tmux.plist
```

Reload it:

```bash
launchctl unload ~/Library/LaunchAgents/com.hive.tmux.plist
launchctl load ~/Library/LaunchAgents/com.hive.tmux.plist
```
