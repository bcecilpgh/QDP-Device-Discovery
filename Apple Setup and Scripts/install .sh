#!/bin/bash

# Q-SYS Browser Launcher - Automated Installation Script
# Copyright (c) 2025 Brandon Cecil / Fresh AVL Co.

echo "============================================"
echo "Q-SYS Browser Launcher Installation"
echo "============================================"
echo ""

# Check if running with sudo
if [ "$EUID" -ne 0 ]; then 
    echo "This installer needs administrator privileges."
    echo "Please run with: sudo ./install.sh"
    exit 1
fi

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Define paths
INSTALL_DIR="/Library/Application Support/QSC"
SCRIPT_NAME="qsys_browser_launcher.py"
PLIST_NAME="com.qsc.browser-launcher.plist"
PLIST_PATH="/Library/LaunchDaemons/$PLIST_NAME"

echo "Step 1: Creating installation directory..."
mkdir -p "$INSTALL_DIR"
if [ $? -eq 0 ]; then
    echo "✓ Directory created: $INSTALL_DIR"
else
    echo "✗ Failed to create directory"
    exit 1
fi

echo ""
echo "Step 2: Copying browser launcher script..."
if [ -f "$SCRIPT_DIR/$SCRIPT_NAME" ]; then
    cp "$SCRIPT_DIR/$SCRIPT_NAME" "$INSTALL_DIR/"
    chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
    echo "✓ Script installed: $INSTALL_DIR/$SCRIPT_NAME"
else
    echo "✗ Error: $SCRIPT_NAME not found in current directory"
    echo "  Make sure you're running this script from the same folder as $SCRIPT_NAME"
    exit 1
fi

echo ""
echo "Step 3: Creating LaunchDaemon configuration..."
cat > "$PLIST_PATH" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.qsc.browser-launcher</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/python3</string>
        <string>/Library/Application Support/QSC/qsys_browser_launcher.py</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/Library/Application Support/QSC/browser_launcher.log</string>
    <key>StandardErrorPath</key>
    <string>/Library/Application Support/QSC/browser_launcher_error.log</string>
</dict>
</plist>
EOF

if [ $? -eq 0 ]; then
    echo "✓ LaunchDaemon configuration created"
else
    echo "✗ Failed to create LaunchDaemon configuration"
    exit 1
fi

echo ""
echo "Step 4: Starting the service..."
launchctl load "$PLIST_PATH"
if [ $? -eq 0 ]; then
    echo "✓ Service started successfully"
else
    echo "✗ Failed to start service"
    exit 1
fi

# Wait a moment for service to start
sleep 2

echo ""
echo "Step 5: Testing the service..."
if command -v curl &> /dev/null; then
    # Test the service
    RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null "http://localhost:8765?url=http://google.com" 2>&1)
    if [ "$RESPONSE" = "200" ]; then
        echo "✓ Service is running and responding correctly"
        echo "  (Google should have opened in your browser)"
    else
        echo "⚠ Service may not be responding correctly (HTTP $RESPONSE)"
        echo "  Check logs: tail -f '$INSTALL_DIR/browser_launcher.log'"
    fi
else
    echo "⚠ curl not found, skipping test"
fi

echo ""
echo "Step 6: Getting your Mac's IP address..."
IP_ADDRESS=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -n 1)
if [ -n "$IP_ADDRESS" ]; then
    echo "✓ Your Mac's IP address: $IP_ADDRESS"
else
    echo "⚠ Could not determine IP address automatically"
    echo "  Run: ifconfig | grep 'inet ' | grep -v 127.0.0.1"
fi

echo ""
echo "============================================"
echo "Installation Complete!"
echo "============================================"
echo ""
echo "Next Steps:"
echo "1. Open Q-SYS Designer"
echo "2. Add the QSC Device Discovery plugin to your design"
echo "3. Set plugin properties:"
echo "   - Mac IP Address: $IP_ADDRESS"
echo "   - Service Port: 8765"
echo "4. Emulate and test!"
echo ""
echo "Service Details:"
echo "- Status: Running"
echo "- Port: 8765"
echo "- Log file: $INSTALL_DIR/browser_launcher.log"
echo ""
echo "To check service status:"
echo "  sudo launchctl list | grep qsc"
echo ""
echo "To view logs:"
echo "  tail -f '$INSTALL_DIR/browser_launcher.log'"
echo ""
echo "To uninstall:"
echo "  sudo launchctl unload $PLIST_PATH"
echo "  sudo rm $PLIST_PATH"
echo "  sudo rm -rf '$INSTALL_DIR'"
echo ""
