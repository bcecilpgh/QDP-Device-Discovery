# QSC Device Discovery Plugin - Developer Documentation

**Version:** 2.0  
**Author:** Brandon Cecil  
**Company:** Fresh AVL Co.  
**License:** MIT Open-Source

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Q-SYS Discovery Protocol (QDP)](#qsys-discovery-protocol-qdp)
4. [Implementation Details](#implementation-details)
5. [Code Structure](#code-structure)
6. [API Reference](#api-reference)
7. [Network Protocol](#network-protocol)
8. [Debugging](#debugging)
9. [Customization](#customization)
10. [Known Limitations](#known-limitations)
11. [Future Enhancements](#future-enhancements)
12. [License](#license)
13. [Contributing](#contributing)

---

## Overview

This Q-SYS plugin implements passive network discovery for Q-SYS devices using the Q-SYS Discovery Protocol (QDP). It listens for UDP multicast announcements on port 2467 and parses XML-formatted device information packets.

### Key Technical Features

- Passive UDP Socket Listener on port 2467
- XML Packet Parser for QDP announcement packets
- Real-time Device Tracking with last-seen timestamps
- Pattern-based Filtering with 10 configurable filter slots
- Automatic Socket Cleanup after scan timeout
- Comprehensive Debug Logging for troubleshooting

### Requirements

- Q-SYS Designer v9.0+
- Lua 5.3 runtime (built into Q-SYS)
- Network multicast support (IGMP)
- UDP port 2467 available

---

## Architecture

### Component Diagram

```
┌─────────────────────────────────────────┐
│        Q-SYS Designer Runtime           │
│  ┌───────────────────────────────────┐  │
│  │   QSC Device Discovery Plugin     │  │
│  │                                   │  │
│  │  ┌─────────────────────────────┐  │  │
│  │  │   Control Interface         │  │  │
│  │  │  - Scan Button              │  │  │
│  │  │  - Status Indicator         │  │  │
│  │  │  - Device List Output       │  │  │
│  │  │  - 10x Filter Inputs        │  │  │
│  │  └─────────────────────────────┘  │  │
│  │                                   │  │
│  │  ┌─────────────────────────────┐  │  │
│  │  │   Core Logic                │  │  │
│  │  │  - UDP Socket Manager       │  │  │
│  │  │  - XML Parser               │  │  │
│  │  │  - Filter Engine            │  │  │
│  │  │  - Device Registry          │  │  │
│  │  │  - Timer Manager            │  │  │
│  │  └─────────────────────────────┘  │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
              │
              │ UDP Port 2467
              ▼
┌─────────────────────────────────────────┐
│             Network Layer               │
│        Multicast: 224.0.23.175          │
│                                         │
│   ┌────────┐  ┌────────┐  ┌────────┐    │
│   │Q-SYS   │  │Q-SYS   │  │Q-SYS   │    │
│   │Core    │  │I/O     │  │Device  │    │
│   │:6504   │  │:6504   │  │:6504   │    │
│   └────────┘  └────────┘  └────────┘    │
└─────────────────────────────────────────┘
```

### Data Flow

1. **Initialization**: Plugin loads, creates control interface, initializes empty device registry
2. **Scan Trigger**: User clicks scan button → `StartDiscovery()` called
3. **Socket Creation**: UDP socket bound to `0.0.0.0:2467`
4. **Passive Listening**: Socket listens for incoming packets for 15 seconds
5. **Packet Reception**: `Data` callback fires on each received UDP packet
6. **XML Parsing**: Extract device info from QDP XML structure
7. **Filter Application**: Check device against all active filters
8. **Registry Update**: Add/update device in `discovered_devices` table
9. **UI Update**: Refresh device list display
10. **Timeout**: Timer expires → close socket, finalize count

---

## Q-SYS Discovery Protocol (QDP)

### Protocol Specification

| Parameter | Value |
|-----------|-------|
| Transport | UDP |
| Direction | Q-SYS Device → Multicast Group |
| Multicast Address | `224.0.23.175` |
| Destination Port | `2467` |
| Source Port | `6504` |
| Broadcast Interval | ~1000ms (1 second) |
| Packet Format | XML |
| TTL | 255 |

### Packet Structure

QDP packets are XML-encoded device announcements:

```xml
<QDP>
  <device>
    <n>device-hostname</n>
    <type>lcqln</type>
    <platform>lcqln</platform>
    <part_number>QIO-ML2x2</part_number>
    <ref>device.ioframe.hostname</ref>
    <is_virtual>false</is_virtual>
    <lan_a_mac>00:60:74:xx:xx:xx</lan_a_mac>
    <lan_a_ip>192.168.1.100</lan_a_ip>
    <lan_b_ip></lan_b_ip>
    <aux_a_ip></aux_a_ip>
    <aux_b_ip></aux_b_ip>
    <lan_a_lldp>14:ab:ec:35:e1:7c+22</lan_a_lldp>
    <web_cfg_url>https://192.168.1.100/</web_cfg_url>
    <id_mode>0</id_mode>
    <hw_rev>0.0</hw_rev>
  </device>
</QDP>
```

### Query Packets

Q-SYS Designer also sends query packets (not implemented in this plugin):

```xml
<QDP>
  <query_ref>control.*.* </query_ref>
  <query_ref>device.ioframe.*</query_ref>
</QDP>
```

---

## Implementation Details

### Plugin Metadata

```lua
PluginInfo = {
  Name = "Fresh AVL Co.~QSC Device Discovery",
  Version = "2.0",
  BuildVersion = "2.0.0",
  Id = "qsc.device.discovery.2.0",
  Author = "Brandon Cecil",
  Description = "Discovers QSC devices on the network via QDP"
}
```

### Control Definitions

```lua
function GetControls(props)
  return {
    {Name = "scan", ControlType = "Button", ButtonType = "Trigger", Count = 1},
    {Name = "device_list", ControlType = "Text", Count = 1},
    {Name = "status", ControlType = "Indicator", IndicatorType = "Status", Count = 1},
    {Name = "filter", ControlType = "Text", Count = 10}
  }
end
```

### State Management

Global state variables:

```lua
local discovered_devices = {}  -- Table: {[ip] = {hostname, type, part_number, last_seen}}
local udp_socket = nil         -- UdpSocket object
local discovery_timer = nil    -- Timer object
```

### Discovery Lifecycle

```lua
-- 1. Initialize
function Initialize()
  -- Set up event handlers
  Controls.scan.EventHandler = StartDiscovery
  for i = 1, 10 do
    Controls.filter[i].EventHandler = UpdateDeviceList
  end
end

-- 2. Start Discovery
function StartDiscovery()
  discovered_devices = {}
  udp_socket = UdpSocket.New()
  udp_socket.Data = HandleQDPPacket
  udp_socket:Open("0.0.0.0", 2467)
  discovery_timer = Timer.New()
  discovery_timer.EventHandler = OnScanComplete
  discovery_timer:Start(15)
end

-- 3. Handle Packets
function HandleQDPPacket(sock, packet)
  local device_info = ParseQDPPacket(packet.Data)
  if not IsFiltered(device_info) then
    discovered_devices[device_info.ip] = device_info
    UpdateDeviceList()
  end
end

-- 4. Complete Scan
function OnScanComplete()
  udp_socket:Close()
  udp_socket = nil
  -- Update final status
end
```

---

## Code Structure

### File Organization

```
QSC_Device_Discovery.qplug
├── PluginInfo                 (Metadata)
├── GetColor()                 (UI color scheme)
├── GetPrettyName()            (Display name)
├── GetProperties()            (Configuration properties)
├── RectifyProperties()        (Property validation)
├── GetControls()              (Control definitions)
├── GetControlLayout()         (UI layout)
└── if Controls then
    ├── State Variables
    ├── DebugPrint()           (Logging utility)
    ├── UpdateDeviceList()     (UI update logic)
    ├── ParseQDPPacket()       (XML parser)
    ├── StartDiscovery()       (Main discovery logic)
    ├── Initialize()           (Setup)
    └── Event Handlers
```

### Key Functions

#### ParseQDPPacket()

Extracts device information from XML QDP packets using Lua pattern matching:

```lua
function ParseQDPPacket(data)
  local device_info = {}
  
  -- Extract hostname
  local name = string.match(data, "<n>([^<]+)</n>")
  if name then device_info.hostname = name end
  
  -- Extract IP address
  local ip = string.match(data, "<lan_a_ip>([^<]+)</lan_a_ip>")
  if ip and ip ~= "" then device_info.ip = ip end
  
  -- Extract device type
  local device_type = string.match(data, "<type>([^<]+)</type>")
  if device_type then device_info.type = device_type end
  
  -- Extract part number
  local part_num = string.match(data, "<part_number>([^<]+)</part_number>")
  if part_num then device_info.part_number = part_num end
  
  return device_info
end
```

#### Filter Engine

```lua
function UpdateDeviceList()
  -- Collect active filters
  local filters = {}
  for i = 1, 10 do
    local filter_text = Controls.filter[i].String
    if filter_text and filter_text ~= "" then
      table.insert(filters, filter_text:lower())
    end
  end
  
  -- Apply filters and build display list
  local list = ""
  local count = 0
  
  for ip, device in pairs(discovered_devices) do
    local should_exclude = false
    
    if #filters > 0 then
      local hostname_lower = device.hostname:lower()
      local ip_lower = ip:lower()
      local part_lower = (device.part_number or ""):lower()
      
      for _, filter in ipairs(filters) do
        if string.find(hostname_lower, filter, 1, true) or
           string.find(ip_lower, filter, 1, true) or
           string.find(part_lower, filter, 1, true) then
          should_exclude = true
          break
        end
      end
    end
    
    if not should_exclude then
      count = count + 1
      list = list .. string.format("%d. %s - %s\n", count, device.hostname, ip)
    end
  end
  
  Controls.device_list.String = list
end
```

---

## API Reference

### Q-SYS Lua API Usage

#### UdpSocket

```lua
-- Create socket
local sock = UdpSocket.New()

-- Set data callback
sock.Data = function(socket, packet)
  -- packet.Address: string (IP address)
  -- packet.Port: number
  -- packet.Data: string (raw bytes)
end

-- Open socket
-- Syntax: Open(address, port)
-- address: "0.0.0.0" for all interfaces, specific IP, or multicast group
-- port: 0 for any port, or specific port number
sock:Open("0.0.0.0", 2467)

-- Close socket
sock:Close()
```

**Important Notes:**
- `JoinMulticastGroup()` is **not available** in Q-SYS Lua environment
- Binding to `0.0.0.0` on a multicast port may or may not receive multicast depending on OS
- No `ReadTimeout` property available
- Socket operations may throw Lua errors, wrap in `pcall()`

#### Timer

```lua
-- Create timer
local timer = Timer.New()

-- Set event handler
timer.EventHandler = function(t)
  t:Stop()  -- Stop the timer
  -- Execute timeout logic
end

-- Start timer (seconds)
timer:Start(15)

-- Stop timer
timer:Stop()
```

#### Controls

```lua
-- Button
Controls.scan.EventHandler = function()
  -- Handle button press
end

-- Text input
Controls.filter[1].String = "text"
local text = Controls.filter[1].String

-- Text output
Controls.device_list.String = "display text"

-- Status indicator
Controls.status.Value = 0  -- 0=OK, 2=Warning, 5=Error
Controls.status.String = "status text"

-- Text EventHandler
Controls.filter[1].EventHandler = function()
  local new_text = Controls.filter[1].String
  -- Handle text change
end
```

---

## Network Protocol

### Packet Capture Analysis

Using Wireshark/tshark to analyze QDP traffic:

```bash
# Capture QDP packets
tshark -i eth0 -f "udp port 2467" -w qdp_capture.pcap

# Display QDP packets
tshark -r qdp_capture.pcap -Y "udp.dstport == 2467"

# Extract packet data
tshark -r qdp_capture.pcap -Y "udp.dstport == 2467" -T fields \
  -e ip.src -e udp.srcport -e data.text
```

### Example Packet

```
Ethernet II
├── Destination: 01:00:5e:00:17:af (IPv4 Multicast)
├── Source: 00:60:74:f5:d1:6c (QSC device MAC)
└── Type: IPv4

Internet Protocol Version 4
├── Source: 192.168.1.100
├── Destination: 224.0.23.175
├── Protocol: UDP
└── TTL: 255

User Datagram Protocol
├── Source Port: 6504
├── Destination Port: 2467
└── Length: 610 bytes

Data (602 bytes)
└── <QDP><device>...</device></QDP>
```

### Multicast Group

```
Address: 224.0.23.175
IGMP Group: 224.0.23.175
MAC Address: 01:00:5e:00:17:af
```

To join multicast group (outside Q-SYS):

```python
import socket
import struct

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
sock.bind(('', 2467))

mreq = struct.pack("4sl", socket.inet_aton("224.0.23.175"), socket.INADDR_ANY)
sock.setsockopt(socket.IPPROTO_IP, socket.IP_ADD_MEMBERSHIP, mreq)
```

---

## Debugging

### Debug Logging

Enable debug output in Q-SYS Designer: **View → Debug Output**

All debug messages prefixed with `[QSC Discovery]`:

```lua
local DEBUG = true  -- Set to false to disable logging

function DebugPrint(message)
  if DEBUG then
    print("[QSC Discovery] " .. message)
  end
end
```

### Key Debug Points

```lua
-- Socket operations
DebugPrint("Attempting to bind to 0.0.0.0:2467")
DebugPrint("Bind result: success=" .. tostring(success))

-- Packet reception
DebugPrint("=== QDP packet received ===")
DebugPrint("From: " .. packet.Address .. ":" .. packet.Port)
DebugPrint("Packet length: " .. #data .. " bytes")
DebugPrint("Packet content: " .. string.sub(data, 1, 300))

-- Parsing
DebugPrint("Parsed hostname: " .. hostname)
DebugPrint("Parsed IP: " .. ip)

-- Filtering
DebugPrint("Active filter " .. i .. ": " .. filter_text)
DebugPrint("Filtered out: " .. device.hostname)
```

### Common Issues

#### No Packets Received

```
Symptom: "Discovery timer expired" but no packets logged
Causes:
  1. Port 2467 already in use
  2. Multicast not reaching interface
  3. IGMP snooping blocking traffic
  
Debug:
  - Check if other process using port: netstat -an | grep 2467
  - Verify multicast routing: ip mroute show
  - Test with external sniffer: tcpdump -i any port 2467
```

#### Packets Received but Not Parsed

```
Symptom: "QDP packet received" but no devices added
Causes:
  1. XML structure changed
  2. Pattern matching failed
  3. Filters excluding all devices
  
Debug:
  - Check raw packet content in debug log
  - Verify XML tags match patterns
  - Disable all filters temporarily
```

#### Socket Binding Failed

```
Symptom: "Error: Failed to open UDP port"
Causes:
  1. Insufficient permissions
  2. Port conflict
  3. Network adapter disabled
  
Debug:
  - Run Q-SYS Designer as administrator
  - Check Windows Firewall rules
  - Verify network adapter status
```

---

## Customization

### Adding Additional Parsed Fields

To extract more fields from QDP packets:

```lua
function ParseQDPPacket(data)
  local device_info = {}
  
  -- Existing fields
  device_info.hostname = string.match(data, "<n>([^<]+)</n>")
  device_info.ip = string.match(data, "<lan_a_ip>([^<]+)</lan_a_ip>")
  
  -- Add new fields
  device_info.mac = string.match(data, "<lan_a_mac>([^<]+)</lan_a_mac>")
  device_info.platform = string.match(data, "<platform>([^<]+)</platform>")
  device_info.hw_rev = string.match(data, "<hw_rev>([^<]+)</hw_rev>")
  device_info.web_url = string.match(data, "<web_cfg_url>([^<]+)</web_cfg_url>")
  
  return device_info
end
```

### Changing Scan Duration

Modify the timer start value:

```lua
-- Change from 15 seconds to 30 seconds
discovery_timer:Start(30)
```

### Custom Filter Logic

Replace the filter engine with custom logic:

```lua
function CustomFilterLogic(device)
  -- Example: Only show Cores
  if device.type and string.match(device.type, "core") then
    return false  -- Don't filter (show device)
  end
  return true  -- Filter out
end
```

### Export Device List

Add export functionality:

```lua
function ExportToCSV()
  local csv = "Hostname,IP,Part Number,Type\n"
  for ip, device in pairs(discovered_devices) do
    csv = csv .. string.format("%s,%s,%s,%s\n",
      device.hostname, ip, device.part_number or "", device.type or "")
  end
  
  -- Write to file (if file I/O available)
  local file = io.open("/path/to/export.csv", "w")
  file:write(csv)
  file:close()
end
```

---

## Known Limitations

### Q-SYS Platform Limitations

1. **No Multicast Group Join**: `UdpSocket.JoinMulticastGroup()` not available
   - Workaround: Bind to `0.0.0.0:2467` and rely on OS multicast handling
   - May not work on all network configurations

2. **No Raw Socket Access**: Cannot implement IGMP directly
   - Limitation: Cannot force multicast subscription at protocol level

3. **Single Network Interface**: Cannot specify which interface to listen on
   - Impact: May miss devices on secondary network adapters

4. **No DNS Resolution**: Cannot perform reverse DNS lookups
   - Impact: Only IP addresses available, not DNS names


### Network Limitations

1. **Same Subnet Requirement**: Multicast typically doesn't cross L3 boundaries
   - Solution: Configure multicast routing or use on same VLAN

2. **IGMP Snooping**: Some switches block multicast by default
   - Solution: Configure IGMP snooping/querier on switch

3. **Port Conflicts**: Q-SYS Designer may use port 2467 for its own discovery
   - Solution: Close Designer's built-in discovery or use plugin on different machine

### Implementation Limitations

1. **No Persistent Storage**: Devices cleared each scan
2. **No Historical Tracking**: No record of device up/down events
3. **Limited XML Parsing**: Simple pattern matching, not full XML parser
4. **Fixed Filter Count**: Only 10 filter slots
5. **Doesn't Work in Emulation Mode With Core on Network** 

---

## Future Enhancements

### Planned Features

1. **Active Querying**: Send query packets to trigger responses
2. **Persistent Device List**: Option to accumulate devices across scans
3. **Export Functions**: CSV/JSON export of device list
4. **Historical Logging**: Track device appearance/disappearance
5. **Device Details View**: Click device to see full XML data
6. **Network Ping Integration**: Verify device reachability

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

### MIT License

```
MIT License

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
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### What This Means

This plugin is free and open-source under the MIT License, which means you can:

- Use it for any purpose (personal, commercial, educational)  
- Modify it to suit your needs  
- Distribute it to others  
- Include it in your own projects  
- Sell software that includes it  

**Requirements:**
- Include the copyright notice and license text in any copies
- Provide attribution to the original author

**No Warranty:**
- The software is provided "as-is" without any warranty
- Use at your own risk

---

## Contributing

Contributions are welcome! This is an open-source project and we encourage community involvement.

### How to Contribute

1. **Report Bugs**: Open an issue describing the bug with reproduction steps
2. **Suggest Features**: Open an issue with your feature request and use case
3. **Submit Pull Requests**: Fork the repo, make changes, and submit a PR
4. **Improve Documentation**: Help make the docs better for everyone

### Contribution Guidelines

- Follow existing code style and conventions
- Add debug logging for new features
- Test your changes thoroughly in Q-SYS Designer
- Update documentation for any new features or changes
- Be respectful and constructive in all interactions

### Contact

For questions, support, or collaboration:
- **Author**: Brandon Cecil
- **Company**: Fresh AVL Co.
- **GitHub**: https://github.com/bcecilpgh/QDP-Device-Discovery

### Building from Source

```lua
-- No build process required
-- Direct .qplug file deployment to Q-SYS Designer

-- File structure:
QSC_Device_Discovery.qplug
  └── Single Lua file with embedded layout/controls
```

### Testing

```lua
-- Unit test framework (pseudo-code, not executable in Q-SYS)
function TestXMLParser()
  local test_xml = [[<QDP><device><n>test-device</n>
    <lan_a_ip>192.168.1.100</lan_a_ip></device></QDP>]]
  
  local result = ParseQDPPacket(test_xml)
  
  assert(result.hostname == "test-device")
  assert(result.ip == "192.168.1.100")
end

function TestFilterEngine()
  -- Set up test data
  discovered_devices = {
    ["192.168.1.100"] = {hostname = "test-core", part_number = "Core 110f"}
  }
  
  -- Apply filter
  Controls.filter[1].String = "test"
  UpdateDeviceList()
  
  -- Verify filtered
  assert(Controls.device_list.String == "All 1 discovered device(s) were filtered out.")
end
```

---

**Document Version**: 1.0  
**Last Updated**: November 19, 2025  
**Maintainer**: Brandon Cecil - Fresh AVL Co.
