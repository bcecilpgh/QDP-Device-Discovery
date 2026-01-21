#!/bin/bash

# Q-SYS Browser Launcher - Uninstall Script
# Copyright (c) 2025 Brandon Cecil / Fresh AVL Co.

echo "============================================"
echo "Q-SYS Browser Launcher Uninstall"
echo "============================================"
echo ""

# Check if running with sudo
if [ "$EUID" -ne 0 ]; then 
    echo "This uninstaller needs administrator privileges."
    echo "Please run with: sudo ./uninstall.sh"
    exit 1
fi

# Define paths
INSTALL_DIR="/Library/Application Support/QSC"
PLIST_PATH="/Library/LaunchDaemons/com.qsc.browser-launcher.plist"

echo "This will remove the Q-SYS Browser Launcher service from your Mac."
echo ""
read -p "Are you sure you want to continue? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstall cancelled."
    exit 0
fi

echo ""
echo "Step 1: Stopping the service..."
if [ -f "$PLIST_PATH" ]; then
    launchctl unload "$PLIST_PATH" 2>/dev/null
    echo "✓ Service stopped"
else
    echo "⚠ LaunchDaemon not found (may already be removed)"
fi

echo ""
echo "Step 2: Removing LaunchDaemon configuration..."
if [ -f "$PLIST_PATH" ]; then
    rm "$PLIST_PATH"
    echo "✓ LaunchDaemon configuration removed"
else
    echo "⚠ LaunchDaemon already removed"
fi

echo ""
echo "Step 3: Removing installation directory..."
if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
    echo "✓ Installation directory removed"
else
    echo "⚠ Installation directory not found"
fi

echo ""
echo "============================================"
echo "Uninstall Complete!"
echo "============================================"
echo ""
echo "The Q-SYS Browser Launcher has been completely removed."
echo "The Q-SYS Designer plugin will still be in your designs,"
echo "but the 'Open Browser' button will no longer work."
echo ""
