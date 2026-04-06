# tmux + emacs Development Environment

[日本語版はこちら / Japanese version](README.ja.md)

Setup guide for remote AWS development with tmux, emacs, and VS Code Remote-SSH.
Optimized for GPU-heavy ML training tasks on AWS EC2.

Includes emacs-friendly tmux configuration (Ctrl+^ prefix) for persistent terminal sessions.

> **New to tmux?** Start with the [**Usage Guide**](docs/USAGE.md) to understand sessions, windows, and recommended workflows.
>
> **Note**: For local testing without AWS access, see [Docker Setup Guide](docs/docker-setup.md).

---

## Table of Contents

1. [AWS EC2 Setup](#section-1-aws-ec2-setup)
2. [VS Code Remote-SSH](#section-2-vs-code-remote-ssh)
3. [Windows PSMUX Tmux Client](#section-3-windows-psmux-tmux-client)
4. [VS Code Terminal + tmux Integration](#section-4-vs-code-terminal--tmux-integration-optional)

---

## Section 1: AWS EC2 Setup

Set up your AWS EC2 instance for remote development with tmux and emacs.

### Prerequisites

- AWS EC2 instance running Linux (optimized for Ubuntu/Debian)
- SSH access to your instance
- SSH key pair (see [docs/ssh-setup.md](docs/ssh-setup.md))

### Step-by-Step Setup

#### 1. Connect to Your Instance

```bash
ssh -i ~/.ssh/your-aws-key.pem <your-username>@<your-ec2-hostname>
```

#### 2. Install tmux and emacs

**Option A: Use the installation script** (recommended):

```bash
# Clone this repository
git clone https://github.com/BobKerns/tmux-demo.git
cd tmux-demo

# Run the installation script
./scripts/install-tmux-emacs.sh
```

**Option B: Manual installation**:

```bash
# Update package list
sudo apt-get update

# Install tmux, emacs, and essential tools
sudo apt-get install -y tmux emacs-nox git curl wget vim build-essential

# Verify installation
tmux -V
emacs --version
```

#### 3. Set Up tmux Configuration

```bash
# Download the emacs-friendly tmux configuration
wget https://raw.githubusercontent.com/BobKerns/tmux-demo/main/.tmux.conf -O ~/.tmux.conf

# Or copy from the cloned repository
cp ~/tmux-demo/.tmux.conf ~/.tmux.conf
```

#### 4. Test tmux

```bash
# Start a new tmux session
tmux

# Test the prefix key (Ctrl+^)
# Try creating a new window: Ctrl+^ then c
```

**Remember**: The prefix key is **Ctrl+^** (not Ctrl+b)!

---

## Section 2: VS Code Remote-SSH

Connect VS Code to your AWS EC2 remote environment.

### Installation

1. **Install VS Code** ([download](https://code.visualstudio.com/))

2. **Install Remote-SSH Extension**:
   - Open VS Code
   - Press `Ctrl+Shift+X` (or `Cmd+Shift+X` on macOS)
   - Search for "Remote - SSH"
   - Click Install on the extension by Microsoft

### Configuration

#### AWS EC2

1. **Open SSH config file**:
   - Press `Ctrl+Shift+P` → "Remote-SSH: Open SSH Configuration File"
   - Select your SSH config (usually `~/.ssh/config`)

2. **Add configuration**:
   ```
   Host aws-ml
       HostName <your-ec2-hostname>
       User <your-username>
       Port 22
       IdentityFile ~/.ssh/your-aws-key.pem
   ```

3. **Connect**:
   - Press `Ctrl+Shift+P` → "Remote-SSH: Connect to Host"
   - Select `aws-ml`
   - First connection will install VS Code Server

### Using Remote-SSH

Once connected:

- **File Explorer**: Browse remote files in the sidebar
- **Terminal**: Opens on the remote machine (press `` Ctrl+` ``)
- **Extensions**: Install extensions on the remote (some need remote installation)
- **Git**: Works with repositories on the remote machine
- **Debugging**: Debug code running on the remote

### Common Tasks

| Task | Command |
| ------ | --------- |
| Open remote folder | `Ctrl+K Ctrl+O` → Select folder |
| New terminal | `` Ctrl+Shift+` `` |
| Close remote connection | Click "SSH: hostname" in bottom-left → "Close Remote Connection" |
| Reload window | `Ctrl+Shift+P` → "Developer: Reload Window" |

---

## Section 3: Windows PSMUX Tmux Client

PSMUX is a modern tmux client for Windows that provides a native experience.

### Installation

1. **Install PSMUX**:
   - Visit [PSMUX GitHub releases](https://github.com/lupont/psmux) (example URL)
   - Download the latest `.exe` or `.msi` installer for Windows
   - Run the installer and follow the prompts

2. **Verify Installation**:
   ```powershell
   psmux --version
   ```

### Connecting to Remote tmux

#### Connect to AWS EC2

```powershell
# Replace with your EC2 instance details
psmux connect -h <your-ec2-hostname> -p 22 -u <your-username> -i C:\Users\YourName\.ssh\aws-key.pem
```

### Basic tmux Commands (via PSMUX)

Remember: The prefix is **Ctrl+^** (not Ctrl+b)

| Command | Description |
| --------- | ------------- |
| `Ctrl+^ c` | Create new window |
| `Ctrl+^ \|` | Split pane horizontally |
| `Ctrl+^ -` | Split pane vertically |
| `Ctrl+^ arrow` | Navigate between panes |
| `Ctrl+^ d` | Detach from session |
| `Ctrl+^ [` | Enter scroll mode (arrow keys to scroll, `q` to exit) |

### PSMUX-Specific Features

- **Native Windows Integration**: Copy/paste works with Windows clipboard
- **Mouse Support**: Full mouse support (click to select panes, scroll to navigate)
- **Session Management**: GUI for managing multiple tmux sessions
- **Font Rendering**: Better font rendering than traditional terminal emulators

### Creating a Session Profile

PSMUX can save connection profiles for quick access to your AWS environments.

For detailed PSMUX usage, see [docs/psmux-guide.md](docs/psmux-guide.md).

---

## Section 4: VS Code Terminal + tmux Integration (Optional)

**Note**: This is an optional advanced feature, separate from basic Remote-SSH usage.

### Overview

You can configure VS Code's integrated terminal to automatically work with tmux for:

- **Persistent sessions**: Your terminal work survives VS Code disconnections
- **Terminal multiplexing**: Multiple panes within VS Code terminal
- **Network resilience**: Continue work even after connection drops

### Quick Example

Simplest approach - just run tmux manually in VS Code's terminal:

1. Connect to your remote host via Remote-SSH
2. Open VS Code terminal (`` Ctrl+` ``)
3. Run `tmux` to start a session
4. Use prefix `Ctrl+^` to control tmux

### When to Use This

✅ **Good for**:
- Long-running processes that need to survive disconnections
- Complex multi-pane terminal setups
- Unstable network connections

❌ **Not needed for**:
- Basic Remote-SSH development
- Simple terminal usage
- If you rarely disconnect

### Complete Guide

For detailed setup with automatic attachment, shell profile integration, and troubleshooting:

**📚 See the complete guide:** [VS Code tmux Integration](docs/vscode-tmux-integration.md) ([Japanese](docs/vscode-tmux-integration.ja.md))

---

## Quick Reference

### tmux Essentials (Prefix: Ctrl+^)

| Command | Description |
| --------- | ------------- |
| `tmux` | Start new session |
| `tmux ls` | List sessions |
| `tmux attach -t <name>` | Attach to session |
| `Ctrl+^ c` | New window |
| `Ctrl+^ \|` | Split horizontal |
| `Ctrl+^ -` | Split vertical |
| `Ctrl+^ d` | Detach session |
| `Ctrl+^ [` | Scroll mode |

### Useful Commands

```bash
# Test connection
./scripts/test-connection.sh <host> <port> <key> <user>

# Setup SSH keys
./scripts/setup-ssh.sh ~/.ssh/your_key.pub

# Install on fresh Ubuntu (AWS EC2)
./scripts/install-tmux-emacs.sh
```

---

## Contributing

Contributions welcome! Please feel free to submit a Pull Request.

---

## License

MIT License - See [LICENSE](LICENSE) file for details

---

## Additional Resources

### Documentation

- [**tmux Usage Guide**](docs/USAGE.md) - Essential guide to sessions, windows, and workflows ⭐
- [SSH Setup Guide](docs/ssh-setup.md) - Generate and configure SSH keys
- [VS Code Remote-SSH Guide](docs/vscode-remote-ssh.md) - Detailed Remote-SSH setup
- [VS Code Troubleshooting](docs/vscode-troubleshooting.md) - Common issues and solutions
- [Docker Setup Guide](docs/docker-setup.md) - Local testing environment (optional)

### External Resources

- [tmux Cheat Sheet](https://tmuxcheatsheet.com/)
- [emacs Tutorial](https://www.gnu.org/software/emacs/tour/)
- [VS Code Remote Development](https://code.visualstudio.com/docs/remote/remote-overview)
- [AWS EC2 User Guide](https://docs.aws.amazon.com/ec2/)

---

**Questions or Issues?** Open an issue on GitHub or consult the detailed guides in the `docs/` directory.
