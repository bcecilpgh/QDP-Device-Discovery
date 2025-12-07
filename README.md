# QSC Device Discovery Plugin

A powerful Q-SYS Designer plugin that automatically discovers and displays all Q-SYS devices on your network using the Q-SYS Discovery Protocol (QDP).

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Q-SYS Designer](https://img.shields.io/badge/Q--SYS%20Designer-v9.0%2B-green.svg)](https://www.qsc.com/solutions-products/q-sys-ecosystem/q-sys-designer-software/)
[![Lua](https://img.shields.io/badge/Lua-5.3-blue.svg)](https://www.lua.org/)

---

## Overview

The QSC Device Discovery Plugin passively listens for Q-SYS Discovery Protocol (QDP) announcements broadcast by Q-SYS Cores, I/O Frames, and other network devices. It provides a simple interface to discover, filter, and manage Q-SYS devices on your network without requiring manual IP configuration.

### Key Features

- **Automatic Discovery** - Passively listens for QDP announcements on multicast address 224.0.23.175
- **Device Information** - Displays hostname, IP address, and part number for each device
- **Advanced Filtering** - 10 configurable filter slots to exclude unwanted devices
- **Real-Time Updates** - Device list updates as announcements are received
- **Debug Logging** - Comprehensive debug output for troubleshooting
- **Auto Timeout** - 15-second scan with automatic socket cleanup

---

## Installation

### Prerequisites

- Q-SYS Designer v9.0 or later
- Network with multicast support (IGMP)
- UDP port 2467 available

### Steps

1. **Download** the latest release from the [Releases](../../releases) page
2. **Copy** `QSC_Device_Discovery.qplug` to your Q-SYS Plugins folder:
   - **Windows**: `%USERPROFILE%\Documents\QSC\Q-Sys Designer\Plugins`
   - **macOS**: `~/Documents/QSC/Q-Sys Designer/Plugins`
3. **Open** Q-SYS Designer
4. **Add** the plugin to your design:
   - Search for "QSC Device Discovery" in the component search
   - Drag it onto your schematic
5. **Double-click** the component to open the control panel

---

## Usage

### Basic Discovery

1. Click the **Scan Network** button
2. Wait up to 15 seconds for discovery to complete
3. View discovered devices in the device list

Each device entry shows:
```
1. device-hostname (Part-Number) - 192.168.1.100
```

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

---

## Configuration

### Network Requirements

- **Same Network Segment**: Plugin must be on the same subnet as target devices, or multicast must be routed
- **Multicast Support**: Network switches must support and forward multicast traffic (IGMP)
- **Port Availability**: UDP port 2467 must not be blocked or in use
- **Firewall**: Allow UDP port 2467 inbound

### Q-SYS Designer Settings

No special configuration required. The plugin works out of the box in Q-SYS Designer.

---

## Troubleshooting

### No Devices Discovered

**Problem**: Scan completes but shows "Found 0 devices"

**Solutions**:
1. Verify network connectivity (ping a known device)
2. Check if multicast is supported on your switch (IGMP)
3. Ensure port 2467 is not blocked by firewall
4. Confirm devices are powered on and connected
5. Check Debug Output in Q-SYS Designer for error messages

### Some Devices Missing

**Problem**: Some known devices don't appear

**Solutions**:
1. Check if devices are filtered by active filters
2. Wait a few seconds after device boot before scanning
3. Verify devices are on the same network segment
4. Some older device types may not broadcast QDP

### Port Already in Use

**Problem**: Error message "Failed to open UDP port"

**Solutions**:
1. Close Q-SYS Designer's built-in discovery window
2. Check for other applications using port 2467
3. Restart Q-SYS Designer
4. Run Q-SYS Designer as administrator (Windows)

### Debug Logging

Enable debug output: **View → Debug Output** in Q-SYS Designer

Look for messages prefixed with `[QSC Discovery]` for detailed troubleshooting information.

---

## Technical Details

### Architecture

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
```

### API Limitations

- Q-SYS Lua environment does not support `JoinMulticastGroup()`
- Plugin relies on OS-level multicast handling
- No reverse DNS lookup capability
- Single network interface binding

For detailed technical information, see [Technical Documentation](QSC_Device_Discovery_Technical.md).

---

## Documentation

- **[User Manual](QSC_Device_Discovery_Manual.html)** - Comprehensive user guide
- **[Technical Documentation](QSC_Device_Discovery_Technical.md)** - Developer documentation
- **[LICENSE](LICENSE)** - MIT License text

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
- Plugin version
- Network configuration details
- Debug log output (if applicable)
- Steps to reproduce the issue

---

## Roadmap

### Planned Features

- [ ] Active query mode (send requests to trigger responses)
- [ ] Persistent device list (accumulate across scans)
- [ ] CSV/JSON export functionality
- [ ] Historical device tracking (up/down events)
- [ ] Regex support for filters
- [ ] Device details view (full XML data)

### Future Enhancements

- Network ping integration
- Device reachability verification
- Multi-subnet discovery support
- Custom scan duration
- Save/load filter presets

---

## Version History

### v2.0 (Current)
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
Copyright (c) 2025 Brandon Cecil / Fresh AV Labs

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
**Company**: Fresh AV Labs  
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

## Disclaimer

This plugin is provided "as-is" without warranty. Use at your own risk. Always test in a non-production environment before deploying to live systems.

Q-SYS, Q-SYS Designer, and related trademarks are property of QSC, LLC. This plugin is an independent project and is not affiliated with or endorsed by QSC.

---

**Built for the Q-SYS community**
