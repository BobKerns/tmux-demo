# VS Code Remote-SSH Troubleshooting

[日本語版 / Japanese](vscode-troubleshooting.ja.md)

Common issues and solutions when using VS Code Remote-SSH.

---

## Table of Contents

1. [Connection Fails](#connection-fails)
2. [VS Code Server Installation Fails](#vs-code-server-installation-fails)
3. [Connection Drops/Timeouts](#connection-dropstimeouts)
4. [Permission Denied](#permission-denied)
5. [Extensions Not Working](#extensions-not-working)
6. [File Watcher Limit (Linux)](#file-watcher-limit-linux)
7. [Slow Performance](#slow-performance)
8. [Additional Tips](#additional-tips)

---

## Connection Fails

**Symptoms:**
```
Could not establish connection to "hostname".
The process tried to write to a pipe that has been closed.
```

**Solutions:**

### 1. Test SSH connection manually

```bash
ssh -v hostname
```

Look for errors in verbose output. Common issues:
- Host unreachable
- Permission denied
- Connection refused
- Wrong port

### 2. Check SSH config

Verify your `~/.ssh/config` entries:

```
Host myserver
    HostName correct.server.address
    User correct-username
    Port 22
    IdentityFile ~/.ssh/correct-key
```

Test manually:
```bash
ssh -F ~/.ssh/config hostname
```

### 3. Check key permissions

SSH refuses keys with incorrect permissions:

```bash
# Fix private key permissions
chmod 600 ~/.ssh/your-key

# Fix .ssh directory
chmod 700 ~/.ssh
```

### 4. For Docker: Ensure container is running

```bash
# Check container status
docker ps

# Start if stopped
docker start tmux-demo

# Check logs
docker logs tmux-demo
```

### 5. For EC2: Check Security Group

- Security Group must allow SSH (port 22) from your IP
- Check AWS Console → EC2 → Security Groups
- Add rule: Type=SSH, Source=My IP

### 6. For corporate networks

- Corporate firewall may block SSH
- Try from different network
- Check with IT department about proxy settings

---

## VS Code Server Installation Fails

**Symptoms:**
```
Failed to install VS Code Server
Could not install Visual Studio Code Server
```

**Solutions:**

### 1. Check disk space on remote

VS Code Server needs at least 1GB free space:

```bash
# Check disk usage
df -h ~

# Check home directory size
du -sh ~/.vscode-server
```

Free up space if needed:
```bash
# Remove old server versions
rm -rf ~/.vscode-server/bin/*
```

### 2. Manual cleanup and retry

Complete reset:

```bash
# Remove entire VS Code Server directory
rm -rf ~/.vscode-server

# Also remove extensions (optional)
rm -rf ~/.vscode-server-insiders
```

Then reconnect from VS Code.

### 3. Check internet connection on remote

VS Code downloads the server from Microsoft:

```bash
# Test connection
curl -I https://update.code.visualstudio.com

# Expected: HTTP/2 200
```

If curl fails:
- Remote host has no internet
- Firewall blocking downloads
- DNS resolution issues

### 4. Firewall blocking download

Corporate firewalls may block `update.code.visualstudio.com`:

- Contact IT department
- Request whitelist for VS Code domains
- Try from different network (home, mobile hotspot)

### 5. Manual installation

Download server manually:

```bash
# Get your VS Code commit ID
code --version  # First line is commit ID

# Download server manually (on remote)
wget https://update.code.visualstudio.com/commit:$COMMIT_ID/server-linux-x64/stable

# Extract to ~/.vscode-server/bin/$COMMIT_ID
```

---

## Connection Drops/Timeouts

**Symptoms:**
- Connection works initially but drops after inactivity
- "Connection lost" errors
- Need to reconnect frequently

**Solutions:**

### 1. Add keepalive to SSH config

Prevent SSH from timing out:

```
Host myserver
    HostName server.address
    User developer
    IdentityFile ~/.ssh/tmux_demo_key
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

**Explanation:**
- `ServerAliveInterval 60`: Send keepalive every 60 seconds
- `ServerAliveCountMax 3`: Try 3 times before giving up
- Total timeout: 180 seconds

### 2. Use tmux for unstable connections

**Best solution for unreliable networks:**

See [tmux Integration Guide](vscode-tmux-integration.md)

Benefits:
- Work survives disconnections
- Reconnect and resume immediately
- Background processes keep running

Quick setup:
```bash
# Install tmux on remote (if not already)
sudo apt install tmux

# Start session
tmux new -s vscode

# Later: reattach after disconnect
tmux attach -t vscode
```

### 3. Adjust VS Code timeout settings

Increase connection timeout:

```json
{
  "remote.SSH.connectTimeout": 60,
  "remote.SSH.serverPickPortsFromRange": {
    "5000": "5100"
  }
}
```

Add to VS Code User Settings.

### 4. Check network stability

```bash
# Test connection stability
ping -c 100 your-server.com

# Check for packet loss
mtr your-server.com
```

High ping times or packet loss indicate network issues.

---

## Permission Denied

**Symptoms:**
```
Permission denied (publickey).
developer@server: Permission denied (publickey,gssapi-keyex,gssapi-with-mic).
```

**Solutions:**

### 1. Verify SSH key is configured

Check your SSH config:

```bash
cat ~/.ssh/config
```

Ensure `IdentityFile` points to correct key:
```
Host myserver
    IdentityFile ~/.ssh/tmux_demo_key
```

### 2. Check public key is on remote

Your **public key** (`.pub`) must be in remote `authorized_keys`:

```bash
# On remote host
cat ~/.ssh/authorized_keys

# Should contain your public key
```

If missing, add it:
```bash
# Copy your public key to clipboard
cat ~/.ssh/tmux_demo_key.pub

# SSH to remote and add
ssh user@host
echo "ssh-ed25519 AAAA..." >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

Or use `ssh-copy-id`:
```bash
ssh-copy-id -i ~/.ssh/tmux_demo_key.pub user@host
```

### 3. Check key permissions

**Local machine:**
```bash
chmod 600 ~/.ssh/tmux_demo_key
chmod 644 ~/.ssh/tmux_demo_key.pub
chmod 700 ~/.ssh
```

**Remote machine:**
```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

### 4. Verify key in SSH agent (if using)

```bash
# List keys in agent
ssh-add -l

# If empty, add your key
ssh-add ~/.ssh/tmux_demo_key
```

### 5. Test manually with verbose output

```bash
ssh -vv user@host

# Look for:
# "Trying private key: /home/user/.ssh/tmux_demo_key"
# "Authentication succeeded (publickey)"
```

For complete SSH setup help, see:
[SSH Setup Guide - Troubleshooting](ssh-setup.md#troubleshooting)

---

## Extensions Not Working

**Symptoms:**
- Extension installed but not functioning
- Features missing
- Extension commands don't appear

**Solutions:**

### 1. Install extension on REMOTE, not locally

When connected via Remote-SSH:

1. Open Extensions view (`Ctrl+Shift+X`)
2. Find your extension
3. Look for "Install in SSH: hostname" button
4. Click to install on remote

**Why:** Some extensions must run on the remote machine.

### 2. Verify extension supports Remote

Not all extensions work with Remote-SSH:

- Check extension page for "Remote" badge
- Look for "Remote Development" in supported features
- Some UI-only extensions only work locally

### 3. Reload VS Code window

After installing extension:

```
Ctrl+Shift+P → "Developer: Reload Window"
```

This ensures extension activates properly.

### 4. Check extension host log

```
Ctrl+Shift+P → "Developer: Show Logs" → "Extension Host"
```

Look for errors from your extension.

### 5. Reinstall extension

1. Uninstall extension (on remote)
2. Reload window
3. Reinstall extension
4. Reload window again

---

## File Watcher Limit (Linux)

**Symptoms:**
```
Visual Studio Code is unable to watch for file changes in this large workspace
```

**Cause:**

Linux limits number of file watches (inotify). Large projects exceed default limit.

**Solution:**

### Temporary increase

```bash
sudo sysctl fs.inotify.max_user_watches=524288
```

Resets on reboot.

### Permanent increase

```bash
# Add to sysctl config
echo "fs.inotify.max_user_watches=524288" | sudo tee -a /etc/sysctl.conf

# Apply immediately
sudo sysctl -p
```

### Alternative: Exclude directories from watching

Don't increase limit, just watch fewer files:

```json
{
  "files.watcherExclude": {
    "**/.git/objects/**": true,
    "**/.git/subtree-cache/**": true,
    "**/node_modules/**": true,
    "**/dist/**": true,
    "**/build/**": true,
    "**/__pycache__/**": true,
    "**/.venv/**": true
  }
}
```

Add to Workspace Settings.

---

## Slow Performance

**Symptoms:**
- Typing lag
- Slow file operations
- IntelliSense delays
- High CPU/memory usage

**Solutions:**

### 1. Reduce file watchers

Exclude unnecessary directories:

```json
{
  "files.watcherExclude": {
    "**/.git/objects/**": true,
    "**/node_modules/**": true,
    "**/dist/**": true,
    "**/build/**": true,
    "**/__pycache__/**": true,
    "**/.pytest_cache/**": true,
    "**/.venv/**": true,
    "**/venv/**": true
  },
  "search.exclude": {
    "**/node_modules": true,
    "**/dist": true,
    "**/.venv": true
  }
}
```

### 2. Disable unused extensions

Each extension consumes resources:

1. Open Extensions view (`Ctrl+Shift+X`)
2. Right-click unused extensions
3. "Disable" or "Disable (Workspace)"

### 3. Close unused terminals

Each terminal consumes memory and CPU:

- Close terminals you're not using
- Use tmux to manage multiple shells in one terminal

### 4. Reduce search scope

When searching:

```json
{
  "search.exclude": {
    "**/node_modules": true,
    "**/dist": true,
    "**/.git": true,
    "**/__pycache__": true
  }
}
```

### 5. Check language service issues

For Python:

```json
{
  "python.analysis.indexing": true,
  "python.analysis.autoImportCompletions": false
}
```

Indexing can be slow on first connect - wait for it to complete.

### 6. For EC2: Use appropriate instance type

- Minimum: t3.small (2 vCPU, 2GB RAM)
- Recommended: t3.medium (2 vCPU, 4GB RAM)
- For large projects: t3.large or larger

Check instance metrics in CloudWatch.

### 7. Network latency

High ping times affect responsiveness:

```bash
# Check latency
ping -c 20 your-server.com

# Acceptable: < 50ms
# Noticeable lag: > 100ms
# Slow: > 200ms
```

Solutions:
- Use server in same region
- Use tmux for all terminal work
- Consider local development for very high latency

---

## Additional Tips

### Connection troubleshooting workflow

```bash
# 1. Test basic connectivity
ping server.address

# 2. Test SSH manually
ssh -v user@server

# 3. Test with VS Code's SSH config
ssh -F ~/.ssh/config hostname

# 4. Check VS Code Remote-SSH output
# View → Output → Remote-SSH
```

### Get more diagnostic info

In VS Code:

1. `Ctrl+Shift+P`
2. "Remote-SSH: Show Log"
3. Look for errors, warnings
4. Copy relevant sections when asking for help

### Reset everything

Nuclear option when nothing works:

```bash
# On local machine
rm -rf ~/.ssh/config.d/vscode-*
rm -rf ~/.vscode/extensions/ms-vscode-remote.*

# On remote machine
rm -rf ~/.vscode-server

# Restart VS Code
```

Then reconfigure from scratch.

---

## Related Documentation

- [VS Code Remote-SSH Setup](vscode-remote-ssh.md)
- [SSH Setup Guide](ssh-setup.md)
- [tmux Integration Guide](vscode-tmux-integration.md) (for connection stability)
- [Official VS Code Remote-SSH Troubleshooting](https://code.visualstudio.com/docs/remote/troubleshooting)

**Still stuck?**
- Check [VS Code Remote-SSH GitHub issues](https://github.com/microsoft/vscode-remote-release/issues)
- Ask on [VS Code discussions](https://github.com/microsoft/vscode-discussions)
- Include: VS Code version, OS, SSH log output
