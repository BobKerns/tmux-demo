# SSH Setup Guide

[日本語版 / Japanese](ssh-setup.ja.md)

This guide covers SSH key generation and configuration for connecting to your tmux development environment.

---

## Table of Contents

1. [SSH Key Types](#ssh-key-types)
2. [Generating SSH Keys](#generating-ssh-keys)
3. [Adding Keys to Remote Host](#adding-keys-to-remote-host)
4. [SSH Config File](#ssh-config-file)
5. [Troubleshooting](#troubleshooting)

---

## SSH Key Types

We recommend **ED25519** keys for modern, secure authentication:

| Key Type | Security | Speed | Compatibility | Recommendation |
| ---------- | ---------- | ------- | --------------- | ---------------- |
| ED25519 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Modern systems | **Recommended** |
| RSA 4096 | ⭐⭐⭐⭐ | ⭐⭐⭐ | Universal | Legacy systems only |
| ECDSA | ⭐⭐⭐ | ⭐⭐⭐⭐ | Most systems | Not recommended |

---

## Generating SSH Keys

### On macOS/Linux

#### Generate ED25519 Key (Recommended)

```bash
# Generate a new ED25519 key
ssh-keygen -t ed25519 -f ~/.ssh/tmux_demo_key -C "tmux-demo"
```

**Parameters explained:**
- `-t ed25519`: Key type (ED25519)
- `-f ~/.ssh/tmux_demo_key`: Output file path
- `-C "tmux-demo"`: Comment for identification

**During generation:**
1. Press Enter to accept the file location
2. Enter a passphrase (recommended) or press Enter for no passphrase
3. Confirm passphrase

**Result:**
- Private key: `~/.ssh/tmux_demo_key`
- Public key: `~/.ssh/tmux_demo_key.pub`

#### Generate RSA 4096 Key (Legacy)

```bash
# Only use if ED25519 is not supported
ssh-keygen -t rsa -b 4096 -f ~/.ssh/tmux_demo_key -C "tmux-demo"
```

### On Windows

#### Using PowerShell (Windows 10+)

```powershell
# Generate ED25519 key
ssh-keygen -t ed25519 -f C:\Users\YourName\.ssh\tmux_demo_key -C "tmux-demo"
```

#### Using Git Bash

```bash
# Same as macOS/Linux
ssh-keygen -t ed25519 -f ~/.ssh/tmux_demo_key -C "tmux-demo"
```

#### Using PuTTYgen (Alternative)

1. Download PuTTYgen from [PuTTY website](https://www.putty.org/)
2. Run PuTTYgen
3. Select "EdDSA" and "Curve25519" (ED25519)
4. Click "Generate" and move mouse for randomness
5. Add comment: "tmux-demo"
6. Set passphrase (optional)
7. Save private key as `.ppk` file
8. Copy public key text for later use

**Note**: For OpenSSH format (needed for VS Code), use "Conversions" → "Export OpenSSH key"

---

## Adding Keys to Remote Host

### Method 1: Using ssh-copy-id (macOS/Linux)

```bash
# Copy public key to Docker container
ssh-copy-id -i ~/.ssh/tmux_demo_key.pub -p 2222 developer@localhost

# Copy public key to AWS EC2
ssh-copy-id -i ~/.ssh/aws_key.pub ubuntu@ec2-xx-xxx.compute-1.amazonaws.com
```

### Method 2: Manual Copy (All Platforms)

#### Step 1: Display your public key

```bash
# On macOS/Linux
cat ~/.ssh/tmux_demo_key.pub

# On Windows PowerShell
Get-Content C:\Users\YourName\.ssh\tmux_demo_key.pub
```

**Copy the entire output** (starts with `ssh-ed25519`)

#### Step 2: Add to remote host

**For Docker container:**

```bash
# Copy key to container
docker cp ~/.ssh/tmux_demo_key.pub tmux-demo:/tmp/key.pub

# Add to authorized_keys
docker exec -u developer tmux-demo bash -c "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat /tmp/key.pub >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
```

**For AWS EC2:**

```bash
# Connect to instance
ssh -i ~/.ssh/your-aws-key.pem ubuntu@your-ec2-instance

# Add key manually
mkdir -p ~/.ssh
chmod 700 ~/.ssh
nano ~/.ssh/authorized_keys
# Paste your public key on a new line
# Save and exit (Ctrl+X, Y, Enter)

# Set permissions
chmod 600 ~/.ssh/authorized_keys
exit
```

### Method 3: Using the setup-ssh.sh Script

```bash
# From inside the remote system (Docker or EC2)
./scripts/setup-ssh.sh /path/to/public/key.pub
```

---

## SSH Config File

The SSH config file (`~/.ssh/config`) lets you define shortcuts for connections.

### Location

- **macOS/Linux**: `~/.ssh/config`
- **Windows**: `C:\Users\YourName\.ssh\config`

### Creating the Config File

If the file doesn't exist:

```bash
# macOS/Linux
mkdir -p ~/.ssh
touch ~/.ssh/config
chmod 600 ~/.ssh/config
```

```powershell
# Windows PowerShell
New-Item -ItemType Directory -Force -Path C:\Users\$env:USERNAME\.ssh
New-Item -ItemType File -Force -Path C:\Users\$env:USERNAME\.ssh\config
```

### Example Configurations

#### Docker Container

```
Host tmux-demo
    HostName localhost
    User developer
    Port 2222
    IdentityFile ~/.ssh/tmux_demo_key
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

Now you can connect with just:
```
ssh tmux-demo
```

#### AWS EC2 Instance

```
Host tmux-aws
    HostName ec2-xx-xxx-xxx-xxx.compute-1.amazonaws.com
    User ubuntu
    Port 22
    IdentityFile ~/.ssh/aws-key.pem
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

Connect with:
```
ssh tmux-aws
```

#### Multiple Environments

```
# Docker local testing
Host tmux-local
    HostName localhost
    User developer
    Port 2222
    IdentityFile ~/.ssh/tmux_demo_key

# AWS development
Host tmux-dev
    HostName ec2-dev.compute-1.amazonaws.com
    User ubuntu
    IdentityFile ~/.ssh/aws-dev-key.pem

# AWS production
Host tmux-prod
    HostName ec2-prod.compute-1.amazonaws.com
    User ubuntu
    IdentityFile ~/.ssh/aws-prod-key.pem
    # Extra security: require confirmation
    ControlMaster no
```

### Configuration Options Explained

| Option | Description | Example |
| -------- | ------------- | --------- |
| `Host` | Alias for this connection | `tmux-demo` |
| `HostName` | Actual hostname or IP | `localhost` or `ec2-xx.amazonaws.com` |
| `User` | Username to login as | `developer` or `ubuntu` |
| `Port` | SSH port | `22` (default) or `2222` |
| `IdentityFile` | Path to private key | `~/.ssh/tmux_demo_key` |
| `ServerAliveInterval` | Keepalive interval (seconds) | `60` |
| `StrictHostKeyChecking` | Check host key | `yes` (secure) or `no` (testing) |

---

## Troubleshooting

### Permission Denied (publickey)

**Symptoms:**
```
Permission denied (publickey).
```

**Solutions:**

1. **Check key permissions:**
   ```bash
   chmod 600 ~/.ssh/tmux_demo_key
   chmod 644 ~/.ssh/tmux_demo_key.pub
   ```

2. **Verify public key is on server:**
   ```bash
   ssh -i ~/.ssh/tmux_demo_key user@host "cat ~/.ssh/authorized_keys"
   ```

3. **Test with verbose output:**
   ```bash
   ssh -v -i ~/.ssh/tmux_demo_key user@host
   ```
   Look for "Offering public key" and "Authentications that can continue"

4. **Check server-side permissions:**
   ```bash
   # On remote host
   chmod 700 ~/.ssh
   chmod 600 ~/.ssh/authorized_keys
   ```

### Wrong Permissions on Key File

**Symptoms:**
```
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@         WARNING: UNPROTECTED PRIVATE KEY FILE!          @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
Permissions 0644 for '/home/user/.ssh/id_rsa' are too open.
```

**Solution:**
```bash
chmod 600 ~/.ssh/tmux_demo_key
```

### Connection Timeout

**Symptoms:**
```
ssh: connect to host localhost port 2222: Connection timed out
```

**Solutions:**

1. **Check if service is running:**
   ```bash
   # For Docker
   docker ps

   # For EC2
   ping your-ec2-instance
   ```

2. **Verify port:**
   ```bash
   # For Docker
   docker port tmux-demo

   # For EC2 - check Security Group allows SSH from your IP
   ```

3. **Check firewall:**
   ```bash
   # On remote host
   sudo ufw status
   ```

### Host Key Verification Failed

**Symptoms:**
```
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
```

**Cause:** Host key changed (e.g., container recreated)

**Solution:**
```bash
# Remove old host key
ssh-keygen -R [localhost]:2222

# Or edit known_hosts manually
nano ~/.ssh/known_hosts
# Delete the line for [localhost]:2222
```

### Key Not Being Used

**Symptoms:**
SSH asks for password or uses wrong key

**Solutions:**

1. **Specify key explicitly:**
   ```bash
   ssh -i ~/.ssh/tmux_demo_key user@host
   ```

2. **Add key to SSH agent:**
   ```bash
   # Start agent
   eval "$(ssh-agent -s)"

   # Add key
   ssh-add ~/.ssh/tmux_demo_key

   # List keys
   ssh-add -l
   ```

3. **Check SSH config:**
   Verify `IdentityFile` path is correct in `~/.ssh/config`

---

## Security Best Practices

1. **Always use a passphrase** for private keys
   - Protects key if file is stolen
   - Can use ssh-agent to avoid typing repeatedly

2. **Never share private keys**
   - Only share public keys (`.pub` files)
   - Each person should have their own key pair

3. **Restrict key file permissions**
   ```bash
   chmod 600 ~/.ssh/tmux_demo_key      # Private key
   chmod 644 ~/.ssh/tmux_demo_key.pub  # Public key
   chmod 700 ~/.ssh                     # .ssh directory
   ```

4. **Use different keys for different purposes**
   - One key for work, one for personal
   - Different keys for different servers

5. **Disable password authentication** on servers
   ```bash
   # In /etc/ssh/sshd_config
   PasswordAuthentication no
   ```

6. **Regularly rotate keys**
   - Generate new keys periodically
   - Remove old public keys from authorized_keys

7. **Back up private keys securely**
   - Store in encrypted location
   - Keep offline backup

---

## Quick Reference

### Generate New Key
```bash
ssh-keygen -t ed25519 -f ~/.ssh/tmux_demo_key -C "tmux-demo"
```

### Copy Key to Server
```bash
ssh-copy-id -i ~/.ssh/tmux_demo_key.pub user@host
```

### Test Connection
```bash
ssh -i ~/.ssh/tmux_demo_key user@host
```

### Add to SSH Config
```
Host myserver
    HostName server.example.com
    User username
    IdentityFile ~/.ssh/tmux_demo_key
```

### Fix Permissions
```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/tmux_demo_key
chmod 644 ~/.ssh/tmux_demo_key.pub
chmod 600 ~/.ssh/authorized_keys
```

---

**Next Steps:**
- [VS Code Remote-SSH Setup](vscode-remote-ssh.md)
- [Windows PSMUX Guide](psmux-guide.md)
- [Back to README](../README.md)
