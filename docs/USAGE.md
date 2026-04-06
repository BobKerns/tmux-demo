# tmux Usage Guide

[日本語版はこちら / Japanese version](USAGE.ja.md)

This guide explains how to effectively use tmux for remote development, focusing on practical workflows that avoid confusion.

---

## Table of Contents

1. [Understanding tmux Layers](#understanding-tmux-layers)
2. [Recommended Setup](#recommended-setup)
3. [Basic Workflow](#basic-workflow)
4. [Window Management Commands](#window-management-commands)
5. [When to Use Multiple Sessions](#when-to-use-multiple-sessions)
6. [Common Scenarios](#common-scenarios)

---

## Understanding tmux Layers

tmux has four layers that can be confusing at first:

```
┌─────────────────────────────────────────┐
│ Client (your local terminal/PSMUX)      │  ← Can have multiple
│  ↓ connects to                          │
│ Session (persistent, runs on server)    │  ← Share one session
│  ↓ contains                             │
│ Windows (like tabs)                     │  ← Use these actively
│  ↓ contains                             │
│ Panes (split sections within a window)  │  ← Use sparingly
└─────────────────────────────────────────┘
```

**Key insight**: Multiple clients can connect to the *same* session. This means:
- Opening a new terminal window and connecting → same session, same windows
- VS Code terminal connecting → can use the same session
- All clients see the same windows and panes
- When one client disconnects, the session survives for other clients

**Recommended approach**: Use **one or two sessions** with **multiple windows**, not multiple sessions.

---

## Recommended Setup

### Connection Alias/Script

Instead of typing `ssh ... ; tmux attach` every time, create a simple connection that automatically
attaches to your main session:

**For bash/zsh** (add to `~/.bashrc` or `~/.zshrc` on your local machine):

```bash
# Connect to AWS and attach to 'main' session (create if doesn't exist)
alias aws-dev='ssh -i ~/.ssh/your-aws-key.pem <your-username>@<your-ec2-hostname> -t "tmux new-session -A -s main"'
```

**Or create a script** (`~/bin/aws-dev`):

```bash
#!/bin/bash
# Connect to AWS EC2 and attach to main tmux session
ssh -i ~/.ssh/your-aws-key.pem <your-username>@<your-ec2-hostname> -t "tmux new-session -A -s main"
```

Make it executable:
```bash
chmod +x ~/bin/aws-dev
```

**What this does**:
- `tmux new-session -A -s main` → Attach to session named "main" if it exists, create it if it doesn't
- All your terminal windows/tabs connecting this way share the same session
- When you disconnect and reconnect, you're back to the exact same state

---

## Basic Workflow

### Starting Your Day

1. **Connect from your first terminal**:
   ```bash
   aws-dev  # (using the alias above)
   ```
   This creates or attaches to session "main"

2. **Create windows for different tasks**:
   ```
   Ctrl+^ c    # Create window for ML training scripts
   Ctrl+^ c    # Create window for monitoring (htop/nvidia-smi)
   Ctrl+^ c    # Create window for git/editing
   ```

3. **Switch between windows** as needed:
   ```
   Ctrl+^ 0    # Go to window 0
   Ctrl+^ 1    # Go to window 1
   Ctrl+^ n    # Next window
   Ctrl+^ p    # Previous window
   ```

### Opening Additional Clients

When you open a **second terminal window** and run `aws-dev` again:
- ✅ You connect to the **same session**
- ✅ You see the **same windows** (0, 1, 2, etc.)
- ✅ Both terminals stay synchronized
- ✅ If one disconnects, the other continues

**Why this is better than separate sessions**:
- No confusion about which session has which work
- All your work is in one place
- Easy to share state between different terminal windows
- When you reconnect after network issues, everything is exactly where you left it

---

## Window Management Commands

Remember: Prefix is **Ctrl+^** (hold Ctrl and press ^)

### Creating and Closing Windows

| Command | Description |
| --------- | ------------- |
| `Ctrl+^ c` | **Create** new window |
| `Ctrl+^ ,` | **Rename** current window |
| `Ctrl+^ &` | **Kill** current window (asks for confirmation) |
| `exit` | Close current pane/window (if last pane) |

### Navigating Windows

| Command | Description |
| --------- | ------------- |
| `Ctrl+^ 0-9` | Go to window **number** (0-9) |
| `Ctrl+^ n` | Go to **next** window |
| `Ctrl+^ p` | Go to **previous** window |
| `Ctrl+^ l` | Go to **last** used window |
| `Ctrl+^ w` | **List** all windows (choose with arrows) |
| `Ctrl+^ f` | **Find** window by name |

### Window List

At the bottom of your terminal, you'll see something like:
```
[main] 0:bash  1:training*  2:monitor-  3:code
```

- `[main]` = session name
- `0:bash` = window number and name
- `*` = current window
- `-` = last window you were in

### Organizing Work with Windows

**Example setup for ML training**:
```
Window 0 (bash)       → General shell, file management
Window 1 (train)      → Running training scripts
Window 2 (monitor)    → htop / nvidia-smi / watch commands
Window 3 (jupyter)    → Jupyter notebook server
Window 4 (code)       → Code editing / git operations
```

Rename windows to remember their purpose:
```bash
Ctrl+^ ,              # Then type new name, e.g. "training"
```

---

## When to Use Multiple Sessions

**Generally avoid** creating many sessions. But there are valid use cases:

### Two-Session Setup (Recommended Maximum)

```bash
# Session 1: "main" - for manual terminal work
tmux new-session -A -s main

# Session 2: "vscode" - dedicated for VS Code terminal
tmux new-session -A -s vscode
```

**Why separate sessions?**
- VS Code terminal auto-attach won't interfere with manual work
- Close VS Code without affecting your manual terminal session
- Each session has independent window numbering

**To switch between sessions** (when attached):
```
Ctrl+^ s    # Show session list, use arrows to select
Ctrl+^ (    # Switch to previous session
Ctrl+^ )    # Switch to next session
```

### When NOT to Create New Sessions

❌ **Don't create** a new session for:
- Different projects → Use windows instead
- Different tasks → Use windows instead
- Each terminal window → Connect to same session

✅ **Do create** windows for:
- Different projects
- Different tasks (training, monitoring, editing)
- Separate long-running processes

---

## Common Scenarios

### Scenario 1: Long Training Job

```bash
# Connect to main session
aws-dev

# Create dedicated window for training
Ctrl+^ c
Ctrl+^ ,
# Type: "training"

# Start your training
python train_model.py

# Create monitoring window
Ctrl+^ c
Ctrl+^ ,
# Type: "monitor"

# Watch GPU usage
watch -n 1 nvidia-smi

# Switch back to training window to check logs
Ctrl+^ p  # Or Ctrl+^ followed by window number
```

**Disconnect safely**: Just close your terminal or press `Ctrl+^ d`
- Training continues running
- Reconnect anytime with `aws-dev`
- Everything is exactly as you left it

### Scenario 2: Multiple Terminal Windows

You want to check something while training runs:

```bash
# In original terminal: training is running in window 1

# Open NEW terminal window on your laptop
aws-dev  # Connects to same "main" session

# You see the same windows!
# Create a new window for your quick task
Ctrl+^ c

# Do your work...

# Close this terminal when done
# Training in window 1 continues untouched
```

### Scenario 3: VS Code + Manual Terminal

```bash
# Manual terminal
ssh <host> -t "tmux new-session -A -s main"

# VS Code Remote-SSH terminal (configure in settings.json)
"terminal.integrated.profiles.linux": {
  "tmux-vscode": {
    "path": "tmux",
    "args": ["new-session", "-A", "-s", "vscode"]
  }
}
```

Now you have:
- `main` session: For SSH terminal work
- `vscode` session: For VS Code integrated terminal
- No conflict when closing VS Code

### Scenario 4: Network Interruption

```bash
# Working in window 1 (training)
python long_running_job.py

# Network disconnects!
# (Session continues on server)

# Later, reconnect
aws-dev

# You're back! Same windows, training still running
Ctrl+^ 1  # Go to training window
# Check logs, confirm it's still running
```

---

## Quick Reference Card

### Essential Commands (90% of usage)

```bash
# Connection
tmux new-session -A -s main     # Attach to "main" (or create)

# Windows
Ctrl+^ c        Create new window
Ctrl+^ ,        Rename window
Ctrl+^ 0-9      Go to window number
Ctrl+^ n        Next window
Ctrl+^ p        Previous window
Ctrl+^ w        List windows

# Session
Ctrl+^ d        Detach (disconnect but keep running)
Ctrl+^ s        List sessions (if using multiple)

# Help
Ctrl+^ ?        Show all keybindings
```

### Checking What's Running

```bash
# From outside tmux
tmux ls                          # List sessions

# From inside tmux
Ctrl+^ w                         # List windows in current session
Ctrl+^ s                         # List all sessions
```

---

## Tips for Success

1. **Start simple**: Use one session (`main`) with multiple windows
2. **Name your windows**: `Ctrl+^ ,` makes it easy to remember what's where
3. **Don't use terminal tabs**: Let tmux windows be your "tabs"
4. **Trust the session**: When you disconnect, everything keeps running
5. **Customize later**: Once comfortable, explore panes, custom layouts, etc.

---

## Additional Resources

- [tmux Cheat Sheet](https://tmuxcheatsheet.com/)
- [SSH Setup Guide](ssh-setup.md)
- [VS Code Remote-SSH Guide](vscode-remote-ssh.md)
- [VS Code tmux Integration](vscode-tmux-integration.md)

---

**Questions?** This workflow takes a day or two to feel natural. The key is: **one session, many windows**.
