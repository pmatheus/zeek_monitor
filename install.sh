#!/bin/bash

# This script installs the Zeek Monitor as a service using Miniconda Python
# Assumes zeek_monitor.py and zeek-monitor.service are in the same directory

# Exit on error
set -e

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

# Check if the required files exist
if [ ! -f "$SCRIPT_DIR/zeek_monitor.py" ]; then
    echo "Error: zeek_monitor.py not found in the same directory as this script" >&2
    exit 1
fi

if [ ! -f "$SCRIPT_DIR/zeek-monitor.service" ]; then
    echo "Error: zeek-monitor.service not found in the same directory as this script" >&2
    exit 1
fi

# Check if running on Windows
if [[ "$OSTYPE" == "win"* || "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin"* ]]; then
    echo "Warning: This installer is designed for Ubuntu. Windows is not fully supported."
    echo "You can still use the Python script manually on Windows for testing purposes."
fi

# Variables
SCRIPT_PATH=/usr/local/bin/zeek_monitor.py
SERVICE_PATH=/etc/systemd/system/zeek-monitor.service


# Prompt for the username that has Miniconda installed
read -p "Enter the username who has Miniconda installed in their home directory: " MINICONDA_USER

# Check if the user exists
if ! id "$MINICONDA_USER" &>/dev/null; then
    echo "Error: User $MINICONDA_USER does not exist" >&2
    exit 1
fi

# Check if Miniconda exists in the user's home directory
MINICONDA_PATH="/home/$MINICONDA_USER/miniconda3"
if [ ! -d "$MINICONDA_PATH" ]; then
    echo "Error: Miniconda directory not found at $MINICONDA_PATH" >&2
    echo "Please ensure Miniconda is installed at this location or modify this script accordingly." >&2
    exit 1
fi

# Check if Python executable exists
PYTHON_PATH="$MINICONDA_PATH/bin/python"
if [ ! -f "$PYTHON_PATH" ]; then
    echo "Error: Python executable not found at $PYTHON_PATH" >&2
    exit 1
fi

echo "=== Zeek Monitor Installation ==="
echo "Installing on Ubuntu 24.04 using Miniconda Python at $MINICONDA_PATH..."

# Copy Python script to system location
echo "Installing Zeek Monitor script to $SCRIPT_PATH..."
cp "$SCRIPT_DIR/zeek_monitor.py" "$SCRIPT_PATH"
chmod +x "$SCRIPT_PATH"

# Create a temporary modified service file with the correct username
TMP_SERVICE=$(mktemp)
cat "$SCRIPT_DIR/zeek-monitor.service" | sed "s/USERNAME/$MINICONDA_USER/g" > "$TMP_SERVICE"

# Copy the modified systemd service file
echo "Installing systemd service to $SERVICE_PATH..."
cp "$TMP_SERVICE" "$SERVICE_PATH"
rm "$TMP_SERVICE"


# Install required Python packages using Miniconda Python
echo "Installing required Python packages using Miniconda..."
sudo -u "$MINICONDA_USER" "$MINICONDA_PATH/bin/pip" install argparse

# Check if zeekctl is installed
if ! command -v zeekctl &> /dev/null; then
    echo "Warning: zeekctl command not found. Make sure Zeek is installed correctly."
    echo "The monitor service will still be installed, but won't be able to stop Zeek until zeekctl is available."
fi

# Reload systemd configuration
echo "Reloading systemd configuration..."
systemctl daemon-reload

# Enable and start the service
echo "Enabling and starting Zeek Monitor service..."
systemctl enable zeek-monitor.service
systemctl start zeek-monitor.service

# Check if service started successfully
if systemctl is-active --quiet zeek-monitor.service; then
    echo "✓ Zeek Monitor service has been successfully installed and started"
else
    echo "⚠ Zeek Monitor service was installed but failed to start. Check logs for details."
    systemctl status zeek-monitor.service
fi

echo ""
echo "=== Installation Summary ==="
echo "Script installed at: $SCRIPT_PATH"
echo "Service installed at: $SERVICE_PATH"
echo "Using Python from: $PYTHON_PATH"
echo ""
echo "Service status: $(systemctl is-active zeek-monitor.service)"
echo ""
echo "To check the logs, run: journalctl -u zeek-monitor.service"
echo "To stop the service, run: systemctl stop zeek-monitor.service"
echo "To start the service, run: systemctl start zeek-monitor.service"
echo "To restart the service, run: systemctl restart zeek-monitor.service"
echo "To check service status, run: systemctl status zeek-monitor.service"
echo "To view service configuration, run: systemctl cat zeek-monitor.service"
echo ""
echo "For updates, replace the files and run this script again."