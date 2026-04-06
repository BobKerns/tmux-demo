# SSH Setup Guide

[日本語版 / Japanese](ssh-setup.ja.md)

This guide covers SSH key generation and configuration for connecting to your tmux development environment.

---

## Table of Contents

1. [Generating SSH Keys](#generating-ssh-keys)
2. [Adding Keys to Remote Host](#adding-keys-to-remote-host)
3. [SSH Config File](#ssh-config-file)
4. [Troubleshooting](#troubleshooting)
5. [Security Best Practices](#security-best-practices)

---

## Generating SSH Keys

### On macOS/Linux

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

### On Windows

#### Using PowerShell (Windows 10+)

```powershell
# Generate ED25519 key
ssh-keygen -t ed25519 -f C:\Users\YourName\.ssh\tmux_demo_key -C "tmux-demo"
```

**Note**: Windows 10 and later include OpenSSH by default.
If the command isn't found, enable it in Settings → Apps → Optional Features → OpenSSH Client.

#### Using Git Bash

```bash
# Same as macOS/Linux
ssh-keygen -t ed25519 -f ~/.ssh/tmux_demo_key -C "tmux-demo"
```

---

## Adding Keys to Remote Host

Choose the method based on your target environment:

### For Docker Container (Local Testing)

**The Docker container has password authentication disabled**, so you need to add the key using Docker commands:

```bash
# Step 1: Ensure the container is running
docker compose ps

# Step 2: Copy public key into container and add to authorized_keys
docker cp ~/.ssh/tmux_demo_key.pub tmux-demo:/tmp/key.pub && \
docker exec -u developer tmux-demo bash -c \
  "mkdir -p ~/.ssh && \
   chmod 700 ~/.ssh && \
   cat /tmp/key.pub >> ~/.ssh/authorized_keys && \
   chmod 600 ~/.ssh/authorized_keys && \
   rm /tmp/key.pub"

# Step 3: Test the connection
ssh -i ~/.ssh/tmux_demo_key -p 2222 developer@localhost
```

**Windows users (PowerShell):**
```powershell
docker cp $env:USERPROFILE\.ssh\tmux_demo_key.pub tmux-demo:/tmp/key.pub
docker exec -u developer tmux-demo bash -c "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat /tmp/key.pub >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && rm /tmp/key.pub"
```

### For AWS EC2 Instance

AWS EC2 instances typically already have an initial key (the `.pem` file you got when creating the instance).
You have two options:

#### Option A: Add Key Using Existing AWS Key

If you have the original AWS `.pem` key:

```bash
# Step 1: Copy your new public key to the instance
scp -i ~/.ssh/your-aws-key.pem ~/.ssh/tmux_demo_key.pub ubuntu@ec2-xx-xxx.compute-1.amazonaws.com:/tmp/

# Step 2: SSH in with the AWS key
ssh -i ~/.ssh/your-aws-key.pem ubuntu@ec2-xx-xxx.compute-1.amazonaws.com

# Step 3: Add the new key to authorized_keys
cat /tmp/tmux_demo_key.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
rm /tmp/tmux_demo_key.pub
exit

# Step 4: Test with your new key
ssh -i ~/.ssh/tmux_demo_key ubuntu@ec2-xx-xxx.compute-1.amazonaws.com
```

**Alternative using ssh-copy-id** (if you have existing access):
```bash
ssh-copy-id -i ~/.ssh/tmux_demo_key.pub -o "IdentityFile ~/.ssh/your-aws-key.pem" ubuntu@ec2-xx-xxx.compute-1.amazonaws.com
```

#### Option B: Add Key Via AWS Console/Session Manager

If you only have console access (AWS Systems Manager Session Manager):

1. Start a session in the AWS Console
2. Switch to your user:
   ```bash
   sudo su - ubuntu
   ```
3. Edit authorized_keys:
   ```bash
   mkdir -p ~/.ssh
   chmod 700 ~/.ssh
   nano ~/.ssh/authorized_keys
   ```
4. Paste your public key on a new line
   - Get the public key: Run `cat ~/.ssh/tmux_demo_key.pub` on your local machine
   - Copy the entire output (starts with `ssh-ed25519` or `ssh-rsa`)
   - Paste into the nano editor
5. Save and exit (Ctrl+X, Y, Enter)
6. Set permissions:
   ```bash
   chmod 600 ~/.ssh/authorized_keys
   ```
7. Test from your local machine:
   ```bash
   ssh -i ~/.ssh/tmux_demo_key ubuntu@ec2-xx-xxx.compute-1.amazonaws.com
   ```

#### Option C: Use the Setup Script

If you've already copied this repository to your EC2 instance:

```bash
# On the EC2 instance (after copying your .pub key there)
./scripts/setup-ssh.sh /path/to/tmux_demo_key.pub
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
