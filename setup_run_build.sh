#!/bin/bash

# Exit on any error
set -e

# Define variables
NODE_VERSION="20"
LOG_DIR="logs"
WEBUI_LOG="$LOG_DIR/open-webui.log"
PORT="8080"
OPEN_WEB_UI_VERSION="0.4.7"

# Check for required Python version
check_python_version() {
    local python_version
    python_version=$(python3 --version 2>&1 | awk '{print $2}')
    if [[ -z "$python_version" ]]; then
        echo "Error: Python is not installed or not available in PATH."
        exit 1
    fi

    # Extract major and minor version numbers
    local major_version
    local minor_version
    major_version=$(echo "$python_version" | cut -d. -f1)
    minor_version=$(echo "$python_version" | cut -d. -f2)

    if [[ "$major_version" -ne 3 ]] || [[ "$minor_version" -lt 11 ]] || [[ "$minor_version" -ge 12 ]]; then
        echo "Error: Python version must be >= 3.11 and < 3.12. Current version: $python_version"
        exit 1
    fi
    echo "Python version: $python_version (valid)"
}

# Check for required tools
check_prerequisites() {
    echo "Checking prerequisites..."
    for cmd in python3 pip3 npm ffmpeg; do
        if ! command -v $cmd &> /dev/null; then
            echo "Error: $cmd is required but not installed. Please install it and re-run this script."
            exit 1
        fi
    done
}

# Main script logic starts here
check_python_version
check_prerequisites

# Check for nvm and source it
echo "Checking for nvm..."
if [ -s "$HOME/.nvm/nvm.sh" ]; then
    source "$HOME/.nvm/nvm.sh"
elif [ -s "/usr/local/opt/nvm/nvm.sh" ]; then
    source "/usr/local/opt/nvm/nvm.sh"
else
    echo "nvm is not installed. Please install it and re-run this script."
    exit 1
fi

# Set up Node.js version using nvm
echo "Switching to Node.js $NODE_VERSION..."
nvm install $NODE_VERSION
nvm use $NODE_VERSION

# Verify Node.js and npm versions
echo "Node.js version: $(node -v)"
echo "npm version: $(npm -v)"

# Install Open-WebUI using pip
echo "Installing Open-WebUI $OPEN_WEB_UI_VERSION..."
pip install --upgrade pip
pip uninstall open-webui -y
pip install open-webui==$OPEN_WEB_UI_VERSION

# Verify Open-WebUI installation
echo "Verifying Open-WebUI installation..."
if ! open-webui --help > /dev/null 2>&1; then
    echo "Open-WebUI installation failed or is not accessible."
    exit 1
fi

# Clean npm environment
echo "Cleaning npm environment..."
rm -rf node_modules package-lock.json

# Install npm dependencies, including dotenv
echo "Installing npm dependencies..."
npm install
npm install dotenv --save

# Set the WEBUI_AUTH environment variable
export WEBUI_AUTH=False

# Create a log directory
mkdir -p $LOG_DIR

# Stop any existing process on port 8080
if lsof -i:$PORT | grep LISTEN; then
    echo "Port $PORT is already in use. Stopping the existing process."
    PID=$(lsof -ti:$PORT) # Get the PID of the process using the port
    if [ -n "$PID" ]; then
        kill -9 "$PID" # Forcefully terminate the process
        echo "Process $PID using port $PORT has been terminated."
    fi
else
    echo "Port $PORT is not in use."
fi

# Start the Open-WebUI server on port 8080 in the background
echo "Starting Open-WebUI server on port $PORT..."
nohup open-webui serve --port "$PORT" > "$WEBUI_LOG" 2>&1 &
SERVER_PID=$!

# Wait for the server to start
echo "Waiting for Open-WebUI server to start on port $PORT..."
for i in {1..10}; do
    if nc -z localhost "$PORT"; then
        echo "Open-WebUI server is running on port $PORT."
        break
    fi
    sleep 1
    if [ $i -eq 10 ]; then
        echo "Error: Open-WebUI server failed to start on port $PORT."
        echo "Check logs at $WEBUI_LOG for details."
        kill $SERVER_PID
        exit 1
    fi
done

# Build the macOS DMG
echo "Building the macOS DMG..."
if ! npx electron-builder --mac; then
    echo "Error: Electron build process failed."
    kill $SERVER_PID
    exit 1
fi
echo "DMG build complete! The file can be found in the dist directory."

# Run the Electron app to test it
echo "Starting the Electron app for testing..."
if ! npm start; then
    echo "Error: Electron app failed to start."
    exit 1
fi

echo "Build complete! The DMG file can be found in the dist directory."