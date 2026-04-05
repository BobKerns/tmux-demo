#!/bin/bash
# ============================================================================
# SSH Setup Script
# ============================================================================
# This script automates SSH configuration for both Docker containers and
# AWS EC2 instances. It sets up authorized_keys for key-based authentication.
#
# Usage:
#   ./setup-ssh.sh <path-to-public-key>
#
# Example:
#   ./setup-ssh.sh ~/.ssh/id_ed25519.pub
# ============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if public key path is provided
if [ $# -eq 0 ]; then
    echo -e "${RED}Error: No public key path provided${NC}"
    echo "Usage: $0 <path-to-public-key>"
    echo "Example: $0 ~/.ssh/id_ed25519.pub"
    exit 1
fi

PUBLIC_KEY_PATH="$1"

# Expand ~ to home directory
PUBLIC_KEY_PATH="${PUBLIC_KEY_PATH/#\~/$HOME}"

# Check if public key file exists
if [ ! -f "$PUBLIC_KEY_PATH" ]; then
    echo -e "${RED}Error: Public key file not found: $PUBLIC_KEY_PATH${NC}"
    exit 1
fi

echo -e "${GREEN}SSH Setup Script${NC}"
echo "================================"
echo ""

# Create .ssh directory if it doesn't exist
SSH_DIR="$HOME/.ssh"
if [ ! -d "$SSH_DIR" ]; then
    echo -e "${YELLOW}Creating .ssh directory...${NC}"
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
fi

# Set up authorized_keys
AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"

echo -e "${YELLOW}Adding public key to authorized_keys...${NC}"
cat "$PUBLIC_KEY_PATH" >> "$AUTHORIZED_KEYS"

# Set proper permissions
chmod 600 "$AUTHORIZED_KEYS"

echo -e "${GREEN}✓ Public key added successfully${NC}"
echo ""
echo "Authorized keys file: $AUTHORIZED_KEYS"
echo "Permissions: $(ls -l $AUTHORIZED_KEYS | awk '{print $1}')"
echo ""

# Display the added key (first 60 characters)
echo "Added key:"
tail -n 1 "$AUTHORIZED_KEYS" | cut -c1-60
echo "..."
echo ""

echo -e "${GREEN}SSH setup completed successfully!${NC}"
echo ""
echo "You can now connect using:"
echo "  ssh -i <private-key> $(whoami)@<host>"
