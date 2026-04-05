#!/bin/bash
# ============================================================================
# Tmux and Emacs Installation Script for AWS EC2 (Ubuntu)
# ============================================================================
# This script installs tmux, emacs, and essential development tools on a
# fresh Ubuntu EC2 instance.
#
# Usage:
#   wget https://raw.githubusercontent.com/your-repo/tmux-demo/main/scripts/install-tmux-emacs.sh
#   chmod +x install-tmux-emacs.sh
#   ./install-tmux-emacs.sh
#
# Or run directly:
#   curl -fsSL https://raw.githubusercontent.com/your-repo/tmux-demo/main/scripts/install-tmux-emacs.sh | bash
# ============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Tmux + Emacs Installation Script${NC}"
echo -e "${BLUE}  for Ubuntu (AWS EC2)${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Check if running on Ubuntu
if [ ! -f /etc/os-release ]; then
    echo -e "${RED}Error: Cannot determine OS. This script is for Ubuntu.${NC}"
    exit 1
fi

. /etc/os-release
if [[ "$ID" != "ubuntu" ]]; then
    echo -e "${YELLOW}Warning: This script is designed for Ubuntu. Detected: $ID${NC}"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo -e "${GREEN}Detected: Ubuntu $VERSION_ID${NC}"
echo ""

# Update package list
echo -e "${YELLOW}Updating package list...${NC}"
sudo apt-get update -qq

# Install tmux
echo -e "${YELLOW}Installing tmux...${NC}"
sudo apt-get install -y tmux

# Install emacs (terminal version for smaller size, or full emacs for GUI support)
echo ""
echo "Select Emacs version:"
echo "  1) emacs-nox (terminal-only, smaller, recommended for servers)"
echo "  2) emacs (full version with GUI support)"
read -pr "Enter choice [1-2] (default: 1): " EMACS_CHOICE
EMACS_CHOICE=${EMACS_CHOICE:-1}

if [ "$EMACS_CHOICE" == "2" ]; then
    echo -e "${YELLOW}Installing full emacs...${NC}"
    sudo apt-get install -y emacs
else
    echo -e "${YELLOW}Installing emacs-nox (terminal-only)...${NC}"
    sudo apt-get install -y emacs-nox
fi

# Install additional development tools
echo ""
echo -e "${YELLOW}Installing additional development tools...${NC}"
sudo apt-get install -y \
    git \
    curl \
    wget \
    vim \
    build-essential \
    htop

# Check tmux version
echo ""
echo -e "${GREEN}✓ Installation completed successfully!${NC}"
echo ""
echo "Installed versions:"
tmux -V
emacs --version | head -n 1
git --version
echo ""

# Download and install .tmux.conf if it doesn't exist
if [ ! -f "$HOME/.tmux.conf" ]; then
    echo -e "${YELLOW}Setting up tmux configuration...${NC}"

    # Check if we have the .tmux.conf from the repo
    if command -v curl &> /dev/null; then
        echo "Downloading emacs-friendly .tmux.conf..."
        # Replace with your actual repo URL
        # curl -fsSL https://raw.githubusercontent.com/your-repo/tmux-demo/main/.tmux.conf -o "$HOME/.tmux.conf"

        # For now, create a minimal config
        cat > "$HOME/.tmux.conf" << 'EOF'
# Emacs-friendly tmux configuration
# Prefix: Ctrl+^ (instead of Ctrl+b)
unbind C-b
set-option -g prefix C-^
bind C-^ send-prefix

# Mouse support
set -g mouse on

# Better colors
set -g default-terminal "screen-256color"

# Start numbering at 1
set -g base-index 1
setw -g pane-base-index 1

# Reload config
bind r source-file ~/.tmux.conf \; display "Config reloaded!"
EOF
        echo -e "${GREEN}✓ .tmux.conf created${NC}"
    fi
else
    echo -e "${BLUE}ℹ .tmux.conf already exists, skipping${NC}"
fi

echo ""
echo -e "${GREEN}Setup complete!${NC}"
echo ""
echo "Quick start:"
echo "  - Start tmux: tmux"
echo "  - Prefix key: Ctrl+^"
echo "  - Create window: Ctrl+^ c"
echo "  - Split horizontal: Ctrl+^ |"
echo "  - Split vertical: Ctrl+^ -"
echo "  - Detach: Ctrl+^ d"
echo "  - Start emacs: emacs"
echo ""
echo "For more information, see the documentation at:"
echo "  https://github.com/your-repo/tmux-demo"
