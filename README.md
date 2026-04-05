# tmux + emacs Development Environment

**Ubuntu 24.04 LTS | tmux | emacs | VS Code Remote-SSH | Docker | AWS EC2**

[日本語版はこちら / Japanese version](README.ja.md)

---

## Overview

This project provides a complete development environment setup featuring:

- **Ubuntu 24.04 LTS** base system
- **tmux** with emacs-friendly configuration (Ctrl+^ prefix)
- **emacs** text editor (terminal version)
- **SSH** server for remote access
- **VS Code Remote-SSH** compatibility
- **Docker** environment for local testing
- **AWS EC2** deployment instructions

### What's Included

```
tmux-demo/
├── Dockerfile              # Ubuntu 24.04 + tmux + emacs + SSH
├── docker-compose.yml      # Local development container setup
├── .tmux.conf             # Emacs-friendly tmux configuration
├── scripts/
│   ├── setup-ssh.sh       # Automate SSH key setup
│   ├── install-tmux-emacs.sh  # AWS EC2 installation script
│   └── test-connection.sh # Connection verification tool
└── docs/
    ├── ssh-setup.md       # SSH key generation guide
    ├── vscode-remote-ssh.md   # VS Code Remote-SSH setup
    └── psmux-guide.md     # Windows PSMUX client guide
```

### Key Features

- **Emacs-Friendly tmux**: Uses `Ctrl+^` prefix instead of `Ctrl+b` to avoid conflicts
- **Mouse Support**: Full mouse support in tmux for scrolling and pane management
- **Secure SSH**: Key-based authentication only, no password login
- **Multi-Platform**: Works with Docker locally and AWS EC2 in production
- **Japanese Documentation**: Complete translations available

---

## Table of Contents

1. [Docker Setup (Local Testing)](#section-1-docker-setup-local-testing)
2. [AWS EC2 Setup](#section-2-aws-ec2-setup)
3. [VS Code Remote-SSH](#section-3-vs-code-remote-ssh)
4. [Windows PSMUX Tmux Client](#section-4-windows-psmux-tmux-client)
5. [VS Code Terminal + tmux Integration](#section-5-vs-code-terminal-tmux-integration)

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
|---------|-------------|
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

#### 1. Launch EC2 Instance

**Using AWS Console:**

1. Go to EC2 Dashboard → Launch Instance
2. **Name**: `tmux-dev-environment` (or your choice)
3. **AMI**: Ubuntu Server 24.04 LTS (HVM), SSD Volume Type
4. **Instance Type**: t3.micro or t3.small (Free Tier eligible)
5. **Key Pair**: Select an existing key pair or create a new one
6. **Network Settings**:
   - Allow SSH (port 22) from your IP address
   - Security Group: Create a new one or use existing
7. **Storage**: 8-20 GB gp3 (default is fine)
8. Click **Launch Instance**

#### 2. Connect to Your Instance

Wait for the instance to be in "running" state, then:

```bash
# Get the public IP or DNS from EC2 console
ssh -i ~/.ssh/your-aws-key.pem ubuntu@ec2-xx-xxx-xxx-xxx.compute-1.amazonaws.com
```

#### 3. Install tmux and emacs

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

#### 4. Set Up tmux Configuration

```bash
# Download the emacs-friendly tmux configuration
wget https://raw.githubusercontent.com/your-repo/tmux-demo/main/.tmux.conf -O ~/.tmux.conf

# Or create it manually (see .tmux.conf in this repo)
```

#### 5. Configure SSH Keys

If you want to use a different key for daily access:

```bash
# On your local machine: generate a new key
ssh-keygen -t ed25519 -f ~/.ssh/aws_tmux_key -C "aws-tmux"

# Copy the public key to the server
ssh-copy-id -i ~/.ssh/aws_tmux_key.pub ubuntu@your-ec2-instance
```

#### 6. Test the Setup

```bash
# From your local machine
./scripts/test-connection.sh your-ec2-instance 22 ~/.ssh/aws_tmux_key ubuntu
```

### Security Best Practices

1. **Restrict SSH Access**:
   - Update Security Group to allow SSH only from your IP
   - Consider using AWS Session Manager for access

2. **Keep System Updated**:
   ```bash
   sudo apt-get update && sudo apt-get upgrade -y
   ```

3. **Configure Firewall** (optional):
   ```bash
   sudo ufw allow OpenSSH
   sudo ufw enable
   ```

4. **Set up automatic security updates**:
   ```bash
   sudo apt-get install unattended-upgrades
   sudo dpkg-reconfigure --priority=low unattended-upgrades
   ```

### Cost Optimization

- **Use t3.micro** for light workloads (Free Tier: 750 hours/month)
- **Stop instances** when not in use (you only pay for storage)
- **Use Elastic IPs carefully** (charged when not attached to running instance)
- **Set up billing alerts** in AWS Console

---

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
|------|---------|
| Open remote folder | `Ctrl+K Ctrl+O` → Select folder |
| New terminal | `` Ctrl+Shift+` `` |
| Close remote connection | Click "SSH: hostname" in bottom-left → "Close Remote Connection" |
| Reload window | `Ctrl+Shift+P` → "Developer: Reload Window" |

### Troubleshooting

**Connection times out:**
- Verify SSH connection works: `ssh -i <key> user@host`
- Check firewall/security group settings
- Increase connection timeout in VS Code settings

**VS Code Server fails to install:**
- Check disk space on remote: `df -h`
- Try manual cleanup: `rm -rf ~/.vscode-server`

For more details, see [docs/vscode-remote-ssh.md](docs/vscode-remote-ssh.md).

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
|---------|-------------|
| `Ctrl+^ c` | Create new window |
| `Ctrl+^ |` | Split pane horizontally |
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

## Section 5: VS Code Terminal + tmux Integration

**Note**: This section is separate from Remote-SSH. It configures VS Code's integrated terminal to work with tmux when you're already connected to a remote host.

### Why Integrate tmux with VS Code Terminal?

When working via VS Code Remote-SSH, you can configure VS Code's integrated terminal to automatically attach to or create tmux sessions. Benefits:

- **Persistent sessions**: Your work survives VS Code disconnections
- **Terminal multiplexing**: Multiple panes within VS Code terminal
- **Emacs-friendly**: Combined with our Ctrl+^ tmux config

### Configuration

#### Option 1: Auto-Attach to tmux Session

Edit your VS Code `settings.json` (remote settings):

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

This configuration:
- Creates a tmux session named "vscode" if it doesn't exist
- Attaches to it if it already exists

#### Option 2: Manual tmux Control

Keep the default terminal but start tmux manually when needed:

```json
{
  "terminal.integrated.profiles.linux": {
    "bash": {
      "path": "bash"
    },
    "tmux": {
      "path": "tmux",
      "args": ["new-session", "-A", "-s", "vscode"]
    }
  },
  "terminal.integrated.defaultProfile.linux": "bash"
}
```

Then use `Ctrl+Shift+P` → "Terminal: Select Default Profile" to switch.

### Usage Workflow

1. **Connect via Remote-SSH** to your environment
2. **Open integrated terminal** (`` Ctrl+` ``)
3. **tmux starts automatically** (if configured) or run `tmux` manually
4. **Work normally** with prefix `Ctrl+^`

### Important Notes

⚠️ **Key Binding Conflicts**:
- Some tmux keybindings may conflict with VS Code
- You can remap VS Code keys in `keybindings.json`

⚠️ **When to Use**:
- Use this when you want persistent terminal sessions
- NOT needed for basic Remote-SSH usage
- Consider if you frequently lose connection

### Example: Remap Conflicting Keys

If tmux bindings conflict with VS Code, remap in `keybindings.json`:

```json
[
  {
    "key": "ctrl+^",
    "command": "-workbench.action.terminal.sendSequence",
    "when": "terminalFocus"
  }
]
```

### Pros and Cons

**Pros**:
- ✅ Persistent terminal sessions
- ✅ Powerful terminal multiplexing
- ✅ Survives network interruptions

**Cons**:
- ❌ Extra complexity
- ❌ Potential keybinding conflicts
- ❌ Learning curve for tmux

### Further Reading

- See [docs/vscode-remote-ssh.md](docs/vscode-remote-ssh.md) for complete integration guide
- [tmux documentation](https://github.com/tmux/tmux/wiki)
- [VS Code Terminal documentation](https://code.visualstudio.com/docs/terminal/basics)

---

## Quick Reference

### tmux Essentials (Prefix: Ctrl+^)

| Command | Description |
|---------|-------------|
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
