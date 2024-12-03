#!/bin/bash

set -e

# Check for nvm
if ! command -v nvm &> /dev/null; then
    echo "Installing nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.4/install.sh | bash
    source ~/.nvm/nvm.sh
fi

# Install and use Node.js 20
echo "Switching to Node.js 20..."
nvm install 20
nvm use 20

# Verify versions
echo "Node.js version: $(node -v)"
echo "npm version: $(npm -v)"

# Clear npm cache
echo "Clearing npm cache..."
npm cache clean --force

# Install dependencies
echo "Installing npm dependencies..."
npm install

# Verify package-lock.json
if [ -f "package-lock.json" ]; then
    echo "package-lock.json successfully created."
else
    echo "Failed to create package-lock.json."
    exit 1
fi