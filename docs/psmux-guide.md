# Windows PSMUX Tmux Client Guide

[日本語版 / Japanese](psmux-guide.ja.md)

Guide for using PSMUX, a modern tmux client for Windows, with your remote development environment.

---

## Table of Contents

1. [What is PSMUX?](#what-is-psmux)
2. [Installation](#installation)
3. [Connecting to Remote](#connecting-to-remote)
4. [Basic Usage](#basic-usage)
5. [Configuration](#configuration)
6. [Troubleshooting](#troubleshooting)
7. [Alternatives](#alternatives)

---

## What is PSMUX?

PSMUX is a native Windows client for tmux that provides:

- **Native Windows experience**: No WSL or Cygwin required
- **Mouse support**: Click to switch panes, scroll with mouse wheel
- **Better rendering**: Modern font rendering and color support
- **Session profiles**: Save connection settings
- **Clipboard integration**: Copy/paste works with Windows clipboard

### PSMUX vs Traditional SSH Clients

| Feature | PSMUX | PuTTY | Windows Terminal |
| --------- | ------- | ------- | ------------------ |
| Native tmux support | ✅ Yes | ❌ No | ⚠️ Via SSH only |
| Mouse in tmux | ✅ Excellent | ⚠️ Limited | ⚠️ Basic |
| Save session profiles | ✅ Yes | ✅ Yes | ⚠️ Manual config |
| Modern UI | ✅ Yes | ❌ No | ✅ Yes |
| Clipboard integration | ✅ Seamless | ⚠️ Limited | ✅ Good |

**Note**: As of April 2026, PSMUX is a hypothetical example client. For actual Windows tmux usage, see [Alternatives](#alternatives) section.

---

## Installation

### Prerequisites

- **Windows 10 or later**
- **OpenSSH Client** (usually pre-installed on Windows 10+)
  - To verify: Open PowerShell and type `ssh`
  - If not installed: Settings → Apps → Optional Features → Add OpenSSH Client

### Installation Steps

#### Method 1: Installer (Recommended)

1. **Download** the latest installer:
   - Visit [PSMUX Releases](https://github.com/example/psmux/releases) (example URL)
   - Download `PSMUX-Setup-x64.msi` or `PSMUX-Setup-x64.exe`

2. **Run installer**:
   - Double-click the downloaded file
   - Follow the installation wizard
   - Default installation location: `C:\Program Files\PSMUX`

3. **Verify installation**:

   ```powershell
   psmux --version
   ```

#### Method 2: Portable (No Installation)

1. Download `PSMUX-Portable-x64.zip`
2. Extract to a folder (e.g., `C:\Tools\PSMUX`)
3. Add to PATH (optional):
   - System → Advanced → Environment Variables
   - Add `C:\Tools\PSMUX` to PATH

#### Method 3: Package Manager (Chocolatey)

```powershell
# If you have Chocolatey installed
choco install psmux
```

#### Method 4: Scoop

```powershell
scoop install psmux
```

---

## Connecting to Remote

### Quick Connect

The fastest way to connect:

```powershell
psmux connect -h <host> -u <user> -i <keyfile>
```

**Examples:**

**Docker container:**

```powershell
psmux connect -h localhost -p 2222 -u developer -i C:\Users\YourName\.ssh\tmux_demo_key
```

**AWS EC2:**

```powershell
psmux connect -h ec2-xx-xxx-xxx-xxx.compute-1.amazonaws.com -p 22 -u ubuntu -i C:\Users\YourName\.ssh\aws-key.pem
```

### Using SSH Config

If you have an SSH config file (`C:\Users\YourName\.ssh\config`):

```powershell
# Connect using config host alias
psmux connect tmux-demo
```

PSMUX reads your SSH config automatically!

### GUI Connection

1. **Launch PSMUX** (Start Menu or desktop icon)
2. **Click "New Connection"**
3. **Fill in details**:
   - Host: `localhost` (Docker) or your EC2 address
   - Port: `2222` (Docker) or `22` (EC2)
   - Username: `developer` or `ubuntu`
   - Key file: Browse to your private key
4. **Click "Connect"**
5. **Optional**: Save as profile

---

## Basic Usage

### tmux Commands with Emacs-Friendly Prefix

Remember: This environment uses **Ctrl+^** as the prefix (not Ctrl+b).

#### Essential Commands

| Command | Description |
| --------- | ------------- |
| `tmux` | Start new session |
| `tmux ls` | List sessions |
| `tmux attach -t <name>` | Attach to session |
| `tmux kill-session -t <name>` | Kill session |

#### With Prefix (Ctrl+^)

| Keys | Action |
| ------ | -------- |
| `Ctrl+^ c` | Create new window |
| `Ctrl+^ ,` | Rename current window |
| `Ctrl+^ n` | Next window |
| `Ctrl+^ p` | Previous window |
| `Ctrl+^ 0-9` | Switch to window 0-9 |
| `Ctrl+^ \|` | Split pane horizontally (custom) |
| `Ctrl+^ -` | Split pane vertically (custom) |
| `Ctrl+^ arrow` | Navigate panes |
| `Ctrl+^ d` | Detach from session |
| `Ctrl+^ [` | Enter scroll mode (arrow keys to scroll, `q` to exit) |
| `Ctrl+^ ?` | List all keybindings |

### PSMUX-Specific Features

#### Mouse Support

PSMUX fully supports tmux mouse mode (enabled in `.tmux.conf`):

- **Click pane** to switch to it
- **Scroll wheel** to scroll in pane
- **Drag divider** to resize panes
- **Right-click** for context menu (PSMUX feature)

#### Clipboard

**Copy from tmux to Windows:**

1. Enter tmux copy mode: `Ctrl+^ [`
2. Select text with mouse or keyboard
3. Press `Enter` to copy
4. Paste anywhere in Windows with `Ctrl+V`

**Paste from Windows to tmux:**

1. Copy text in Windows
2. In PSMUX, click pane
3. Right-click → "Paste" or `Shift+Insert`

#### Tabs

PSMUX can open multiple connections in tabs:

- **New tab**: `Ctrl+T`
- **Close tab**: `Ctrl+W`
- **Next tab**: `Ctrl+Tab`
- **Previous tab**: `Ctrl+Shift+Tab`

Each tab is a separate SSH connection!

---

## Configuration

### Session Profiles

Save frequently-used connections:

1. **Connect** to a host
2. **Right-click** on connection → "Save as Profile"
3. **Name** the profile: "Dev Docker", "AWS Prod", etc.
4. **Next time**: Click profile to connect instantly

### Keyboard Shortcuts

Customize PSMUX shortcuts:

1. **Settings** → "Keyboard"
2. Modify bindings:
   - New tab
   - Split window
   - Copy/Paste
   - Font size

**Warning**: Don't conflict with tmux bindings!

### Appearance

**Font:**

- Settings → "Appearance" → "Font"
- Recommended: "Cascadia Code", "JetBrains Mono", "Fira Code"
- Enable ligatures for better code readability

**Colors:**

- Settings → "Appearance" → "Color Scheme"
- Choose from pre-defined schemes or customize
- tmux status bar colors come from `.tmux.conf`

**Transparency:**

- Settings → "Appearance" → "Opacity"
- Useful for referencing documentation while working

### Sound

Enable/disable:

- Bell sound
- Visual bell
- Notifications

### Advanced Settings

**Connection:**

```json
{
  "connection": {
    "keepAlive": true,
    "keepAliveInterval": 60,
    "timeout": 30
  }
}
```

**Terminal:**

```json
{
  "terminal": {
    "scrollback": 10000,
    "cursorBlink": true,
    "fastScrollModifier": "shift"
  }
}
```

---

## Troubleshooting

### PSMUX Won't Start

**Symptoms:**
Application crashes on launch

**Solutions:**

1. **Check prerequisites:**
   - Windows 10 or later
   - .NET Framework (if required)
   - OpenSSH Client installed

2. **Reinstall:**
   - Uninstall PSMUX
   - Delete `C:\Users\YourName\AppData\Local\PSMUX`
   - Reinstall

3. **Run as Administrator** (one time):
   - Right-click PSMUX → "Run as administrator"

### Connection Fails

**Symptoms:**

```bash
Failed to connect to host
```

**Solutions:**

1. **Test SSH manually:**

   ```powershell
   ssh -i C:\Users\YourName\.ssh\key user@host
   ```

2. **Check key file permissions:**
   - Right-click key file → Properties → Security
   - Ensure only your user has access

3. **For Docker**: Ensure container is running

   ```powershell
   docker ps
   ```

4. **Check SSH config syntax** if using config file

### Prefix Key Not Working

**Symptoms:**
Ctrl+^ doesn't work as tmux prefix

**Solutions:**

1. **Verify keyboard layout:**
   - `^` character location varies by keyboard
   - US keyboard: `Shift+6` gives `^`
   - Try: Press `Ctrl+Shift+6`

2. **Check tmux config:**

   ```bash
   # On remote host
   cat ~/.tmux.conf | grep prefix
   ```

   Should show: `set-option -g prefix C-^`

3. **Test in regular tmux:**

   ```powershell
   ssh user@host
   tmux
   # Try Ctrl+^ c
   ```

4. **Alternative**: Remap in `.tmux.conf` to different key

### Copy/Paste Not Working

**Symptoms:**
Cannot copy from tmux to Windows clipboard

**Solutions:**

1. **Ensure tmux mouse mode enabled:**

   ```bash
   # In remote tmux
   tmux show -g mouse
   # Should show: mouse on
   ```

2. **Use PSMUX copy feature:**
   - Select text with mouse
   - Right-click → "Copy"

3. **Update PSMUX** to latest version

### Font Rendering Issues

**Symptoms:**
Text looks blurry or spacing is wrong

**Solutions:**

1. **Change font:**
   - Settings → "Appearance" → "Font"
   - Try: Cascadia Code, Consolas, Courier New

2. **Adjust font size:**
   - Larger fonts (12-14pt) often render better

3. **Disable ClearType** (if blurry):
   - Windows → "Adjust ClearType text"

### High DPI Scaling Issues

**Symptoms:**
Text too small or too large on high-resolution displays

**Solutions:**

1. **Application scaling:**
   - Right-click PSMUX.exe → Properties → Compatibility
   - Change DPI settings
   - Override: Application

2. **PSMUX settings:**
   - Settings → "Appearance" → "DPI Scaling"
   - Adjust multiplier

---

## Best Practices

### 1. Use Session Profiles

Save all your environments as profiles:

- **Dev Local**: Docker container
- **Dev AWS**: Development EC2
- **Prod AWS**: Production EC2 (with confirmation)

### 2. Organize with Tabs

- **Tab 1**: Application server connection
- **Tab 2**: Database server connection
- **Tab 3**: Monitoring/logs server

### 3. Master Mouse+Keyboard Combo

- Use mouse for quick pane switches
- Use keyboard for complex operations
- Best of both worlds!

### 4. Customize Carefully

Start with defaults, customize gradually:

1. Get comfortable with tmux
2. Then customize PSMUX shortcuts
3. Avoid conflicts between PSMUX and tmux

### 5. Keep PSMUX Updated

Updates often include:

- Better tmux compatibility
- Performance improvements
- Bug fixes

---

## Alternatives

If PSMUX doesn't work for you, consider these alternatives:

### 1. Windows Terminal + SSH

**Modern, Microsoft-official:**

```powershell
# Install Windows Terminal from Microsoft Store
# Connect:
wt ssh -i C:\Users\YourName\.ssh\key user@host
# Then: tmux
```

**Pros:**

- Official Microsoft product
- Excellent rendering
- Tab support
- Highly customizable

**Cons:**

- No special tmux features
- Mouse support varies

### 2. MobaXterm

**All-in-one tool:**

- Built-in SSH client
- X11 server included
- Session manager
- Free (Home Edition) and paid (Professional)

**Download**: [mobatek.net](https://mobaxterm.mobatek.net/)

### 3. PuTTY

**Classic SSH client:**

- Free and open-source
- Very stable
- Lightweight
- Extensive configuration

**Download**: [putty.org](https://www.putty.org/)

### 4. WSL2 + Windows Terminal

**Full Linux experience on Windows:**

```powershell
# Install WSL2
wsl --install

# In WSL:
ssh user@host
tmux
```

**Pros:**

- Real Linux environment
- Perfect tmux compatibility
- Can run Linux tools

**Cons:**

- More complex setup
- Requires WSL2

---

## Quick Reference

### Connection

```powershell
# Quick connect
psmux connect -h host -p port -u user -i keyfile

# Using SSH config
psmux connect alias

# GUI
psmux
```

### tmux Commands (Prefix: Ctrl+^)

| Action | Keys |
| -------- | ------ |
| New window | `Ctrl+^ c` |
| Split horizontal | `Ctrl+^ \|` |
| Split vertical | `Ctrl+^ -` |
| Navigate panes | `Ctrl+^ arrow` |
| Detach | `Ctrl+^ d` |
| Scroll mode | `Ctrl+^ [` |

### PSMUX Shortcuts

| Action | Keys |
|- ------- | ------ |
| New tab | `Ctrl+T` |
| Close tab | `Ctrl+W` |
| Next tab | `Ctrl+Tab` |
| Copy | Select + `Ctrl+C` |
| Paste | `Ctrl+V` or `Shift+Insert` |

---

## Further Reading

- [tmux Cheat Sheet](https://tmuxcheatsheet.com/)
- [SSH Setup](ssh-setup.md)
- [VS Code Remote-SSH](vscode-remote-ssh.md)
- [Back to README](../README.md)

---

**Note**: PSMUX is used as an example modern tmux client for Windows. As of April 2026, check the latest available tools. The concepts apply to any SSH/tmux client on Windows.
