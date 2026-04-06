# tmux + emacs Development Environment

[日本語版はこちら / Japanese version](README.ja.md)

Setup guide for Ubuntu, tmux, emacs, and VS Code Remote-SSH development environment.

Test locally with Docker, deploy to AWS EC2. Includes emacs-friendly tmux configuration (Ctrl+^ prefix).

---

## Table of Contents

1. [Docker Setup (Local Testing)](#section-1-docker-setup-local-testing)
2. [AWS EC2 Setup](#section-2-aws-ec2-setup)
3. [VS Code Remote-SSH](#section-3-vs-code-remote-ssh)
4. [Windows PSMUX Tmux Client](#section-4-windows-psmux-tmux-client)
5. [VS Code Terminal + tmux Integration](#section-5-vs-code-terminal--tmux-integration-optional)

---

## Section 1: Docker Setup (Local Testing)

Use Docker to test the environment locally before deploying to AWS.

### Prerequisites

- Docker installed on your system ([Get Docker](https://docs.docker.com/get-docker/))
- Docker Compose installed
- SSH key pair (see [docs/ssh-setup.md](docs/ssh-setup.md))

### Quick Start

1. **Clone this repository**:
   ```bash
   git clone https://github.com/your-repo/tmux-demo.git
   cd tmux-demo
   ```

2. **Build and start the container**:
   ```bash
   docker-compose up -d --build
   ```

   This creates a container named `tmux-demo` with:
   - SSH server on port 2222 (mapped from container port 22)
   - User `developer` with sudo privileges
   - Persistent home directory volume

3. **Set up SSH access**:

   First, generate an SSH key if you haven't already:
   ```bash
   ssh-keygen -t ed25519 -f ~/.ssh/tmux_demo_key -C "tmux-demo"
   ```

   Copy your public key into the container:
   ```bash
   docker exec tmux-demo bash -c "mkdir -p /home/developer/.ssh && chmod 700 /home/developer/.ssh"
   docker cp ~/.ssh/tmux_demo_key.pub tmux-demo:/tmp/key.pub
   docker exec -u developer tmux-demo bash -c "cat /tmp/key.pub >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
   ```

   Or use the setup script (from inside the container):
   ```bash
   docker exec -it tmux-demo bash
   ./scripts/setup-ssh.sh /path/to/your/public/key.pub
   ```

4. **Test the connection**:
   ```bash
   ssh -i ~/.ssh/tmux_demo_key -p 2222 developer@localhost
   ```

5. **Start tmux**:
   ```bash
   tmux
   ```

   Remember: The prefix key is **Ctrl+^** (not Ctrl+b)!

### Docker Commands

| Command | Description |
| --------- | ------------- |
| `docker-compose up -d` | Start container in background |
| `docker-compose down` | Stop and remove container |
| `docker-compose logs -f` | View container logs |
| `docker exec -it tmux-demo bash` | Open shell in container |
| `docker-compose restart` | Restart the container |

### Troubleshooting

**Cannot connect via SSH:**
- Check container is running: `docker ps`
- Verify port mapping: `docker port tmux-demo`
- Check SSH key permissions: `chmod 600 ~/.ssh/tmux_demo_key`
- View SSH logs: `docker logs tmux-demo`

**Tmux not working:**
- Verify installation: `docker exec tmux-demo tmux -V`
- Check configuration: `docker exec -u developer tmux-demo cat ~/.tmux.conf`

---

## Section 2: AWS EC2 Setup

Deploy to AWS EC2 for a production remote development environment.

### Prerequisites

- AWS account with EC2 access
- AWS CLI configured (optional, for CLI deployment)
- SSH key pair registered in AWS

### Step-by-Step Setup

#### 1. Install tmux and emacs

**Option A: Use the installation script** (recommended):

```bash
# Download the script
wget https://raw.githubusercontent.com/your-repo/tmux-demo/main/scripts/install-tmux-emacs.sh

# Make it executable
chmod +x install-tmux-emacs.sh

# Run it
./install-tmux-emacs.sh
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

#### 2. Set Up tmux Configuration

```bash
# Download the emacs-friendly tmux configuration
wget https://raw.githubusercontent.com/your-repo/tmux-demo/main/.tmux.conf -O ~/.tmux.conf

# Or create it manually (see .tmux.conf in this repo)
```


## Section 3: VS Code Remote-SSH

Connect VS Code to your remote environment (Docker or AWS EC2).

### Installation

1. **Install VS Code** ([download](https://code.visualstudio.com/))

2. **Install Remote-SSH Extension**:
   - Open VS Code
   - Press `Ctrl+Shift+X` (or `Cmd+Shift+X` on macOS)
   - Search for "Remote - SSH"
   - Click Install on the extension by Microsoft

### Configuration

#### For Docker (Local Testing)

1. **Open SSH config file**:
   - Press `Ctrl+Shift+P` → "Remote-SSH: Open SSH Configuration File"
   - Select your SSH config (usually `~/.ssh/config`)

2. **Add configuration**:
   ```
   Host tmux-demo-docker
       HostName localhost
       User developer
       Port 2222
       IdentityFile ~/.ssh/tmux_demo_key
   ```

3. **Connect**:
   - Press `Ctrl+Shift+P` → "Remote-SSH: Connect to Host"
   - Select `tmux-demo-docker`
   - First connection will install VS Code Server

#### For AWS EC2

1. **Add to SSH config**:
   ```
   Host tmux-aws
       HostName ec2-xx-xxx-xxx-xxx.compute-1.amazonaws.com
       User ubuntu
       Port 22
       IdentityFile ~/.ssh/your-aws-key.pem
   ```

2. **Connect**:
   - Press `Ctrl+Shift+P` → "Remote-SSH: Connect to Host"
   - Select `tmux-aws`

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

## Section 4: Windows PSMUX Tmux Client

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

#### Connect to Docker Container

```powershell
# Basic connection
psmux connect -h localhost -p 2222 -u developer -i C:\Users\YourName\.ssh\tmux_demo_key
```

#### Connect to AWS EC2

```powershell
# Replace with your EC2 instance details
psmux connect -h ec2-xx-xxx-xxx-xxx.compute-1.amazonaws.com -p 22 -u ubuntu -i C:\Users\YourName\.ssh\aws-key.pem
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

PSMUX can save connection profiles:

1. Create a profile for your Docker environment
2. Create a profile for your AWS EC2 instance
3. Quickly switch between environments

For detailed PSMUX usage, see [docs/psmux-guide.md](docs/psmux-guide.md).

---

## Section 5: VS Code Terminal + tmux Integration (Optional)

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

MIT License - See LICENSE file for details

---

## Additional Resources

- [tmux Cheat Sheet](https://tmuxcheatsheet.com/)
- [emacs Tutorial](https://www.gnu.org/software/emacs/tour/)
- [VS Code Remote Development](https://code.visualstudio.com/docs/remote/remote-overview)
- [AWS EC2 User Guide](https://docs.aws.amazon.com/ec2/)
- [Docker Documentation](https://docs.docker.com/)

---

**Questions or Issues?** Open an issue on GitHub or consult the detailed guides in the `docs/` directory.
