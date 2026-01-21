# QSC Device Discovery Plugin with Browser Launch

A powerful Q-SYS Designer plugin that automatically discovers and displays all Q-SYS devices on your network using the Q-SYS Discovery Protocol (QDP), with one-click browser access to device web interfaces.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Q-SYS Designer](https://img.shields.io/badge/Q--SYS%20Designer-v9.0%2B-green.svg)](https://www.qsc.com/solutions-products/q-sys-ecosystem/q-sys-designer-software/)
[![Lua](https://img.shields.io/badge/Lua-5.3-blue.svg)](https://www.lua.org/)

---

## Overview

The QSC Device Discovery Plugin passively listens for Q-SYS Discovery Protocol (QDP) announcements broadcast by Q-SYS Cores, I/O Frames, and other network devices. It provides a simple interface to discover, filter, and manage Q-SYS devices on your network without requiring manual IP configuration.

**NEW:** Includes automatic browser launch integration for **macOS and Windows** - open device web interfaces with a single click from Q-SYS Designer!

> **Note:** This plugin requires deployment to a QSC Core processor. The UDP socket operations used for device discovery are only available when running on Core hardware, not in Q-SYS Designer's Emulation Mode.

### Key Features

- **Automatic Discovery** - Passively listens for QDP announcements on multicast address 224.0.23.175
- **Device Information** - Displays hostname, IP address, and part number for each device
- **Advanced Filtering** - 10 configurable filter slots to exclude unwanted devices
- **Browser Launch** - One-click access to device web interfaces (macOS & Windows)
- **Fast Scanning** - 5-second scan with automatic socket cleanup
- **Real-Time Updates** - Device list updates as announcements are received
- **Debug Logging** - Comprehensive debug output for troubleshooting

---

## Quick Start

### Standard Installation (Discovery Only)

1. **Download** the plugin (`QSC_Device_Discovery_URL_Enhanced.qplug`)
2. **Add to Q-SYS Designer** - Drag into your design
3. **Deploy to Core** - This plugin requires a QSC Core processor and will not function in Emulation Mode
4. **Scan Network** - Click the button and wait 5 seconds
5. **View Results** - See all discovered devices

### Browser Launch Installation (macOS Only)

For automatic browser launching capability:

1. **Download all files** from the release
2. **Run the installer:**
   ```bash
   cd /path/to/downloaded/files
   sudo ./install.sh
   ```
3. **Note your Mac's IP** (shown at end of install)
4. **Configure plugin** in Q-SYS Designer:
   - Right-click plugin → Properties
   - Set "Mac IP Address" to your Mac's IP
   - Click OK
5. **Use it:**
   - Scan Network → Select device → Click "Open Browser"

---

## Installation

### Prerequisites

- Q-SYS Designer v9.0 or later
- **QSC Core processor** (Core 110f, Core 510i, Core Nano, etc.) - plugin will not function in Emulation Mode
- Network with multicast support (IGMP)
- UDP port 2467 available
- **For browser launch:** macOS with Python 3 (pre-installed) OR Windows 10/11 with PowerShell (built-in)

### Plugin Installation

1. **Copy** `QSC_Device_Discovery_URL_Enhanced.qplug` to your Q-SYS Plugins folder:
   - **Windows**: `%USERPROFILE%\Documents\QSC\Q-Sys Designer\Plugins`
   - **macOS**: `~/Documents/QSC/Q-Sys Designer/Plugins`
2. **Open** Q-SYS Designer
3. **Add** the plugin to your design:
   - Search for "QSC Device Discovery" in the component search
   - Drag it onto your schematic
4. **Deploy** your design to a QSC Core processor
5. **Double-click** the component to open the control panel

### Browser Launch Installation (macOS & Windows)

The browser launch feature requires a small background service on your computer.

#### macOS (Automated Installation)

```bash
sudo ./install.sh
```

This installs the service to `/Library/Application Support/QSC/` and configures it to start automatically on boot.

#### Windows (Simple Startup)

1. **Extract files** to a folder (e.g., `C:\QSC\BrowserLauncher\`)
2. **Double-click** `start_browser_service.bat`
3. Service starts (no installation required!)

See [WINDOWS_SETUP_INSTRUCTIONS.md](WINDOWS_SETUP_INSTRUCTIONS.md) for auto-start on boot, firewall config, and advanced options.

#### Manual Installation

See [SETUP_INSTRUCTIONS.md](SETUP_INSTRUCTIONS.md) (macOS) or [WINDOWS_SETUP_INSTRUCTIONS.md](WINDOWS_SETUP_INSTRUCTIONS.md) (Windows) for detailed manual installation steps.

---

## Usage

### Basic Discovery

1. Click the **Scan Network** button
2. Wait 5 seconds for discovery to complete
3. View discovered devices in the device list

Each device entry shows:
```
1. device-hostname (Part-Number) - 192.168.1.100
```

### Opening Device Web Interfaces

**With Browser Launch Service (macOS or Windows):**

1. **Scan** for devices
2. **Turn the Device # knob** to select a device (URL auto-populates)
3. **Click "Open Browser"** - Device web interface opens automatically!

**Without Browser Launch Service:**

1. **Scan** for devices
2. **Turn the Device # knob** to select a device
3. **Copy/paste** the URL from the display into your browser manually

### Using Filters

Filters exclude devices from the results based on partial text matching against hostname, IP address, or part number.

**Examples:**

| Filter Text | Excludes |
|------------|----------|
| `192.168.1` | All devices in the 192.168.1.x subnet |
| `burnin` | Any device with "burnin" in the hostname |
| `QIO` | All QIO series devices |
| `Core Nano` | All Core Nano devices |
| `.234` | Devices ending in .234 |

**To use filters:**
1. Enter text in any Filter 1-10 field
2. Device list updates automatically
3. Leave filter fields empty to show all devices

---

## How It Works

### Q-SYS Discovery Protocol (QDP)

QDP is a method where Q-SYS devices broadcast periodic UDP packets to announce their presence:

- **Protocol**: UDP Multicast
- **Multicast Address**: 224.0.23.175
- **Port**: 2467
- **Broadcast Interval**: ~1 second
- **Format**: XML

### Example QDP Packet

```xml
<QDP>
  <device>
    <n>audio-core-main</n>
    <type>lcqln</type>
    <part_number>Core 110f</part_number>
    <lan_a_ip>192.168.1.100</lan_a_ip>
    <lan_a_mac>00:60:74:xx:xx:xx</lan_a_mac>
    ...
  </device>
</QDP>
```

The plugin passively listens for these announcements and parses the XML to extract device information.

### Browser Launch Architecture

```
Q-SYS Designer Plugin
        |
   HTTP Request (device URL)
        |
Mac Service (localhost:8765)
        |
   macOS 'open' command
        |
  Default Browser Opens
```

The Mac service runs as a system daemon and receives HTTP requests from the Q-SYS plugin. When a request is received, it uses macOS's native `open` command to launch the device URL in your default browser.

**Service Details:**
- **Location**: `/Library/Application Support/QSC/qsys_browser_launcher.py`
- **Auto-start**: Configured via LaunchDaemon (starts on boot)
- **Port**: 8765 (configurable)
- **Protocol**: HTTP GET with URL parameter

---

## Configuration

### Network Requirements

- **Same Network Segment**: Plugin must be on the same subnet as target devices, or multicast must be routed
- **Multicast Support**: Network switches must support and forward multicast traffic (IGMP)
- **Port Availability**: UDP port 2467 must not be blocked or in use
- **Firewall**: Allow UDP port 2467 inbound

### Plugin Properties

Right-click the plugin and select "Properties" to configure:

- **Mac IP Address** - IP address of the Mac running the browser service (default: 192.168.1.100)
- **Service Port** - Port number for the browser service (default: 8765)

---

## Troubleshooting

### Discovery Issues

#### No Devices Discovered

**Problem**: Scan completes but shows "Found 0 devices"

**Solutions**:
1. Verify network connectivity (ping a known device)
2. Check if multicast is supported on your switch (IGMP)
3. Ensure port 2467 is not blocked by firewall
4. Confirm devices are powered on and connected
5. Check Debug Output in Q-SYS Designer for error messages
6. **Confirm design is deployed to a Core** - discovery will not work in Emulation Mode

#### Some Devices Missing

**Problem**: Some known devices don't appear

**Solutions**:
1. Check if devices are filtered by active filters
2. Wait a few seconds after device boot before scanning
3. Verify devices are on the same network segment
4. Some older device types may not broadcast QDP

#### Port Already in Use

**Problem**: Error message "Failed to open UDP port"

**Solutions**:
1. Close Q-SYS Designer's built-in discovery window
2. Check for other applications using port 2467
3. Restart Q-SYS Designer
4. Run Q-SYS Designer as administrator (Windows)

### Browser Launch Issues

#### Browser Doesn't Open

**Test the service directly:**
```bash
curl "http://localhost:8765?url=http://google.com"
```
This should open Google in your browser.

**Check if service is running:**
```bash
sudo launchctl list | grep qsc
```
Should show the service with a PID number.

**View service logs:**
```bash
tail -f "/Library/Application Support/QSC/browser_launcher.log"
```

**Restart the service:**
```bash
sudo launchctl unload /Library/LaunchDaemons/com.qsc.browser-launcher.plist
sudo launchctl load /Library/LaunchDaemons/com.qsc.browser-launcher.plist
```

#### Wrong IP Address

If your Mac's IP changes (different network, DHCP renewal):
1. Get the new IP: `ifconfig | grep "inet " | grep -v 127.0.0.1`
2. Update the plugin properties in Q-SYS Designer
3. No need to restart the service

#### Firewall Blocking

**Allow Python through firewall:**
- System Preferences → Security & Privacy → Firewall → Firewall Options
- Add Python to allowed apps

**Or use hostname instead:**
```bash
hostname
```
Use this in plugin properties instead of IP (e.g., "brandons-macbook.local")

### Debug Logging

Enable debug output: **View → Debug Output** in Q-SYS Designer

Look for messages prefixed with `[QSC Discovery]` for detailed troubleshooting information.

---

## Managing the Browser Service

### Check Status
```bash
sudo launchctl list | grep qsc
```

### Stop Service
```bash
sudo launchctl unload /Library/LaunchDaemons/com.qsc.browser-launcher.plist
```

### Start Service
```bash
sudo launchctl load /Library/LaunchDaemons/com.qsc.browser-launcher.plist
```

### View Logs
```bash
tail -f "/Library/Application Support/QSC/browser_launcher.log"
```

### Uninstall Completely
```bash
sudo ./uninstall.sh
```

Or manually:
```bash
sudo launchctl unload /Library/LaunchDaemons/com.qsc.browser-launcher.plist
sudo rm /Library/LaunchDaemons/com.qsc.browser-launcher.plist
sudo rm -rf "/Library/Application Support/QSC"
```

---

## Files Included

**Q-SYS Plugin:**
- **QSC_Device_Discovery_URL_Enhanced.qplug** - Q-SYS Designer plugin

**macOS Browser Service:**
- **qsys_browser_launcher.py** - Mac browser service (Python script)
- **install.sh** - Automated installer for Mac
- **uninstall.sh** - Automated uninstaller

**Windows Browser Service:**
- **qsys_browser_launcher_windows.py** - Windows Python service
- **qsys_browser_launcher.ps1** - Windows PowerShell service (no install required)
- **start_browser_service.bat** - Easy double-click launcher

**Documentation:**
- **README.md** - This file
- **SETUP_INSTRUCTIONS.md** - Detailed macOS installation guide
- **WINDOWS_SETUP_INSTRUCTIONS.md** - Detailed Windows installation guide

---

## Technical Details

### Plugin Architecture

```
Plugin (UDP Socket) → Listens on 0.0.0.0:2467
                    |
         Receives QDP Announcements
                    |
              Parse XML Data
                    |
           Apply Filters (if any)
                    |
         Update Device Registry
                    |
       Display in Device List
                    |
    User Selects Device (Optional)
                    |
     HTTP Request to Mac Service
                    |
        Browser Opens Device URL
```

### Platform Requirements

This plugin requires deployment to a QSC Core processor and will not function when running in Emulation Mode within Q-SYS Designer on a PC or Mac. The UDP socket operations used for device discovery are only available when the design is running on actual Core hardware.

Supported Core processors include:
- Core 110f
- Core 510i
- Core Nano
- Core 8 Flex
- And other Q-SYS Core processors

### API Limitations

- Q-SYS Lua environment does not support `JoinMulticastGroup()`
- Plugin relies on OS-level multicast handling
- No reverse DNS lookup capability
- Single network interface binding
- Browser launch requires external service (security limitation)
- **UDP sockets only available on Core hardware, not in Emulation Mode**

### Security Considerations

- Browser service listens on all network interfaces (0.0.0.0)
- Any device on your network can send URLs to open
- Service only accepts HTTP/HTTPS URLs
- Consider firewall rules to restrict access to specific IPs
- Service runs as system daemon (not user-level)

---

## Contributing

Contributions are welcome! This is an open-source project under the MIT License.

### How to Contribute

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Contribution Guidelines

- Follow existing code style and conventions
- Add debug logging for new features
- Test changes thoroughly in Q-SYS Designer
- Update documentation for new features
- Be respectful and constructive

### Reporting Issues

Found a bug or have a feature request? Please open an [issue](../../issues) with:
- Q-SYS Designer version
- Plugin version (check PluginInfo.Version in the .qplug file)
- Network configuration details
- Debug log output (if applicable)
- Steps to reproduce the issue
- Operating system (for browser launch issues)

---

## Roadmap

### Planned Features

- [ ] Linux browser launch support
- [ ] Active query mode (send requests to trigger responses)
- [ ] Persistent device list (accumulate across scans)
- [ ] CSV/JSON export functionality
- [ ] Historical device tracking (up/down events)
- [ ] Regex support for filters
- [ ] Device details view (full XML data)
- [ ] Configurable scan duration

### Future Enhancements

- Network ping integration
- Device reachability verification
- Multi-subnet discovery support
- Save/load filter presets
- Device status monitoring
- Alert on device offline/online

---

## Version History

### v2.5 (Current)
- **NEW:** Windows browser launch support (PowerShell & Python)
- **NEW:** Cross-platform service architecture
- **Removed:** "Get URL" button (redundant - knob auto-populates URL)
- **Improved:** Cleaner user workflow (select device → open browser)
- **Changed:** UI layout simplified

### v2.4
- **Changed:** Scan time reduced from 15 to 5 seconds
- **Improved:** Faster network discovery

### v2.3
- **NEW:** Browser launch integration for macOS
- **NEW:** Mac service installer and auto-startup configuration
- Fixed hostname parsing (enhanced XML tag detection)
- Improved fallback logic for missing hostname data
- Enhanced debug output (500 char packet preview)
- Added device selection controls
- Reduced scan time from 15 to 5 seconds

### v2.2
- Added HTTP client for browser launch requests
- Added plugin properties for Mac IP and service port
- Added "Open Browser" button

### v2.1
- Added device selector knob
- Added URL display field
- Added device info display

### v2.0
- Added 10 configurable filters
- Implemented real-time filter updates
- Fixed continuous packet reception bug
- Improved XML parsing robustness
- Enhanced debug logging
- Updated UI with filter section

### v1.0
- Initial release
- Basic QDP listening
- XML parsing for hostname and IP
- 15-second scan timer
- Status indicators

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

### MIT License Summary

```
Copyright (c) 2025 Brandon Cecil / Fresh AVL Co.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
```

---

## Contact

**Author**: Brandon Cecil  
**Company**: Fresh AVL Co.  
**Project Link**: https://github.com/bcecilpgh/QDP-Device-Discovery

---

## Support

If you find this plugin useful, please:
- Star this repository
- Report bugs via [Issues](../../issues)
- Suggest features via [Issues](../../issues)
- Contribute via [Pull Requests](../../pulls)
- Share with other Q-SYS users

---

## Acknowledgments

- QSC for the Q-SYS ecosystem and comprehensive API documentation
- The Q-SYS community for feedback and testing
- macOS for providing the `open` command for browser integration

---

## Disclaimer

This plugin is provided "as-is" without warranty. Use at your own risk. Always test in a non-production environment before deploying to live systems.

Q-SYS, Q-SYS Designer, and related trademarks are property of QSC, LLC. This plugin is an independent project and is not affiliated with or endorsed by QSC.

---

**Built for the Q-SYS community**# QSC Device Discovery Plugin with Browser Launch

A powerful Q-SYS Designer plugin that automatically discovers and displays all Q-SYS devices on your network using the Q-SYS Discovery Protocol (QDP), with one-click browser access to device web interfaces.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Q-SYS Designer](https://img.shields.io/badge/Q--SYS%20Designer-v9.0%2B-green.svg)](https://www.qsc.com/solutions-products/q-sys-ecosystem/q-sys-designer-software/)
[![Lua](https://img.shields.io/badge/Lua-5.3-blue.svg)](https://www.lua.org/)

---

## Overview

The QSC Device Discovery Plugin passively listens for Q-SYS Discovery Protocol (QDP) announcements broadcast by Q-SYS Cores, I/O Frames, and other network devices. It provides a simple interface to discover, filter, and manage Q-SYS devices on your network without requiring manual IP configuration.

**NEW:** Includes automatic browser launch integration for **macOS and Windows** - open device web interfaces with a single click from Q-SYS Designer!

### Key Features

- **Automatic Discovery** - Passively listens for QDP announcements on multicast address 224.0.23.175
- **Device Information** - Displays hostname, IP address, and part number for each device
- **Advanced Filtering** - 10 configurable filter slots to exclude unwanted devices
- **Browser Launch** - One-click access to device web interfaces (macOS & Windows)
- **Fast Scanning** - 5-second scan with automatic socket cleanup
- **Real-Time Updates** - Device list updates as announcements are received
- **Debug Logging** - Comprehensive debug output for troubleshooting

---

## Quick Start

### Standard Installation (Discovery Only)

1. **Download** the plugin (`QSC_Device_Discovery_URL_Enhanced.qplug`)
2. **Add to Q-SYS Designer** - Drag into your design
3. **Scan Network** - Click the button and wait 5 seconds
4. **View Results** - See all discovered devices

### Browser Launch Installation (macOS Only)

For automatic browser launching capability:

1. **Download all files** from the release
2. **Run the installer:**
   ```bash
   cd /path/to/downloaded/files
   sudo ./install.sh
   ```
3. **Note your Mac's IP** (shown at end of install)
4. **Configure plugin** in Q-SYS Designer:
   - Right-click plugin → Properties
   - Set "Mac IP Address" to your Mac's IP
   - Click OK
5. **Use it:**
   - Scan Network → Select device → Click "Open Browser"

---

## Installation

### Prerequisites

- Q-SYS Designer v9.0 or later
- Network with multicast support (IGMP)
- UDP port 2467 available
- **For browser launch:** macOS with Python 3 (pre-installed) OR Windows 10/11 with PowerShell (built-in)

### Plugin Installation

1. **Copy** `QSC_Device_Discovery_URL_Enhanced.qplug` to your Q-SYS Plugins folder:
   - **Windows**: `%USERPROFILE%\Documents\QSC\Q-Sys Designer\Plugins`
   - **macOS**: `~/Documents/QSC/Q-Sys Designer/Plugins`
2. **Open** Q-SYS Designer
3. **Add** the plugin to your design:
   - Search for "QSC Device Discovery" in the component search
   - Drag it onto your schematic
4. **Double-click** the component to open the control panel

### Browser Launch Installation (macOS & Windows)

The browser launch feature requires a small background service on your computer.

#### macOS (Automated Installation)

```bash
sudo ./install.sh
```

This installs the service to `/Library/Application Support/QSC/` and configures it to start automatically on boot.

#### Windows (Simple Startup)

1. **Extract files** to a folder (e.g., `C:\QSC\BrowserLauncher\`)
2. **Double-click** `start_browser_service.bat`
3. Service starts (no installation required!)

See [WINDOWS_SETUP_INSTRUCTIONS.md](WINDOWS_SETUP_INSTRUCTIONS.md) for auto-start on boot, firewall config, and advanced options.

#### Manual Installation

See [SETUP_INSTRUCTIONS.md](SETUP_INSTRUCTIONS.md) (macOS) or [WINDOWS_SETUP_INSTRUCTIONS.md](WINDOWS_SETUP_INSTRUCTIONS.md) (Windows) for detailed manual installation steps.

---

## Usage

### Basic Discovery

1. Click the **Scan Network** button
2. Wait 5 seconds for discovery to complete
3. View discovered devices in the device list

Each device entry shows:
```
1. device-hostname (Part-Number) - 192.168.1.100
```

### Opening Device Web Interfaces

**With Browser Launch Service (macOS or Windows):**

1. **Scan** for devices
2. **Turn the Device # knob** to select a device (URL auto-populates)
3. **Click "Open Browser"** - Device web interface opens automatically!

**Without Browser Launch Service:**

1. **Scan** for devices
2. **Turn the Device # knob** to select a device
3. **Copy/paste** the URL from the display into your browser manually

### Using Filters

Filters exclude devices from the results based on partial text matching against hostname, IP address, or part number.

**Examples:**

| Filter Text | Excludes |
|------------|----------|
| `192.168.1` | All devices in the 192.168.1.x subnet |
| `burnin` | Any device with "burnin" in the hostname |
| `QIO` | All QIO series devices |
| `Core Nano` | All Core Nano devices |
| `.234` | Devices ending in .234 |

**To use filters:**
1. Enter text in any Filter 1-10 field
2. Device list updates automatically
3. Leave filter fields empty to show all devices

---

## How It Works

### Q-SYS Discovery Protocol (QDP)

QDP is a method where Q-SYS devices broadcast periodic UDP packets to announce their presence:

- **Protocol**: UDP Multicast
- **Multicast Address**: 224.0.23.175
- **Port**: 2467
- **Broadcast Interval**: ~1 second
- **Format**: XML

### Example QDP Packet

```xml
<QDP>
  <device>
    <n>audio-core-main</n>
    <type>lcqln</type>
    <part_number>Core 110f</part_number>
    <lan_a_ip>192.168.1.100</lan_a_ip>
    <lan_a_mac>00:60:74:xx:xx:xx</lan_a_mac>
    ...
  </device>
</QDP>
```

The plugin passively listens for these announcements and parses the XML to extract device information.

### Browser Launch Architecture

```
Q-SYS Designer Plugin
        ↓
   HTTP Request (device URL)
        ↓
Mac Service (localhost:8765)
        ↓
   macOS 'open' command
        ↓
  Default Browser Opens
```

The Mac service runs as a system daemon and receives HTTP requests from the Q-SYS plugin. When a request is received, it uses macOS's native `open` command to launch the device URL in your default browser.

**Service Details:**
- **Location**: `/Library/Application Support/QSC/qsys_browser_launcher.py`
- **Auto-start**: Configured via LaunchDaemon (starts on boot)
- **Port**: 8765 (configurable)
- **Protocol**: HTTP GET with URL parameter

---

## Configuration

### Network Requirements

- **Same Network Segment**: Plugin must be on the same subnet as target devices, or multicast must be routed
- **Multicast Support**: Network switches must support and forward multicast traffic (IGMP)
- **Port Availability**: UDP port 2467 must not be blocked or in use
- **Firewall**: Allow UDP port 2467 inbound

### Plugin Properties

Right-click the plugin and select "Properties" to configure:

- **Mac IP Address** - IP address of the Mac running the browser service (default: 192.168.1.100)
- **Service Port** - Port number for the browser service (default: 8765)

---

## Troubleshooting

### Discovery Issues

#### No Devices Discovered

**Problem**: Scan completes but shows "Found 0 devices"

**Solutions**:
1. Verify network connectivity (ping a known device)
2. Check if multicast is supported on your switch (IGMP)
3. Ensure port 2467 is not blocked by firewall
4. Confirm devices are powered on and connected
5. Check Debug Output in Q-SYS Designer for error messages

#### Some Devices Missing

**Problem**: Some known devices don't appear

**Solutions**:
1. Check if devices are filtered by active filters
2. Wait a few seconds after device boot before scanning
3. Verify devices are on the same network segment
4. Some older device types may not broadcast QDP

#### Port Already in Use

**Problem**: Error message "Failed to open UDP port"

**Solutions**:
1. Close Q-SYS Designer's built-in discovery window
2. Check for other applications using port 2467
3. Restart Q-SYS Designer
4. Run Q-SYS Designer as administrator (Windows)

### Browser Launch Issues

#### Browser Doesn't Open

**Test the service directly:**
```bash
curl "http://localhost:8765?url=http://google.com"
```
This should open Google in your browser.

**Check if service is running:**
```bash
sudo launchctl list | grep qsc
```
Should show the service with a PID number.

**View service logs:**
```bash
tail -f "/Library/Application Support/QSC/browser_launcher.log"
```

**Restart the service:**
```bash
sudo launchctl unload /Library/LaunchDaemons/com.qsc.browser-launcher.plist
sudo launchctl load /Library/LaunchDaemons/com.qsc.browser-launcher.plist
```

#### Wrong IP Address

If your Mac's IP changes (different network, DHCP renewal):
1. Get the new IP: `ifconfig | grep "inet " | grep -v 127.0.0.1`
2. Update the plugin properties in Q-SYS Designer
3. No need to restart the service

#### Firewall Blocking

**Allow Python through firewall:**
- System Preferences → Security & Privacy → Firewall → Firewall Options
- Add Python to allowed apps

**Or use hostname instead:**
```bash
hostname
```
Use this in plugin properties instead of IP (e.g., "brandons-macbook.local")

### Debug Logging

Enable debug output: **View → Debug Output** in Q-SYS Designer

Look for messages prefixed with `[QSC Discovery]` for detailed troubleshooting information.

---

## Managing the Browser Service

### Check Status
```bash
sudo launchctl list | grep qsc
```

### Stop Service
```bash
sudo launchctl unload /Library/LaunchDaemons/com.qsc.browser-launcher.plist
```

### Start Service
```bash
sudo launchctl load /Library/LaunchDaemons/com.qsc.browser-launcher.plist
```

### View Logs
```bash
tail -f "/Library/Application Support/QSC/browser_launcher.log"
```

### Uninstall Completely
```bash
sudo ./uninstall.sh
```

Or manually:
```bash
sudo launchctl unload /Library/LaunchDaemons/com.qsc.browser-launcher.plist
sudo rm /Library/LaunchDaemons/com.qsc.browser-launcher.plist
sudo rm -rf "/Library/Application Support/QSC"
```

---

## Files Included

**Q-SYS Plugin:**
- **QSC_Device_Discovery_URL_Enhanced.qplug** - Q-SYS Designer plugin

**macOS Browser Service:**
- **qsys_browser_launcher.py** - Mac browser service (Python script)
- **install.sh** - Automated installer for Mac
- **uninstall.sh** - Automated uninstaller

**Windows Browser Service:**
- **qsys_browser_launcher_windows.py** - Windows Python service
- **qsys_browser_launcher.ps1** - Windows PowerShell service (no install required)
- **start_browser_service.bat** - Easy double-click launcher

**Documentation:**
- **README.md** - This file
- **SETUP_INSTRUCTIONS.md** - Detailed macOS installation guide
- **WINDOWS_SETUP_INSTRUCTIONS.md** - Detailed Windows installation guide

---

## Technical Details

### Plugin Architecture

```
Plugin (UDP Socket) → Listens on 0.0.0.0:2467
                    ↓
         Receives QDP Announcements
                    ↓
              Parse XML Data
                    ↓
           Apply Filters (if any)
                    ↓
         Update Device Registry
                    ↓
       Display in Device List
                    ↓
    User Selects Device (Optional)
                    ↓
     HTTP Request to Mac Service
                    ↓
        Browser Opens Device URL
```

### API Limitations

- Q-SYS Lua environment does not support `JoinMulticastGroup()`
- Plugin relies on OS-level multicast handling
- No reverse DNS lookup capability
- Single network interface binding
- Browser launch requires external service (security limitation)

### Security Considerations

- Browser service listens on all network interfaces (0.0.0.0)
- Any device on your network can send URLs to open
- Service only accepts HTTP/HTTPS URLs
- Consider firewall rules to restrict access to specific IPs
- Service runs as system daemon (not user-level)

---

## Contributing

Contributions are welcome! This is an open-source project under the MIT License.

### How to Contribute

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Contribution Guidelines

- Follow existing code style and conventions
- Add debug logging for new features
- Test changes thoroughly in Q-SYS Designer
- Update documentation for new features
- Be respectful and constructive

### Reporting Issues

Found a bug or have a feature request? Please open an [issue](../../issues) with:
- Q-SYS Designer version
- Plugin version (check PluginInfo.Version in the .qplug file)
- Network configuration details
- Debug log output (if applicable)
- Steps to reproduce the issue
- Operating system (for browser launch issues)

---

## Roadmap

### Planned Features

- [ ] Windows browser launch support
- [ ] Linux browser launch support
- [ ] Active query mode (send requests to trigger responses)
- [ ] Persistent device list (accumulate across scans)
- [ ] CSV/JSON export functionality
- [ ] Historical device tracking (up/down events)
- [ ] Regex support for filters
- [ ] Device details view (full XML data)
- [ ] Configurable scan duration

### Future Enhancements

- Network ping integration
- Device reachability verification
- Multi-subnet discovery support
- Save/load filter presets
- Device status monitoring
- Alert on device offline/online

---

## Version History

### v2.5 (Current)
- **NEW:** Windows browser launch support (PowerShell & Python)
- **NEW:** Cross-platform service architecture
- **Removed:** "Get URL" button (redundant - knob auto-populates URL)
- **Improved:** Cleaner user workflow (select device → open browser)
- **Changed:** UI layout simplified

### v2.4
- **Changed:** Scan time reduced from 15 to 5 seconds
- **Improved:** Faster network discovery

### v2.3
- **NEW:** Browser launch integration for macOS
- **NEW:** Mac service installer and auto-startup configuration
- Fixed hostname parsing (enhanced XML tag detection)
- Improved fallback logic for missing hostname data
- Enhanced debug output (500 char packet preview)
- Added device selection controls
- Reduced scan time from 15 to 5 seconds

### v2.2
- Added HTTP client for browser launch requests
- Added plugin properties for Mac IP and service port
- Added "Open Browser" button

### v2.1
- Added device selector knob
- Added URL display field
- Added device info display

### v2.0
- Added 10 configurable filters
- Implemented real-time filter updates
- Fixed continuous packet reception bug
- Improved XML parsing robustness
- Enhanced debug logging
- Updated UI with filter section

### v1.0
- Initial release
- Basic QDP listening
- XML parsing for hostname and IP
- 15-second scan timer
- Status indicators

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

### MIT License Summary

```
Copyright (c) 2025 Brandon Cecil / Fresh AVL Co.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
```

---

## Contact

**Author**: Brandon Cecil  
**Company**: Fresh AVL Co.  
**Project Link**: https://github.com/bcecilpgh/QDP-Device-Discovery

---

## Support

If you find this plugin useful, please:
-  Star this repository
-  Report bugs via [Issues](../../issues)
-  Suggest features via [Issues](../../issues)
-  Contribute via [Pull Requests](../../pulls)
-  Share with other Q-SYS users

---

## Acknowledgments

- QSC for the Q-SYS ecosystem and comprehensive API documentation
- The Q-SYS community for feedback and testing
- macOS for providing the `open` command for browser integration

---

## Disclaimer

This plugin is provided "as-is" without warranty. Use at your own risk. Always test in a non-production environment before deploying to live systems.

Q-SYS, Q-SYS Designer, and related trademarks are property of QSC, LLC. This plugin is an independent project and is not affiliated with or endorsed by QSC.

---

**Built with ❤️ for the Q-SYS community**
