# VS Code Remote-SSH Setup Guide

[日本語版 / Japanese](vscode-remote-ssh.ja.md)

Complete guide for using Visual Studio Code Remote-SSH extension with your tmux development environment.

---

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Installation](#installation)
4. [Configuration](#configuration)
5. [Connecting](#connecting)
6. [Working Remotely](#working-remotely)
7. [tmux Integration](#tmux-integration)
8. [Troubleshooting](#troubleshooting)

---

## Overview

VS Code Remote-SSH allows you to:

- **Edit files** on a remote machine as if they were local
- **Run commands** in an integrated terminal on the remote
- **Debug applications** running on the remote
-**Install extensions** that run on the remote
- **Access Git repositories** on the remote

### How It Works

1. Local VS Code connects to remote host via SSH
2. VS Code Server is installed automatically on the remote
3. Your local VS Code UI communicates with the remote server
4. All file operations and commands run on the remote

---

## Prerequisites

### Local Machine

- **VS Code** installed ([Download](https://code.visualstudio.com/))
- **SSH client** installed:
  - macOS/Linux: Included by default
  - Windows 10+: OpenSSH Client (Settings → Apps → Optional Features)
  - Older Windows: Install [Git for Windows](https://git-scm.com/download/win)

### Remote Machine

- **SSH server** running
- **SSH key-based authentication** configured
- **Internet connection** (for initial VS Code Server installation)
- **Supported OS**: Linux, macOS, or Windows with SSH server

### This Project

- **Docker container** running, OR
- **AWS EC2 instance** with tmux and emacs installed

---

## Installation

### Step 1: Install Remote-SSH Extension

**Method A: Via Extensions View**

1. Open VS Code
2. Click Extensions icon in sidebar (or press `Ctrl+Shift+X` / `Cmd+Shift+X`)
3. Search for "Remote - SSH"
4. Click **Install** on "Remote - SSH" by Microsoft
5. Optionally install "Remote - SSH: Editing Configuration Files" for better config editing

**Method B: Via Command Palette**

1. Press `Ctrl+Shift+P` / `Cmd+Shift+P`
2. Type "Install Extensions"
3. Search for "Remote - SSH"
4. Install

**Method C: Via Command Line**

```bash
code --install-extension ms-vscode-remote.remote-ssh
```

### Step 2: Verify Installation

1. Press `Ctrl+Shift+P` / `Cmd+Shift+P`
2. Type "Remote-SSH"
3. You should see commands like "Remote-SSH: Connect to Host"

---

## Configuration

### Step 1: Create/Edit SSH Config

The SSH config file tells VS Code how to connect to your remote hosts.

**Open SSH config:**

1. Press `Ctrl+Shift+P` / `Cmd+Shift+P`
2. Type "Remote-SSH: Open SSH Configuration File"
3. Select your SSH config file (usually first option: `~/.ssh/config`)

If the file doesn't exist, create it:

```bash
# macOS/Linux
touch ~/.ssh/config
chmod 600 ~/.ssh/config
```

```powershell
# Windows PowerShell
New-Item -ItemType File -Force -Path C:\Users\$env:USERNAME\.ssh\config
```

### Step 2: Add Host Configurations

#### For Docker Container (Local Testing)

Add to `~/.ssh/config`:

```
Host tmux-demo-docker
    HostName localhost
    User developer
    Port 2222
    IdentityFile ~/.ssh/tmux_demo_key
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null
```

**Parameters explained:**
- `Host tmux-demo-docker`: Friendly name (appears in VS Code)
- `HostName localhost`: Connect to local Docker container
- `User developer`: Username created in Dockerfile
- `Port 2222`: Docker container's mapped SSH port
- `IdentityFile`: Path to your private SSH key
- `StrictHostKeyChecking no`: Don't warn about host key changes (container may be recreated)
- `UserKnownHostsFile=/dev/null`: Don't save host key (useful for containers)

#### For AWS EC2 Instance

Add to `~/.ssh/config`:

```
Host tmux-aws
    HostName ec2-xx-xxx-xxx-xxx.compute-1.amazonaws.com
    User ubuntu
    Port 22
    IdentityFile ~/.ssh/aws-key.pem
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

**Additional parameters:**
- `ServerAliveInterval 60`: Send keepalive every 60 seconds
- `ServerAliveCountMax 3`: Disconnect after 3 failed keepalives

#### Advanced: Multiple Environments

```
# Local Docker for testing
Host dev-local
    HostName localhost
    User developer
    Port 2222
    IdentityFile ~/.ssh/tmux_demo_key
    StrictHostKeyChecking no

# AWS Development Environment
Host dev-aws
    HostName ec2-dev.compute-1.amazonaws.com
    User ubuntu
    Port 22
    IdentityFile ~/.ssh/aws-dev-key.pem
    ServerAliveInterval 60

# AWS Production Environment
Host prod-aws
    HostName ec2-prod.compute-1.amazonaws.com
    User ubuntu
    Port 22
    IdentityFile ~/.ssh/aws-prod-key.pem
    ServerAliveInterval 60
    # Require explicit confirmation for production
    RequestTTY yes
```

---

## Connecting

### Method 1: Connect via Command Palette

1. Press `Ctrl+Shift+P` / `Cmd+Shift+P`
2. Type "Remote-SSH: Connect to Host"
3. Select your host (e.g., `tmux-demo-docker` or `tmux-aws`)
4. New VS Code window opens
5. **First connection only**: VS Code Server installs automatically (wait 1-2 minutes)
6. Bottom-left corner shows "SSH: hostname" when connected

### Method 2: Connect via Remote Explorer

1. Click **Remote Explorer** icon in sidebar
2. Expand "SSH Targets"
3. Right-click on your host
4. Select "Connect to Host in Current Window" or "Connect to Host in New Window"

### Method 3: Quick Connect

1. Click green "Open Remote Window" button in bottom-left corner
2. Select "Connect to Host"
3. Choose your host

---

## Working Remotely

### Opening Folders and Files

**Open a folder:**

1. File → Open Folder (or `Ctrl+K Ctrl+O`)
2. Navigate to folder on remote machine
3. Click "OK"

**Open workspace:**

Same as opening folder, but select a `.code-workspace` file

### Integrated Terminal

**Open terminal:**

- Press `` Ctrl+` `` (backtick)
- Or: Terminal → New Terminal
- Or: `Ctrl+Shift+P` → "Terminal: Create New Terminal"

**Terminal automatically connects to remote machine!**

```bash
# You're now on the remote host
pwd
# /home/developer (Docker) or /home/ubuntu (EC2)

# Start tmux
tmux

# Prefix is Ctrl+^
```

### File Explorer

The file explorer shows **remote files**:

- Create, delete, rename files
- Drag and drop to/from local machine
- Right-click for context menu
- Search across remote files

### Extensions

**Installing extensions:**

Some extensions run locally, others run remotely:

- **Remote extensions**: Installed on the remote (e.g., Python, GitLens)
- **UI extensions**: Run locally (e.g., themes)

**To install on remote:**

1. Open Extensions view (`Ctrl+Shift+X`)
2. Extensions show "Install in SSH: hostname"
3. Click "Install in SSH: hostname"

**Recommended extensions for remote:**

- **Python** (if working with Python)
- **GitLens** (enhanced Git features)
- **Docker** (if managing containers remotely)
- **ESLint/Prettier** (for JavaScript/TypeScript)

### Git Integration

Git works on remote repositories:

- Source Control view shows remote repo status
- Commit, push, pull from VS Code
- View diffs and history
- Works with any Git repository on the remote

### Debugging

Debug code running on the remote:

1. Open a file on remote
2. Set breakpoints
3. F5 to start debugging
4. Debugger connects to remote process

---

## tmux Integration

### Option 1: Manual Usage

After connecting via Remote-SSH:

```bash
# Open integrated terminal
# Press Ctrl+`

# Start tmux
tmux

# Or attach to existing session
tmux attach -t my-session
```

Use tmux as normal with `Ctrl+^` prefix.

### Option 2: Auto-Attach to tmux

Configure VS Code to automatically start tmux when opening a terminal.

**Edit remote settings.json:**

1. Press `Ctrl+Shift+P`
2. Type "Preferences: Open Remote Settings (SSH: hostname)"
3. Add:

```json
{
  "terminal.integrated.profiles.linux": {
    "tmux": {
      "path": "tmux",
      "args": ["new-session", "-A", "-s", "vscode"]
    }
  },
  "terminal.integrated.defaultProfile.linux": "tmux"
}
```

Now terminals automatically attach to tmux session "vscode"!

### Option 3: Persistent Shell Profile

Add to remote `~/.bashrc` or `~/.zshrc`:

```bash
# Auto-attach to tmux if not already in tmux and not in VS Code terminal
if command -v tmux &> /dev/null && [ -z "$TMUX" ] && [ -z "$VSCODE_IPC_HOOK_CLI" ]; then
    tmux attach -t vscode || tmux new -s vscode
fi
```

**Note**: `VSCODE_IPC_HOOK_CLI` check prevents auto-attach in VS Code terminals

### Keybinding Conflicts

**Potential conflicts:**

- `Ctrl+^` may be captured by VS Code
- Some tmux shortcuts may not work

**Solutions:**

1. **Use tmux from regular SSH**: For heavy tmux usage, connect via regular SSH client
2. **Remap VS Code keys**: Modify VS Code keybindings to avoid conflicts
3. **Use tmux mouse mode**: Enabled in our `.tmux.conf`

**Example keybinding remapping** (`keybindings.json`):

```json
[
  {
    "key": "ctrl+shift+^",
    "command": "workbench.action.terminal.sendSequence",
    "args": { "text": "\u001e" },
    "when": "terminalFocus"
  }
]
```

---

## Troubleshooting

### Connection Fails

**Symptoms:**
```
Could not establish connection to "hostname".
The process tried to write to a pipe that has been closed.
```

**Solutions:**

1. **Test SSH connection manually:**
   ```bash
   ssh -v hostname
   ```
   Look for errors in verbose output

2. **Check SSH config:**
   - Verify HostName, User, Port, IdentityFile are correct
   - Test with `ssh -F ~/.ssh/config hostname`

3. **Check key permissions:**
   ```bash
   chmod 600 ~/.ssh/your-key
   ```

4. **For Docker**: Ensure container is running
   ```bash
   docker ps
   ```

5. **For EC2**: Check Security Group allows SSH from your IP

### VS Code Server Installation Fails

**Symptoms:**
```
Failed to install VS Code Server
```

**Solutions:**

1. **Check disk space on remote:**
   ```bash
   df -h ~
   ```
   Need at least 1GB free

2. **Manual cleanup:**
   ```bash
   rm -rf ~/.vscode-server
   ```
   Then reconnect

3. **Check internet on remote:**
   ```bash
   curl -I https://update.code.visualstudio.com
   ```

4. **Firewall blocking download:**
   - Check corporate firewall
   - Try from different network

### Connection Drops/Timeouts

**Symptoms:**
Connection works but drops after inactivity

**Solutions:**

1. **Add keepalive to SSH config:**
   ```
   Host myserver
       ServerAliveInterval 60
       ServerAliveCountMax 3
   ```

2. **For unstable connections**, use tmux:
   - Work survives disconnections
   - Reconnect and reattach to session

3. **Adjust VS Code timeout settings:**
   ```json
   {
     "remote.SSH.connectTimeout": 60
   }
   ```

### Permission Denied

**Symptoms:**
```
Permission denied (publickey).
```

**Solutions:**

See [SSH Setup Guide - Troubleshooting](ssh-setup.md#troubleshooting)

1. Verify key permissions
2. Check public key is in remote `~/.ssh/authorized_keys`
3. Test SSH connection manually

### Extensions Not Working

**Symptoms:**
Extension installed but not functioning

**Solutions:**

1. **Install on remote**, not locally:
   - Look for "Install in SSH: hostname" button
   - Some extensions only work remotely

2. **Reload window:**
   - `Ctrl+Shift+P` → "Developer: Reload Window"

3. **Check extension compatibility:**
   - Not all extensions support remote
   - Check extension page for "Remote" badge

### File Watcher Limit (Linux)

**Symptoms:**
```
Visual Studio Code is unable to watch for file changes in this large workspace
```

**Solution:**

Increase inotify limit on remote:

```bash
# Temporary
sudo sysctl fs.inotify.max_user_watches=524288

# Permanent
echo "fs.inotify.max_user_watches=524288" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

### Slow Performance

**Symptoms:**
Typing lag, slow file operations

**Solutions:**

1. **Reduce file watchers:**
   ```json
   {
     "files.watcherExclude": {
       "**/.git/objects/**": true,
       "**/node_modules/**": true,
       "**/dist/**": true
     }
   }
   ```

2. **Disable extensions you don't need:**
   - Disable locally or remotely via Extensions view

3. **Close unused terminals:**
   - Each terminal uses resources

4. **For EC2**: Consider larger instance type

---

## Tips and Best Practices

### 1. Use Workspaces

Save workspace configuration:

```json
// .code-workspace file
{
  "folders": [
    {
      "path": "/home/developer/project1"
    },
    {
      "path": "/home/developer/project2"
    }
  ],
  "settings": {
    "terminal.integrated.defaultProfile.linux": "tmux"
  }
}
```

### 2. Remote Settings vs Local Settings

- **User Settings**: Apply everywhere
- **Remote Settings**: Only for this connection
- **Workspace Settings**: Only for this workspace

Access via: `Ctrl+Shift+P` → "Preferences: Open Remote Settings"

### 3. Port Forwarding

Forward ports from remote to local:

```bash
# In VS Code terminal
# Forward remote port 8080 to local 8080
```

Or: Terminal → Ports panel → "Forward a Port"

### 4. Multiple Connections

Work on multiple remote machines simultaneously:

- Each connection opens a new window
- Windows are independent
- Can connect to different hosts

### 5. Sync Settings

Install **Settings Sync** to sync configuration across machines

### 6. Use SSH Agent

Avoid typing passphrase repeatedly:

```bash
# Start SSH agent
eval "$(ssh-agent -s)"

# Add key
ssh-add ~/.ssh/tmux_demo_key

# Keys persist until logout
```

---

## Quick Reference

### Connection

| Action | Command |
| -------- | --------- |
| Connect to host | `Ctrl+Shift+P` → "Remote-SSH: Connect to Host" |
| Disconnect | Click "SSH: hostname" → "Close Remote Connection" |
| Reload window | `Ctrl+Shift+P` → "Developer: Reload Window" |

### Terminal

| Action | Command |
| -------- | --------- |
| New terminal | `` Ctrl+Shift+` `` or `` Ctrl+` `` |
| Kill terminal | `Ctrl+Shift+P` → "Terminal: Kill Active Terminal" |
| Start tmux | `tmux` |
| Attach to tmux | `tmux attach -t vscode` |

### Files

| Action | Command |
| -------- | --------- |
| Open folder | `Ctrl+K Ctrl+O` |
| Quick open file | `Ctrl+P` |
| Search in files | `Ctrl+Shift+F` |

---

## Further Reading

- [Official VS Code Remote-SSH docs](https://code.visualstudio.com/docs/remote/ssh)
- [SSH Config file reference](https://man.openbsd.org/ssh_config)
- [tmux Integration Guide](../README.md#section-5-vs-code-terminal-tmux-integration)

**Next Steps:**
- [Windows PSMUX Guide](psmux-guide.md)
- [SSH Setup](ssh-setup.md)
- [Back to README](../README.md)
