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
7. [Tips and Best Practices](#tips-and-best-practices)
8. [Next Steps](#next-steps)

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

**Recommended extensions for Python development:**

- **Python** (by Microsoft) - IntelliSense, linting, debugging, code formatting
- **Pylance** (by Microsoft) - Fast, feature-rich language support for Python
- **Python Debugger** (by Microsoft) - Debugging support
- **GitLens** (by GitKraken) - Enhanced Git features
- **autoDocstring** (by Nils Werner) - Generate Python docstrings automatically
- **Black Formatter** (by Microsoft) - Code formatting with Black

**Installing Python extensions:**

1. Open Extensions view (`Ctrl+Shift+X`)
2. Search for "Python"
3. Click "Install in SSH: hostname" for each extension
4. Reload window when prompted: `Ctrl+Shift+P` → "Developer: Reload Window"

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
- **Remote Settings**: Only for specific SSH connection
- **Workspace Settings**: Only for current workspace

Access via: `Ctrl+Shift+P` → "Preferences: Open Remote Settings"

### 3. Python Virtual Environments

VS Code automatically detects Python virtual environments:

```bash
# Create virtual environment on remote
python3 -m venv .venv

# VS Code will prompt to select this interpreter
# Or manually: Ctrl+Shift+P → "Python: Select Interpreter"
```

### 4. Port Forwarding

Forward ports from remote to local for web apps:

1. Start your application on remote (e.g., `python app.py` on port 8000)
2. VS Code detects the port automatically
3. Or manually: Terminal → Ports panel → "Forward a Port"
4. Access via `http://localhost:8000` on your local machine

### 5. Multiple Connections

Work on multiple remote machines simultaneously:

- Each connection opens a new window
- Windows are independent
- Can connect to different hosts

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

### Python

| Action | Command |
| -------- | --------- |
| Select interpreter | `Ctrl+Shift+P` → "Python: Select Interpreter" |
| Run Python file | `Ctrl+Shift+P` → "Python: Run Python File in Terminal" |
| Debug Python file | F5 |

### Files

| Action | Command |
| -------- | --------- |
| Open folder | `Ctrl+K Ctrl+O` |
| Quick open file | `Ctrl+P` |
| Search in files | `Ctrl+Shift+F` |

---

## Next Steps

### Optional Enhancements

- **[VS Code tmux Integration Guide](vscode-tmux-integration.md)** - Use tmux for persistent sessions (optional)
- **[Windows PSMUX Guide](psmux-guide.md)** - tmux client for Windows

### Troubleshooting

- **[VS Code Troubleshooting](vscode-troubleshooting.md)** - Common issues and solutions
- **[SSH Setup Guide](ssh-setup.md)** - SSH configuration and key troubleshooting

### Additional Resources

- [Official VS Code Remote-SSH docs](https://code.visualstudio.com/docs/remote/ssh)
- [SSH Config file reference](https://man.openbsd.org/ssh_config)
- [Python in VS Code](https://code.visualstudio.com/docs/python/python-tutorial)
- [Back to README](../README.md)
