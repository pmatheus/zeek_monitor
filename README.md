# Zeek Monitor

A monitoring solution that automatically stops Zeek network traffic capture when the data folder reaches a specified size limit or at a scheduled time.

## Overview

This tool monitors the size of a directory (where zeek is saving data) and automatically stops Zeek traffic capture using `zeekctl stop` when the directory size exceeds a specified limit or when a scheduled end time is reached.

## Repository Contents

- `zeek_monitor.py` - Python script for monitoring folder size
- `zeek-monitor.service` - Systemd service file
- `install.sh` - Installation script for Ubuntu 24.04
- `README.md` - This documentation file

## Requirements

- Ubuntu 24.04 (may work on other distributions)
- Miniconda installed in the user's home directory
- Zeek installed with `zeekctl` available
- Root privileges for installation and execution

## Quick Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/zeek-monitor.git
cd zeek-monitor
```
edit zeek-monitor.service with your desired settings

# Run the installation script as root
```bash
sudo ./install.sh
```

## Manual Setup

If you prefer to install manually:

1. Copy `zeek_monitor.py` to `/usr/local/bin/` and make it executable:
   ```bash
   sudo cp zeek_monitor.py /usr/local/bin/
   sudo chmod +x /usr/local/bin/zeek_monitor.py
   ```

2. Copy the service file to systemd directory:
   ```bash
   sudo cp zeek-monitor.service /etc/systemd/system/
   ```

3. Edit the service file to configure your preferred settings:
   ```bash
   sudo nano /etc/systemd/system/zeek-monitor.service
   ```

4. Enable and start the service:
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable zeek-monitor.service
   sudo systemctl start zeek-monitor.service
   ```

## Configuration

In the `ExecStart` line of zeek-monitor.service, modify the parameters:

```
ExecStart=/usr/local/bin/zeek_monitor.py 3.5TB --folder /data --interval 60
```

Parameters:
- First parameter: Size limit (e.g., `2MB`, `1GB`, `3.5TB`)
- `--folder`: Directory to monitor (default: `/data`)
- `--interval`: Check interval in seconds (default: 60)
- `--end-time`: Optional end time (format: YYYY-MM-DDThh:mm)

After making changes, reload and restart the service:

## Running Manually

You can also run the script manually without installing as a service:

```bash
# Python script:
sudo python3 zeek_monitor.py 2GB --folder /data --interval 60 --end-time 2025-04-10T15:30
```

## Monitoring and Troubleshooting

Check service status:
```bash
sudo systemctl status zeek-monitor.service
```

View logs:
```bash
sudo journalctl -u zeek-monitor.service
```

## License

MIT License

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.