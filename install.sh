#!/bin/bash

# This script installs the Zeek Monitor as a service
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

# Variables
SCRIPT_PATH=/usr/local/bin/zeek_monitor.py
SERVICE_PATH=/etc/systemd/system/zeek-monitor.service
LOG_PATH=/var/log/zeek-monitor.log

echo "=== Zeek Monitor Installation ==="
echo "Installing on Ubuntu 24.04..."

# Copy Python script to system location
echo "Installing Zeek Monitor script to $SCRIPT_PATH..."
cp "$SCRIPT_DIR/zeek_monitor.py" "$SCRIPT_PATH"
chmod +x "$SCRIPT_PATH"

# Copy systemd service file
echo "Installing systemd service to $SERVICE_PATH..."
cp "$SCRIPT_DIR/zeek-monitor.service" "$SERVICE_PATH"

# Create log file if it doesn't exist
touch "$LOG_PATH"
chmod 644 "$LOG_PATH"

# Install required Python packages
echo "Installing required Python packages..."
if command -v apt-get &> /dev/null; then
    apt-get update -qq
    apt-get install -y python3 python3-pip
    pip3 install argparse
fi

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
echo "Log file: $LOG_PATH"
echo ""
echo "Service status: $(systemctl is-active zeek-monitor.service)"
echo ""
echo "To check the logs, run: tail -f $LOG_PATH"
echo "To check service status, run: systemctl status zeek-monitor.service"
echo "To view or modify service configuration, run: systemctl cat zeek-monitor.service"
echo "To modify settings, edit $SERVICE_PATH and then run: systemctl daemon-reload && systemctl restart zeek-monitor.service"
echo ""
echo "For updates, replace the files and run this script again."