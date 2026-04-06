# Docker Setup (Local Testing & Demonstration)

[日本語版はこちら / Japanese version](docker-setup.ja.md)

This guide is for local testing and demonstration purposes. The Docker environment allows testing the tmux + emacs setup without requiring AWS access or modifying production systems.

**Target audience**: Developers who want to test or demonstrate the environment locally before deploying to AWS.

---

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Quick Start](#quick-start)
4. [Docker Commands](#docker-commands)
5. [Troubleshooting](#troubleshooting)
6. [Next Steps](#next-steps)

---

## Overview

The Docker setup provides:
- Ubuntu 24.04 LTS environment
- tmux 3.4 with emacs-friendly configuration (Ctrl+^ prefix)
- emacs 29.3
- SSH server on port 2222
- Persistent home directory volume
- User `developer` with sudo privileges

This mirrors the AWS EC2 environment for local testing.

---

## Prerequisites

- Docker installed on your system ([Get Docker](https://docs.docker.com/get-docker/))
- Docker Compose installed
- SSH key pair (see [ssh-setup.md](ssh-setup.md))

---

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/BobKerns/tmux-demo.git
cd tmux-demo
```

### 2. Build and Start the Container

```bash
docker-compose up -d --build
```

This creates a container named `tmux-demo` with:
- SSH server on port 2222 (mapped from container port 22)
- User `developer` with sudo privileges
- Persistent home directory volume

### 3. Set Up SSH Access

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

### 4. Test the Connection

```bash
ssh -i ~/.ssh/tmux_demo_key -p 2222 developer@localhost
```

### 5. Start tmux

```bash
tmux
```

**Remember**: The prefix key is **Ctrl+^** (not Ctrl+b)!

---

## Docker Commands

| Command | Description |
| --------- | ------------- |
| `docker-compose up -d` | Start container in background |
| `docker-compose down` | Stop and remove container |
| `docker-compose logs -f` | View container logs |
| `docker exec -it tmux-demo bash` | Open shell in container |
| `docker-compose restart` | Restart the container |
| `docker-compose build` | Rebuild the image |
| `docker ps` | List running containers |
| `docker port tmux-demo` | Show port mappings |

---

## Troubleshooting

### Cannot Connect via SSH

**Symptoms**: `Connection refused` or timeout when trying to SSH to localhost:2222

**Solutions**:
1. Check container is running:
   ```bash
   docker ps
   ```
   Should show `tmux-demo` in the list

2. Verify port mapping:
   ```bash
   docker port tmux-demo
   ```
   Should show: `22/tcp -> 0.0.0.0:2222`

3. Check SSH key permissions:
   ```bash
   chmod 600 ~/.ssh/tmux_demo_key
   ```

4. View SSH logs:
   ```bash
   docker logs tmux-demo
   ```
   Look for SSH server startup messages

5. Restart the container:
   ```bash
   docker-compose restart
   ```

### Tmux Not Working

**Symptoms**: `tmux: command not found` or configuration not applied

**Solutions**:
1. Verify tmux installation:
   ```bash
   docker exec tmux-demo tmux -V
   ```
   Should show: `tmux 3.4` or later

2. Check configuration file:
   ```bash
   docker exec -u developer tmux-demo cat ~/.tmux.conf
   ```
   Should show the emacs-friendly configuration

3. Rebuild the container:
   ```bash
   docker-compose down
   docker-compose up -d --build
   ```

### Permission Denied

**Symptoms**: Cannot access certain files or directories

**Solutions**:
1. Check you're running commands as the correct user:
   ```bash
   docker exec -u developer tmux-demo whoami
   ```
   Should return: `developer`

2. Fix file ownership (if needed):
   ```bash
   docker exec tmux-demo chown -R developer:developer /home/developer
   ```

### Container Won't Start

**Symptoms**: Container exits immediately or won't start

**Solutions**:
1. Check logs:
   ```bash
   docker logs tmux-demo
   ```

2. Verify Docker Compose configuration:
   ```bash
   docker-compose config
   ```

3. Remove existing container and volumes:
   ```bash
   docker-compose down -v
   docker-compose up -d --build
   ```

---

## Next Steps

Once your Docker environment is working:

1. **Test VS Code Remote-SSH**: Follow the [VS Code Remote-SSH Guide](vscode-remote-ssh.md) using the Docker configuration
2. **Try Windows PSMUX**: If on Windows, test the PSMUX tmux client (see main README)
3. **Practice tmux**: Learn the tmux commands (see Quick Reference in main README)
4. **Deploy to AWS**: Use the AWS EC2 setup instructions in the main README

---

## Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [tmux Cheat Sheet](https://tmuxcheatsheet.com/)
- [Main README](../README.md) - AWS setup and usage guide

---

**Questions or Issues?** Open an issue on GitHub or consult the troubleshooting section above.
