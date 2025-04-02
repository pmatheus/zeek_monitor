#!/usr/bin/env python3

import os
import sys
import time
import subprocess
import argparse
import datetime
import re

def get_folder_size(folder_path):
    """Calculate the total size of a folder in bytes."""
    total_size = 0
    for dirpath, dirnames, filenames in os.walk(folder_path):
        for filename in filenames:
            file_path = os.path.join(dirpath, filename)
            if os.path.islink(file_path):
                continue
            total_size += os.path.getsize(file_path)
    return total_size

def convert_size_to_bytes(size_str):
    """Convert size string like '2MB', '1GB', '3.5TB' to bytes."""
    size_str = size_str.upper().strip()
    
    pattern = r'^(\d+(\.\d+)?)([KMGT]B)$'
    match = re.match(pattern, size_str)
    
    if not match:
        raise ValueError(f"Invalid size format: {size_str}. Expected format: '2MB', '1GB', '3.5TB'")
    
    value = float(match.group(1))
    unit = match.group(3)
    
    unit_multipliers = {
        'KB': 1024,
        'MB': 1024 ** 2,
        'GB': 1024 ** 3,
        'TB': 1024 ** 4
    }
    
    return value * unit_multipliers[unit]

def parse_datetime(datetime_str):
    """Parse datetime string in format 'YYYY-MM-DDThh:mm'."""
    try:
        return datetime.datetime.strptime(datetime_str, '%Y-%m-%dT%H:%M')
    except ValueError:
        raise ValueError(f"Invalid datetime format: {datetime_str}. Expected format: 'YYYY-MM-DDThh:mm'")

def stop_zeek():
    """Stop Zeek network capture using zeekctl stop with sudo."""
    try:
        # Check if script is running as root
        if os.geteuid() == 0:
            # Running as root, execute directly
            subprocess.run(['zeekctl', 'stop'], check=True)
        else:
            # Not running as root, use sudo
            subprocess.run(['sudo', 'zeekctl', 'stop'], check=True)
        
        print(f"{datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')} - Zeek stopped successfully")
        return True
    except subprocess.CalledProcessError as e:
        print(f"{datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')} - Failed to stop Zeek: {e}", file=sys.stderr)
        return False
    except FileNotFoundError:
        print(f"{datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')} - zeekctl command not found", file=sys.stderr)
        return False

def main():
    parser = argparse.ArgumentParser(description='Monitor /data folder size and stop Zeek if it exceeds a limit')
    parser.add_argument('size_limit', help='Size limit (e.g., 2MB, 1GB, 3.5TB)')
    parser.add_argument('--end-time', dest='end_time', help='Optional end time in format YYYY-MM-DDThh:mm')
    parser.add_argument('--folder', dest='folder_path', default='/data', help='Folder to monitor (default: /data)')
    parser.add_argument('--interval', dest='check_interval', type=int, default=60, 
                        help='Check interval in seconds (default: 60)')
    
    args = parser.parse_args()
    
    # Convert size limit to bytes
    try:
        size_limit_bytes = convert_size_to_bytes(args.size_limit)
        print(f"Size limit set to {args.size_limit} ({size_limit_bytes} bytes)")
    except ValueError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
    
    # Parse end time if provided
    end_time = None
    if args.end_time:
        try:
            end_time = parse_datetime(args.end_time)
            print(f"End time set to {end_time}")
        except ValueError as e:
            print(f"Error: {e}", file=sys.stderr)
            sys.exit(1)
    
    # Check if the folder exists
    if not os.path.isdir(args.folder_path):
        print(f"Error: Folder '{args.folder_path}' does not exist", file=sys.stderr)
        sys.exit(1)
    
    print(f"{datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')} - Started monitoring '{args.folder_path}'")
    
    try:
        while True:
            # Check size limit
            current_size = get_folder_size(args.folder_path)
            print(f"{datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')} - Current size: {current_size/1024/1024:.2f} MB")
            
            if current_size >= size_limit_bytes:
                print(f"{datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')} - Size limit reached ({args.size_limit})")
                if stop_zeek():
                    break
            
            # Check end time
            if end_time and datetime.datetime.now() >= end_time:
                print(f"{datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')} - End time reached")
                if stop_zeek():
                    break
            
            time.sleep(args.check_interval)
    
    except KeyboardInterrupt:
        print("\nMonitoring stopped by user")
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()