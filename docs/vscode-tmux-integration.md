# VS Code tmux Integration (Optional)

[日本語版 / Japanese](vscode-tmux-integration.ja.md)

This guide shows how to integrate tmux with VS Code Remote-SSH for persistent terminal sessions that survive disconnections.

---

## Why Use tmux with VS Code?

**Benefits:**
- **Session persistence**: Your work survives network disconnections
- **Multiple panes**: Split terminals within VS Code
- **Background processes**: Keep processes running after closing VS Code
- **Tmux workflow**: Use your preferred tmux keybindings and workflow

**When to use:**
- Unstable network connections
- Long-running processes (builds, servers, database operations)
- You prefer tmux's window/pane management
- Working across multiple SSH sessions

**When NOT needed:**
- Stable local network (Docker container on localhost)
- Short editing sessions
- You prefer VS Code's built-in terminal management

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Method 1: Manual Usage](#method-1-manual-usage)
3. [Method 2: Auto-Attach Configuration](#method-2-auto-attach-configuration)
4. [Method 3: Shell Profile Integration](#method-3-shell-profile-integration)
5. [Keybinding Considerations](#keybinding-considerations)
6. [Best Practices](#best-practices)

---

## Prerequisites

- VS Code Remote-SSH extension installed and configured
- Connected to remote host with tmux installed
- Familiarity with [tmux basics](../README.md#tmux-basics)

---

## Method 1: Manual Usage

**Simplest approach - start tmux when you need it:**

1. Connect to remote host via VS Code Remote-SSH
2. Open integrated terminal (`` Ctrl+` ``)
3. Start tmux:
   ```bash
   # Create new session
   tmux

   # Or attach to existing session
   tmux attach -t my-session

   # Or create/attach to named session
   tmux new-session -A -s vscode
   ```

4. Work normally within tmux
5. Detach when done: `Ctrl+^ d` (our configured prefix + d)

**To resume after disconnection:**
1. Reconnect via VS Code Remote-SSH
2. Open terminal
3. Reattach: `tmux attach -t vscode`

---

## Method 2: Auto-Attach Configuration

**Automatically start tmux for every new VS Code terminal:**

### Configure VS Code Terminal Profile

1. Connect to remote host
2. Press `Ctrl+Shift+P`
3. Type "Preferences: Open Remote Settings (SSH: hostname)"
4. Add this configuration:

```json
{
  "terminal.integrated.profiles.linux": {
    "tmux": {
      "path": "tmux",
      "args": ["new-session", "-A", "-s", "vscode"],
      "icon": "terminal"
    }
  },
  "terminal.integrated.defaultProfile.linux": "tmux"
}
```

**What this does:**
- Creates a terminal profile named "tmux"
- Uses `tmux new-session -A -s vscode` (attach or create session named "vscode")
- Sets tmux as the default terminal profile

### Test It

1. Open new terminal (`` Ctrl+` ``)
2. Should automatically be inside tmux session "vscode"
3. Bottom of terminal shows `[vscode]` indicator
4. Close and reopen terminal - reconnects to same session!

---

## Method 3: Shell Profile Integration

**Automatically start tmux for ALL terminal sessions (not just VS Code):**

### Add to Remote Shell Profile

Edit `~/.bashrc` or `~/.zshrc` on the remote host:

```bash
# Auto-start tmux (but not from within VS Code's integrated terminal)
if command -v tmux &> /dev/null && [ -z "$TMUX" ] && [ -z "$VSCODE_IPC_HOOK_CLI" ]; then
    # Try to attach to "main" session, create if doesn't exist
    tmux attach -t main || tmux new -s main
fi
```

**Explanation:**
- `command -v tmux`: Check if tmux is installed
- `[ -z "$TMUX" ]`: Not already in tmux
- `[ -z "$VSCODE_IPC_HOOK_CLI" ]`: NOT in VS Code integrated terminal
- Attaches to session "main" or creates it

**Note:** This affects regular SSH sessions too!

---

## Keybinding Considerations

### Potential Conflicts

VS Code may capture some tmux key combinations:

| Tmux Command | Keybinding | Conflict |
| ------------ | ---------- | -------- |
| Prefix | `Ctrl+^` | Generally works |
| Split horizontal | `Ctrl+^ -` | Works |
| Split vertical | `Ctrl+^ \|` | Works |
| Previous window | `Ctrl+^ p` | May conflict with VS Code's "Quick Open" |
| New window | `Ctrl+^ c` | Works |

### Solutions

**Option 1: Use Mouse Mode (Recommended)**

Our `.tmux.conf` enables mouse support:
- Click to select panes
- Drag borders to resize
- Right-click for context menu
- Scroll to navigate history

**Option 2: Send Keys Through VS Code**

Create custom VS Code keybindings (`keybindings.json`):

```json
[
  {
    "key": "ctrl+shift+6",
    "command": "workbench.action.terminal.sendSequence",
    "args": { "text": "\u001e" },
    "when": "terminalFocus",
    "comment": "Send Ctrl+^ to terminal for tmux prefix"
  }
]
```

**Option 3: Use Regular SSH for Heavy tmux Use**

For intensive tmux workflows, consider:
- Using a dedicated SSH client (Terminal.app, iTerm2, Windows Terminal)
- VS Code Remote-SSH for editing
- Switch between tools as needed

---

## Best Practices

### 1. Session Naming

Use descriptive session names:

```bash
# Development work
tmux new -s dev

# Testing/QA
tmux new -s test

# Production monitoring
tmux new -s prod
```

List sessions: `tmux ls`

### 2. Window Organization

Organize work by context:

```bash
Ctrl+^ c     # New window
Ctrl+^ ,     # Rename window
Ctrl+^ n     # Next window
Ctrl+^ p     # Previous window
Ctrl+^ 0-9   # Jump to window by number
```

### 3. Pane Layouts

Pre-configure pane layouts:

```bash
# Horizontal split for code + terminal
Ctrl+^ -

# Vertical split for side-by-side editing
Ctrl+^ |

# Cycle through layouts
Ctrl+^ Space
```

### 4. Detach Intentionally

Don't just close VS Code - detach properly:

```bash
# Detach from session (keeps it running)
Ctrl+^ d

# Or type
tmux detach
```

### 5. Clean Up Old Sessions

Periodically remove unused sessions:

```bash
# List sessions
tmux ls

# Kill specific session
tmux kill-session -t old-session

# Kill all but current
tmux kill-session -a
```

### 6. Combine with VS Code Features

**Use both tools' strengths:**
- **VS Code**: File editing, Git UI, debugging, extensions
- **tmux**: Persistent shells, long-running processes, multiple panes

**Example workflow:**
1. Edit code in VS Code editor
2. Run tests in tmux terminal
3. Monitor logs in another tmux pane
4. Disconnect/reconnect freely - all work persists

---

## Quick Commands Reference

### tmux Session Management

```bash
# Create new session
tmux new -s myname

# Attach to session
tmux attach -t myname

# Create OR attach
tmux new-session -A -s myname

# List sessions
tmux ls

# Kill session
tmux kill-session -t myname

# Detach
Ctrl+^ d
```

### tmux Window Management

```bash
Ctrl+^ c        # Create window
Ctrl+^ ,        # Rename window
Ctrl+^ n        # Next window
Ctrl+^ p        # Previous window
Ctrl+^ 0-9      # Select window 0-9
Ctrl+^ &        # Kill window
```

### tmux Pane Management

```bash
Ctrl+^ |        # Split vertical
Ctrl+^ -        # Split horizontal
Ctrl+^ arrow    # Navigate panes
Ctrl+^ z        # Toggle pane zoom
Ctrl+^ x        # Kill pane
Ctrl+^ Space    # Cycle layouts
```

---

## Troubleshooting

### Terminal Shows Raw Control Characters

**Problem:** Typing shows `^M` or similar

**Solution:** tmux may not have initialized properly
```bash
exit        # Exit tmux
tmux kill-server  # Kill tmux server
tmux        # Start fresh
```

### Can't Access tmux After VS Code Reconnect

**Problem:** tmux session exists but can't attach

**Solution:**
```bash
# List sessions
tmux ls

# Force attach (detaches other connections)
tmux attach -t vscode -d
```

### Mouse Not Working in tmux

**Problem:** Click doesn't select panes

**Solution:** Check our `.tmux.conf` includes:
```bash
set -g mouse on
```

Reload config:
```bash
tmux source-file ~/.tmux.conf
```

---

## Related Documentation

- [Main README - tmux Basics](../README.md#tmux-basics)
- [VS Code Remote-SSH Setup](vscode-remote-ssh.md)
- [VS Code Troubleshooting](vscode-troubleshooting.md)
- [Official tmux documentation](https://github.com/tmux/tmux/wiki)

**Benefits summary:**
✅ Persistent sessions survive disconnections
✅ Multiple panes and windows organized by context
✅ Background processes keep running
✅ Flexible workflow combining VS Code + tmux strengths
