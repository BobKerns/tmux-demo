#!/bin/bash
# ============================================================================
# Connection Test Script
# ============================================================================
# This script tests SSH connection and tmux functionality on a remote host.
#
# Usage:
#   ./test-connection.sh <host> <port> <private-key> <username>
#
# Example (Docker):
#   ./test-connection.sh localhost 2222 ~/.ssh/id_ed25519 developer
#
# Example (AWS EC2):
#   ./test-connection.sh ec2-xxx.compute.amazonaws.com 22 ~/.ssh/aws-key.pem ubuntu
# ============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
HOST="${1:-localhost}"
PORT="${2:-2222}"
KEY="${3:-$HOME/.ssh/id_ed25519}"
USER="${4:-developer}"

# Expand ~ to home directory
KEY="${KEY/#\~/$HOME}"

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  SSH and Tmux Connection Test${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""
echo "Configuration:"
echo "  Host: $HOST"
echo "  Port: $PORT"
echo "  User: $USER"
echo "  Key:  $KEY"
echo ""

# Check if private key exists
if [ ! -f "$KEY" ]; then
    echo -e "${RED}Error: Private key not found: $KEY${NC}"
    exit 1
fi

# Check key permissions
KEY_PERMS=$(stat -f "%OLp" "$KEY" 2>/dev/null || stat -c "%a" "$KEY" 2>/dev/null)
if [ "$KEY_PERMS" != "600" ] && [ "$KEY_PERMS" != "400" ]; then
    echo -e "${YELLOW}Warning: Key permissions are $KEY_PERMS (should be 600 or 400)${NC}"
    echo -e "${YELLOW}Fixing permissions...${NC}"
    chmod 600 "$KEY"
    echo -e "${GREEN}✓ Permissions fixed${NC}"
    echo ""
fi

# Test 1: Basic SSH connection
echo -e "${YELLOW}Test 1: Basic SSH Connection${NC}"
echo "Running command: ssh -i $KEY -p $PORT $USER@$HOST 'echo SUCCESS'"
if ssh -i "$KEY" -p "$PORT" -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$USER@$HOST" 'echo SUCCESS' &>/dev/null; then
    echo -e "${GREEN}✓ SSH connection successful${NC}"
else
    echo -e "${RED}✗ SSH connection failed${NC}"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Verify the host is reachable:"
    echo "     ping $HOST"
    echo "  2. Check if SSH service is running on the host"
    echo "  3. Verify the public key is in ~/.ssh/authorized_keys on the host"
    echo "  4. Check SSH config permits key authentication"
    exit 1
fi
echo ""

# Test 2: Check tmux installation
echo -e "${YELLOW}Test 2: Tmux Installation${NC}"
TMUX_VERSION=$(ssh -i "$KEY" -p "$PORT" "$USER@$HOST" 'tmux -V' 2>/dev/null || echo "NOT_INSTALLED")
if [[ "$TMUX_VERSION" != "NOT_INSTALLED" ]]; then
    echo -e "${GREEN}✓ Tmux is installed: $TMUX_VERSION${NC}"
else
    echo -e "${RED}✗ Tmux is not installed${NC}"
    echo "  Install with: sudo apt-get update && sudo apt-get install -y tmux"
fi
echo ""

# Test 3: Check emacs installation
echo -e "${YELLOW}Test 3: Emacs Installation${NC}"
EMACS_VERSION=$(ssh -i "$KEY" -p "$PORT" "$USER@$HOST" 'emacs --version' 2>/dev/null | head -n 1 || echo "NOT_INSTALLED")
if [[ "$EMACS_VERSION" != "NOT_INSTALLED" ]]; then
    echo -e "${GREEN}✓ Emacs is installed: $EMACS_VERSION${NC}"
else
    echo -e "${RED}✗ Emacs is not installed${NC}"
    echo "  Install with: sudo apt-get update && sudo apt-get install -y emacs-nox"
fi
echo ""

# Test 4: Check .tmux.conf
echo -e "${YELLOW}Test 4: Tmux Configuration${NC}"
if ssh -i "$KEY" -p "$PORT" "$USER@$HOST" 'test -f ~/.tmux.conf' 2>/dev/null; then
    echo -e "${GREEN}✓ .tmux.conf exists${NC}"

    # Check for emacs-friendly prefix
    if ssh -i "$KEY" -p "$PORT" "$USER@$HOST" 'grep -q "prefix C-\^" ~/.tmux.conf' 2>/dev/null; then
        echo -e "${GREEN}✓ Emacs-friendly prefix (C-^) configured${NC}"
    else
        echo -e "${YELLOW}⚠ Custom prefix not found (may be using default C-b)${NC}"
    fi
else
    echo -e "${YELLOW}⚠ .tmux.conf not found (using default configuration)${NC}"
fi
echo ""

# Test 5: Test tmux session creation
echo -e "${YELLOW}Test 5: Tmux Session Test${NC}"
if [[ "$TMUX_VERSION" != "NOT_INSTALLED" ]]; then
    # Create a test session, run a command, and kill it
    if ssh -i "$KEY" -p "$PORT" "$USER@$HOST" 'tmux new-session -d -s test_session "echo test" && tmux kill-session -t test_session' 2>/dev/null; then
        echo -e "${GREEN}✓ Tmux session creation successful${NC}"
    else
        echo -e "${RED}✗ Tmux session creation failed${NC}"
    fi
else
    echo -e "${YELLOW}⊘ Skipped (tmux not installed)${NC}"
fi
echo ""

# Test 6: Check Git installation
echo -e "${YELLOW}Test 6: Git Installation${NC}"
GIT_VERSION=$(ssh -i "$KEY" -p "$PORT" "$USER@$HOST" 'git --version' 2>/dev/null || echo "NOT_INSTALLED")
if [[ "$GIT_VERSION" != "NOT_INSTALLED" ]]; then
    echo -e "${GREEN}✓ Git is installed: $GIT_VERSION${NC}"
else
    echo -e "${YELLOW}⚠ Git is not installed${NC}"
fi
echo ""

# Summary
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Test Summary${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""
echo "Connection String:"
echo "  ssh -i $KEY -p $PORT $USER@$HOST"
echo ""
echo "VS Code Remote-SSH Config Entry:"
echo "  Host tmux-demo"
echo "    HostName $HOST"
echo "    User $USER"
echo "    Port $PORT"
echo "    IdentityFile $KEY"
echo ""
echo -e "${GREEN}All critical tests passed!${NC}"
echo ""
echo "Next steps:"
echo "  1. Connect: ssh -i $KEY -p $PORT $USER@$HOST"
echo "  2. Start tmux: tmux"
echo "  3. Configure VS Code Remote-SSH (see docs/vscode-remote-ssh.md)"
