# Q-SYS Device Discovery with Browser Launch

This system allows you to discover Q-SYS devices on your network and automatically open their web interfaces in your Mac's default browser with a single click from Q-SYS Designer.

## What You Need

- Mac with macOS (M1 or Intel)
- Q-SYS Designer installed
- Both files from this package

## Installation

### Step 1: Install the Browser Service on Your Mac

1. **Create the QSC folder** (if it doesn't exist)
   
   Open Terminal and run:
   ```bash
   sudo mkdir -p "/Library/Application Support/QSC"
   ```
   Enter your Mac password when prompted.

2. **Copy the Python script**
   
   Drag `qsys_browser_launcher.py` to your Desktop, then run:
   ```bash
   sudo cp ~/Desktop/qsys_browser_launcher.py "/Library/Application Support/QSC/"
   sudo chmod +x "/Library/Application Support/QSC/qsys_browser_launcher.py"
   ```

3. **Test that it works**
   
   ```bash
   python3 "/Library/Application Support/QSC/qsys_browser_launcher.py"
   ```
   
   You should see:
   ```
   Q-SYS Browser Launcher Service
   ===============================
   Listening on: http://localhost:8765
   ```
   
   Press `Ctrl+C` to stop it for now.

4. **Get your Mac's IP address**
   
   ```bash
   ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}'
   ```
   
   Write down the IP address (e.g., 192.168.1.100)

### Step 2: Set Up Automatic Startup

1. **Create the startup file**
   
   ```bash
   sudo nano /Library/LaunchDaemons/com.qsc.browser-launcher.plist
   ```

2. **Paste this content** (press Cmd+V):
   
   ```xml
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
   ```

3. **Save and exit**
   - Press `Ctrl+X`
   - Press `Y`
   - Press `Enter`

4. **Start the service**
   
   ```bash
   sudo launchctl load /Library/LaunchDaemons/com.qsc.browser-launcher.plist
   ```

5. **Verify it's running**
   
   ```bash
   curl http://localhost:8765?url=http://google.com
   ```
   
   This should open Google in your browser. If it does, the service is working!

### Step 3: Install the Q-SYS Plugin

1. **Open Q-SYS Designer**

2. **Drag the plugin** (`QSC_Device_Discovery_URL_Enhanced.qplug`) into your design

3. **Configure the plugin**
   - Right-click the plugin → **Properties**
   - Set **Mac IP Address** to the IP from Step 1.4
   - Set **Service Port** to `8765`
   - Click **OK**

4. **Emulate or run** your design

## Using the Plugin

1. **Scan for devices**
   - Click "Scan Network"
   - Wait 15 seconds

2. **Open a device's web interface**
   - Use the knob to select a device number
   - Click "Get URL" (optional - just to see the URL)
   - Click "Open Browser"
   - The device's web page opens in your Mac's browser!

## Managing the Service

### Check if the service is running
```bash
sudo launchctl list | grep qsc
```

### Stop the service
```bash
sudo launchctl unload /Library/LaunchDaemons/com.qsc.browser-launcher.plist
```

### Start the service
```bash
sudo launchctl load /Library/LaunchDaemons/com.qsc.browser-launcher.plist
```

### View the logs
```bash
tail -f "/Library/Application Support/QSC/browser_launcher.log"
```

### Uninstall completely
```bash
sudo launchctl unload /Library/LaunchDaemons/com.qsc.browser-launcher.plist
sudo rm /Library/LaunchDaemons/com.qsc.browser-launcher.plist
sudo rm "/Library/Application Support/QSC/qsys_browser_launcher.py"
```

## Troubleshooting

### Browser doesn't open

**Test the service directly:**
```bash
curl "http://localhost:8765?url=http://192.168.1.50"
```
If this works, the issue is with Q-SYS network configuration.

**Check if service is running:**
```bash
sudo launchctl list | grep qsc
```
Should show the service with a PID number.

**Check the logs:**
```bash
cat "/Library/Application Support/QSC/browser_launcher.log"
```

**Restart the service:**
```bash
sudo launchctl unload /Library/LaunchDaemons/com.qsc.browser-launcher.plist
sudo launchctl load /Library/LaunchDaemons/com.qsc.browser-launcher.plist
```

### Wrong IP address

If your Mac's IP changes (different network, DHCP renewal):
1. Get the new IP: `ifconfig | grep "inet " | grep -v 127.0.0.1`
2. Update the plugin properties in Q-SYS Designer
3. No need to restart the service

### Firewall blocking connections

**Allow Python through firewall:**
- System Preferences → Security & Privacy → Firewall → Firewall Options
- Add Python to allowed apps

**Or use hostname instead:**
- In plugin properties, try using your Mac's hostname:
  ```bash
  hostname
  ```
  Use this instead of IP (e.g., "brandons-macbook.local")

## Technical Notes

- **Location:** `/Library/Application Support/QSC/qsys_browser_launcher.py`
- **LaunchDaemon:** `/Library/LaunchDaemons/com.qsc.browser-launcher.plist`
- **Logs:** `/Library/Application Support/QSC/browser_launcher.log`
- **Default Port:** 8765
- **Protocol:** HTTP GET with URL parameter

## Support

For issues:
1. Check Q-SYS Designer debug output
2. Check service logs (see above)
3. Test service directly with curl
4. Verify network connectivity

---

**License:** MIT License  
**Author:** Brandon Cecil / Fresh AVL Co.  
**Copyright:** 2025
