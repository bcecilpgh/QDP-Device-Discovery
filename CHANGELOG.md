# Changelog

## Version 2.4 - 2025-11-22

### Changed
- **Scan Time Reduced**: Discovery scan time reduced from 15 seconds to 5 seconds for faster results
- **Updated Documentation**: All documentation updated to reflect 5-second scan time

### What This Means
- Faster network discovery - you only need to wait 5 seconds instead of 15
- Still captures multiple QDP announcements (devices broadcast every ~1 second)
- Same reliability with improved user experience

---

## Version 2.3 - 2025-11-22

### Added
- **macOS Browser Launch**: One-click opening of device web interfaces
- **Mac Service Installer**: Automated installation script (`install.sh`)
- **Auto-startup Configuration**: Service configured to start on Mac boot
- **Comprehensive Documentation**: Added setup instructions and README

### Fixed
- **Hostname Parsing**: Enhanced XML tag detection for better hostname extraction
- **Fallback Logic**: Improved handling when hostname is missing (uses part number or type)
- **Debug Output**: Expanded packet preview from 300 to 500 characters

### Changed
- **Plugin Properties**: Added Mac IP Address and Service Port configuration
- **UI Layout**: Added device selection controls and browser launch button

---

## Version 2.2 - 2025-11-22

### Added
- HTTP client integration for browser launch requests
- "Open Browser" button in UI
- Selected device info display

---

## Version 2.1 - 2025-11-22

### Added
- Device selector knob for choosing devices
- URL display field showing http:// address
- "Get URL" button to populate selected device info

---

## Version 2.0 - 2025-11-22

### Added
- 10 configurable filter slots for excluding devices
- Real-time filter updates (no need to rescan)
- Enhanced UI with dedicated filter section

### Fixed
- Continuous packet reception bug (proper socket cleanup)
- Improved XML parsing robustness

### Changed
- Enhanced debug logging throughout
- Updated UI layout to accommodate filters

---

## Version 1.0 - Initial Release

### Added
- QDP protocol listening on multicast 224.0.23.175:2467
- XML parsing for device hostname, IP, and part number
- 15-second scan timer with automatic cleanup
- Status indicators
- Basic device list display
- Debug logging system

---

## Upgrade Notes

### Upgrading from v2.3 to v2.4
- **No action required** - Simply replace the plugin file
- Existing Mac service installation continues to work unchanged
- Enjoy faster 5-second scans!

### Upgrading from v2.0-2.2 to v2.3+
- Mac service installation required for browser launch feature
- Run `sudo ./install.sh` to install the service
- Configure Mac IP in plugin properties
- Discovery features work the same way

### Upgrading from v1.0 to v2.0+
- No breaking changes
- Filter controls are optional (leave blank to disable)
- All existing functionality preserved

---

## Known Issues

- **macOS Only**: Browser launch feature currently only supports macOS
- **Multicast Dependency**: Discovery requires IGMP multicast support on network switches
- **Single Interface**: Plugin binds to all interfaces but may have issues in multi-homed systems

---

## Future Plans

- Windows browser launch support
- Linux browser launch support  
- Configurable scan duration
- Active query mode (send discovery requests)
- Device status monitoring
- Historical tracking

---

For complete feature details, see [README.md](README.md)
