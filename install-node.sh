#!/bin/bash

# Script to help install Node.js and npm

echo "=========================================="
echo "  Node.js and npm Installation Helper"
echo "=========================================="
echo ""

# Check if nvm is already installed
if [ -d "$HOME/.nvm" ]; then
    echo "✓ nvm is already installed"
    echo ""
    echo "To use nvm, run:"
    echo "  source ~/.nvm/nvm.sh"
    echo "  nvm install 20"
    echo "  nvm use 20"
    echo ""
    exit 0
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "Could not detect OS. Please install Node.js manually."
    exit 1
fi

echo "Detected OS: $OS"
echo ""

# Installation instructions based on OS
case $OS in
    ubuntu|debian)
        echo "For Ubuntu/Debian, you can install Node.js using:"
        echo ""
        echo "Option 1: Using nvm (recommended):"
        echo "  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash"
        echo "  source ~/.bashrc"
        echo "  nvm install 20"
        echo "  nvm use 20"
        echo ""
        echo "Option 2: Using apt (system-wide):"
        echo "  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -"
        echo "  sudo apt-get install -y nodejs"
        echo ""
        ;;
    fedora|rhel|centos)
        echo "For Fedora/RHEL/CentOS, you can install Node.js using:"
        echo ""
        echo "Option 1: Using nvm (recommended):"
        echo "  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash"
        echo "  source ~/.bashrc"
        echo "  nvm install 20"
        echo "  nvm use 20"
        echo ""
        echo "Option 2: Using dnf:"
        echo "  sudo dnf install -y nodejs npm"
        echo ""
        ;;
    arch|manjaro)
        echo "For Arch/Manjaro, you can install Node.js using:"
        echo ""
        echo "Option 1: Using nvm (recommended):"
        echo "  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash"
        echo "  source ~/.bashrc"
        echo "  nvm install 20"
        echo "  nvm use 20"
        echo ""
        echo "Option 2: Using pacman:"
        echo "  sudo pacman -S nodejs npm"
        echo ""
        ;;
    *)
        echo "For $OS, please install Node.js manually."
        echo "Recommended: Use nvm (Node Version Manager)"
        echo "  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash"
        echo "  source ~/.bashrc"
        echo "  nvm install 20"
        echo "  nvm use 20"
        echo ""
        ;;
esac

echo "After installation, verify with:"
echo "  node --version"
echo "  npm --version"
echo ""
