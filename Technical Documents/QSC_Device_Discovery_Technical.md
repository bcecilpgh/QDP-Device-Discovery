# QSC Device Discovery Plugin - Developer Documentation

**Version:** 2.5  
**Author:** Brandon Cecil  
**Company:** Fresh AVL Co.  
**License:** MIT Open-Source

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Q-SYS Discovery Protocol (QDP)](#qsys-discovery-protocol-qdp)
4. [Browser Launch Integration](#browser-launch-integration)
5. [Implementation Details](#implementation-details)
6. [Code Structure](#code-structure)
7. [API Reference](#api-reference)
8. [Network Protocol](#network-protocol)
9. [HTTP Client Integration](#http-client-integration)
10. [Mac Service Implementation](#mac-service-implementation)
11. [Debugging](#debugging)
12. [Customization](#customization)
13. [Known Limitations](#known-limitations)
14. [Future Enhancements](#future-enhancements)
15. [License](#license)
16. [Contributing](#contributing)

---

## Overview

This Q-SYS plugin implements passive network discovery for Q-SYS devices using the Q-SYS Discovery Protocol (QDP). It listens for UDP multicast announcements on port 2467 and parses XML-formatted device information packets. **Version 2.4 introduces browser launch integration for macOS**, enabling one-click access to device web interfaces.

### Key Technical Features

- Passive UDP Socket Listener on port 2467
- XML Packet Parser for QDP announcement packets
- Real-time Device Tracking with last-seen timestamps
- Pattern-based Filtering with 10 configurable filter slots
- **Device Selection and URL Generation**
- **HTTP Client for Browser Launch Requests**
- **macOS Service Integration**
- Automatic Socket Cleanup after scan timeout (5 seconds)
- Comprehensive Debug Logging for troubleshooting

### Requirements

- Q-SYS Designer v9.0+
- Lua 5.3 runtime (built into Q-SYS)
- Network multicast support (IGMP)
- UDP port 2467 available
- **For browser launch:** macOS with Python 3 (pre-installed)

---

## Architecture

### Component Diagram

```
┌──────────────────────────────────────────────────────────────┐
│                  Q-SYS Designer Runtime                      │
│  ┌────────────────────────────────────────────────────────┐  │
│  │         QSC Device Discovery Plugin                    │  │ 
│  │                                                        │  │
│  │  ┌──────────────────────────────────────────────────┐  │  │
│  │  │         Control Interface                        │  │  │
│  │  │  - Scan Button                                   │  │  │
│  │  │  - Status Indicator                              │  │  │
│  │  │  - Device List Output                            │  │  │
│  │  │  - 10x Filter Inputs                             │  │  │
│  │  │  - Device Selector Knob           [NEW v2.1]     │  │  │
│  │  │  - Get URL Button                 [NEW v2.1]     │  │  │
│  │  │  - Open Browser Button            [NEW v2.2]     │  │  │
│  │  │  - Selected Device Info            [NEW v2.1]    │  │  │
│  │  │  - Selected URL Display            [NEW v2.1]    │  │  │
│  │  └──────────────────────────────────────────────────┘  │  │
│  │                                                        │  │
│  │  ┌──────────────────────────────────────────────────┐  │  │
│  │  │         Core Logic                               │  │  │
│  │  │  - UDP Socket Manager                            │  │  │
│  │  │  - XML Parser (enhanced)          [UPD v2.3]     │  │  │
│  │  │  - Filter Engine                                 │  │  │
│  │  │  - Device Registry                               │  │  │
│  │  │  - Device Order Tracker           [NEW v2.1]     │  │  │
│  │  │  - Timer Manager (5s timeout)     [UPD v2.4]     │  │  │
│  │  │  - HTTP Client Manager            [NEW v2.2]     │  │  │
│  │  └──────────────────────────────────────────────────┘  │  │
│  └────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
              │                           │
              │ UDP Port 2467             │ HTTP Request
              ▼                           ▼
┌─────────────────────────────┐   ┌────────────────────────┐
│      Network Layer          │   │   macOS System         │
│  Multicast: 224.0.23.175    │   │  ┌──────────────────┐  │
│                             │   │  │ Browser Service  │  │
│ ┌────────┐  ┌────────┐      │   │  │  (Python)        │  │
│ │Q-SYS   │  │Q-SYS   │      │   │  │  Port: 8765      │  │
│ │Core    │  │I/O     │      │   │  └────────┬─────────┘  │
│ │:6504   │  │:6504   │      │   │           │            │
│ └────────┘  └────────┘      │   │           ▼            │
└─────────────────────────────┘   │  ┌──────────────────┐  │
                                  │  │ Default Browser  │  │
                                  │  │ (Safari/Chrome)  │  │
                                  │  └──────────────────┘  │
                                  └────────────────────────┘
```

### Data Flow

#### Discovery Flow

1. **Initialization**: Plugin loads, creates control interface, initializes empty device registry
2. **Scan Trigger**: User clicks scan button → `StartDiscovery()` called
3. **Socket Creation**: UDP socket bound to `0.0.0.0:2467`
4. **Passive Listening**: Socket listens for incoming packets for 5 seconds
5. **Packet Reception**: `Data` callback fires on each received UDP packet
6. **XML Parsing**: Extract device info from QDP XML structure with enhanced tag detection
7. **Filter Application**: Check device against all active filters
8. **Registry Update**: Add/update device in `discovered_devices` table with display order tracking
9. **UI Update**: Refresh device list display
10. **Timeout**: Timer expires → close socket, finalize count

#### Browser Launch Flow

1. **Device Selection**: User adjusts device selector knob → `SelectDevice()` called
2. **URL Generation**: Plugin formats HTTP URL from device IP
3. **Display Update**: URL and device info shown in controls
4. **Launch Trigger**: User clicks "Open Browser" → `OpenInBrowser()` called
5. **HTTP Request**: Plugin sends GET request to Mac service with URL parameter
6. **Service Processing**: Mac service receives request, validates URL
7. **Browser Launch**: Service executes macOS `open` command
8. **Response Handling**: Plugin receives success/error response, updates status

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

## Browser Launch Integration

### Overview

The browser launch feature enables automatic opening of device web interfaces from Q-SYS Designer using a lightweight service running on macOS. This overcomes Q-SYS's sandboxed Lua environment limitations.

### Architecture

```
Q-SYS Plugin              Mac Service              Browser
    │                         │                       │
    │  1. Device Selected     │                       │
    ├────────────────────────>│                       │
    │                         │                       │
    │  2. HTTP GET Request    │                       │
    │  /url=http://device-ip  │                       │
    ├────────────────────────>│                       │
    │                         │  3. Validate URL      │
    │                         │                       │
    │                         │  4. Execute 'open'    │
    │                         ├──────────────────────>│
    │                         │                       │
    │  5. HTTP 200 Response   │  5. Browser Opens     │
    │<────────────────────────┤                       │
    │                         │                       │
```

### Communication Protocol

**Request Format:**
```
GET http://<mac-ip>:8765?url=http://<device-ip>
```

**Response Format (Success):**
```json
{
  "status": "success",
  "message": "Opened http://192.168.1.100",
  "url": "http://192.168.1.100"
}
```

**Response Format (Error):**
```
HTTP 400 Bad Request
HTTP 500 Internal Server Error
```

### Service Specifications

| Parameter | Value |
|-----------|-------|
| Language | Python 3 |
| Location | `/Library/Application Support/QSC/qsys_browser_launcher.py` |
| Port | 8765 (configurable) |
| Startup | LaunchDaemon (automatic) |
| Protocol | HTTP |
| Methods | GET, POST |
| Security | Local network only, HTTP/HTTPS URLs only |

---

## Implementation Details

### Plugin Metadata

```lua
PluginInfo = {
  Name = "Fresh AVL Co.~QSC Device Discovery URL",
  Version = "2.4",
  BuildVersion = "2.4.0",
  Id = "qsc.device.discovery.2.4 URL",
  Author = "Brandon Cecil",
  Description = "Discovers QSC devices on the network via QDP with browser launch"
}
```

### Properties

```lua
function GetProperties()
  return {
    {
      Name = "Mac IP Address",
      Type = "string",
      Value = "192.168.1.100"
    },
    {
      Name = "Service Port",
      Type = "integer",
      Min = 1024,
      Max = 65535,
      Value = 8765
    }
  }
end
```

### Control Definitions

```lua
function GetControls(props)
  return {
    {Name = "scan", ControlType = "Button", ButtonType = "Trigger", Count = 1},
    {Name = "device_list", ControlType = "Text", Count = 1},
    {Name = "status", ControlType = "Indicator", IndicatorType = "Status", Count = 1},
    {Name = "filter", ControlType = "Text", Count = 10},
    
    -- Device Selection Controls (v2.1+)
    {Name = "device_selector", ControlType = "Knob", ControlUnit = "Integer",
     Min = 0, Max = 100, Count = 1},
    {Name = "open_browser", ControlType = "Button", ButtonType = "Trigger", Count = 1},
    {Name = "selected_url", ControlType = "Text", Count = 1},
    {Name = "selected_info", ControlType = "Text", Count = 1}
  }
end
```

### State Management

Global state variables:

```lua
local discovered_devices = {}  -- Table: {[ip] = {hostname, type, part_number, last_seen}}
local device_order = {}        -- Array: [index] = ip (display order tracking)
local udp_socket = nil         -- UdpSocket object
local discovery_timer = nil    -- Timer object

-- QDP Configuration
local DISCOVERY_ADDR = "224.0.23.175"
local LISTEN_PORT = 2467
local DEBUG = true
```

### Discovery Lifecycle

```lua
-- 1. Initialize
function Initialize()
  Controls.scan.EventHandler = StartDiscovery
  Controls.open_browser.EventHandler = OpenInBrowser
  
  -- Auto-select device when knob changes
  Controls.device_selector.EventHandler = function()
    if Controls.device_selector.Value > 0 then
      SelectDevice()
    end
  end
  
  for i = 1, 10 do
    Controls.filter[i].EventHandler = UpdateDeviceList
  end
end

-- 2. Start Discovery
function StartDiscovery()
  discovered_devices = {}
  device_order = {}
  udp_socket = UdpSocket.New()
  udp_socket.Data = HandleQDPPacket
  udp_socket:Open("0.0.0.0", 2467)
  discovery_timer = Timer.New()
  discovery_timer.EventHandler = OnScanComplete
  discovery_timer:Start(5)  -- 5 second timeout
end

-- 3. Handle Packets
function HandleQDPPacket(sock, packet)
  local device_info = ParseQDPPacket(packet.Data)
  if not IsFiltered(device_info) then
    if not discovered_devices[device_info.ip] then
      discovered_devices[device_info.ip] = device_info
      UpdateDeviceList()
    else
      discovered_devices[device_info.ip].last_seen = os.time()
    end
  end
end

-- 4. Complete Scan
function OnScanComplete()
  udp_socket:Close()
  udp_socket = nil
  -- Update final status
end

-- 5. Device Selection
function SelectDevice()
  local device_num = math.floor(Controls.device_selector.Value)
  local ip = device_order[device_num]
  if ip and discovered_devices[ip] then
    local device = discovered_devices[ip]
    Controls.selected_info.String = string.format("%s - %s", 
      device.hostname, ip)
    Controls.selected_url.String = string.format("http://%s", ip)
  end
end

-- 6. Browser Launch
function OpenInBrowser()
  local url = Controls.selected_url.String
  local mac_ip = Properties["Mac IP Address"].Value
  local service_port = Properties["Service Port"].Value
  local service_url = string.format("http://%s:%d?url=%s", 
    mac_ip, service_port, url)
  
  HttpClient.Download {
    Url = service_url,
    Timeout = 5,
    EventHandler = function(tbl, code, data, error, headers)
      if code == 200 then
        Controls.status.String = "Browser opened successfully"
      else
        Controls.status.String = "Browser launch failed"
      end
    end
  }
end
```

---

## Code Structure

### File Organization

```
QSC_Device_Discovery_URL_Enhanced.qplug
├── PluginInfo                     (Metadata - v2.4)
├── GetColor()                     (UI color scheme)
├── GetPrettyName()                (Display name)
├── GetProperties()                (Mac IP, Service Port) [NEW v2.2]
├── RectifyProperties()            (Property validation)
├── GetControls()                  (Control definitions - expanded)
├── GetControlLayout()             (UI layout - device selection section)
└── if Controls then
    ├── State Variables
    │   ├── discovered_devices
    │   ├── device_order           [NEW v2.1]
    │   ├── udp_socket
    │   └── discovery_timer
    ├── DebugPrint()               (Logging utility)
    ├── UpdateDeviceList()         (UI update + order tracking)
    ├── ParseQDPPacket()           (Enhanced XML parser) [UPD v2.3]
    ├── SelectDevice()             (Device selection logic) [NEW v2.1]
    ├── OpenInBrowser()            (HTTP launch request) [NEW v2.2]
    ├── StartDiscovery()           (Main discovery logic - 5s timeout)
    ├── Initialize()               (Setup)
    └── Event Handlers
```

### Key Functions

#### ParseQDPPacket() - Enhanced

Extracts device information from XML QDP packets using multiple tag patterns:

```lua
function ParseQDPPacket(data)
  local device_info = {}
  
  -- Enhanced hostname extraction (tries multiple tags)
  local name = string.match(data, "<n>([^<]+)</n>")
  if not name then
    name = string.match(data, "<hostname>([^<]+)</hostname>")
  end
  if not name then
    name = string.match(data, "<device_name>([^<]+)</device_name>")
  end
  if name then device_info.hostname = name end
  
  -- Enhanced IP extraction (tries multiple tags)
  local ip = string.match(data, "<lan_a_ip>([^<]+)</lan_a_ip>")
  if not ip or ip == "" then
    ip = string.match(data, "<ip>([^<]+)</ip>")
  end
  if not ip or ip == "" then
    ip = string.match(data, "<lan_ip>([^<]+)</lan_ip>")
  end
  if ip and ip ~= "" then device_info.ip = ip end
  
  -- Device type
  local device_type = string.match(data, "<type>([^<]+)</type>")
  if device_type then device_info.type = device_type end
  
  -- Part number (tries multiple tags)
  local part_num = string.match(data, "<part_number>([^<]+)</part_number>")
  if not part_num then
    part_num = string.match(data, "<model>([^<]+)</model>")
  end
  if part_num then device_info.part_number = part_num end
  
  return device_info
end
```

**Improvements in v2.3:**
- Multiple tag name fallbacks for hostname
- Enhanced IP address extraction
- Alternative part number tag support
- Better error handling for missing data

#### UpdateDeviceList() - With Order Tracking

```lua
function UpdateDeviceList()
  local filters = {}
  for i = 1, 10 do
    local filter_text = Controls.filter[i].String
    if filter_text and filter_text ~= "" then
      table.insert(filters, filter_text:lower())
    end
  end
  
  local list = ""
  local count = 0
  device_order = {}  -- Reset display order
  
  for ip, device in pairs(discovered_devices) do
    local should_exclude = false
    
    -- Check filters
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
      local display_name = device.hostname
      if device.part_number then
        display_name = display_name .. " (" .. device.part_number .. ")"
      end
      list = list .. string.format("%d. %s - %s\n", count, display_name, ip)
      
      -- Store IP in display order for selection
      device_order[count] = ip
    end
  end
  
  Controls.device_list.String = list
end
```

**New in v2.1:**
- `device_order` array tracks display position to IP mapping
- Enables device selection by number

#### SelectDevice()

```lua
function SelectDevice()
  local device_num = math.floor(Controls.device_selector.Value)
  
  if device_num < 1 or device_num > #device_order then
    Controls.selected_info.String = "Invalid device number"
    Controls.selected_url.String = ""
    return
  end
  
  local ip = device_order[device_num]
  local device = discovered_devices[ip]
  
  if device then
    local display_name = device.hostname
    if device.part_number then
      display_name = display_name .. " (" .. device.part_number .. ")"
    end
    
    Controls.selected_info.String = string.format("%s - %s", display_name, ip)
    Controls.selected_url.String = string.format("http://%s", ip)
    
    DebugPrint(string.format("Device %d selected: %s at %s", 
      device_num, device.hostname, ip))
  end
end
```

**Purpose:**
- Maps device number from knob to actual IP address
- Displays device information and formatted URL
- Validates selection range

#### OpenInBrowser()

```lua
function OpenInBrowser()
  local url = Controls.selected_url.String
  
  if not url or url == "" then
    DebugPrint("No URL selected. Select a device first.")
    Controls.status.String = "Select a device first"
    return
  end
  
  local mac_ip = Properties["Mac IP Address"].Value
  local service_port = Properties["Service Port"].Value
  local service_url = string.format("http://%s:%d?url=%s", 
    mac_ip, service_port, url)
  
  DebugPrint(string.format("Sending browser launch request to: %s", service_url))
  
  HttpClient.Download {
    Url = service_url,
    Headers = {
      ["Content-Type"] = "application/json"
    },
    Timeout = 5,
    EventHandler = function(tbl, code, data, error, headers)
      if code == 200 then
        DebugPrint("Browser launch successful")
        Controls.status.Value = 0
        Controls.status.String = "Browser opened successfully"
      else
        DebugPrint(string.format("Browser launch failed. Code: %s, Error: %s", 
          tostring(code), tostring(error)))
        Controls.status.Value = 2
        Controls.status.String = string.format("Browser launch failed (code: %s)", 
          tostring(code))
      end
    end
  }
end
```

**Features:**
- Constructs HTTP request to Mac service
- URL encoding and validation
- Error handling with status updates
- Debug logging for troubleshooting

---

## API Reference

### Plugin Functions

#### Core Functions

| Function | Parameters | Returns | Description |
|----------|-----------|---------|-------------|
| `Initialize()` | None | None | Sets up event handlers and initial state |
| `StartDiscovery()` | None | None | Begins UDP listening for 5 seconds |
| `UpdateDeviceList()` | None | None | Refreshes UI with filtered device list |
| `ParseQDPPacket()` | `data: string` | `table` | Extracts device info from XML |
| `SelectDevice()` | None | None | Maps selector value to device IP |
| `OpenInBrowser()` | None | None | Sends HTTP request to launch browser |

#### Q-SYS API Functions Used

| API | Usage | Notes |
|-----|-------|-------|
| `UdpSocket.New()` | Create UDP socket | Passive listener |
| `UdpSocket:Open()` | Bind to port 2467 | OS handles multicast |
| `UdpSocket:Close()` | Cleanup after scan | Prevents resource leak |
| `Timer.New()` | Create scan timeout | 5-second duration |
| `Timer:Start()` | Begin countdown | Triggers OnScanComplete |
| `Timer:Stop()` | Cancel timer | Cleanup on early exit |
| `HttpClient.Download` | HTTP GET request | Browser launch trigger |
| `Controls.<name>` | Access control values | Read/write UI state |
| `Properties["name"]` | Read property values | Mac IP, Service Port |

---

## Network Protocol

### QDP Listening

```
Binding: 0.0.0.0:2467
Protocol: UDP
Multicast: 224.0.23.175
Direction: Inbound only
Timeout: 5 seconds
```

### HTTP Browser Launch

```
Method: GET
URL: http://<mac-ip>:<port>?url=<device-url>
Timeout: 5 seconds
Headers: Content-Type: application/json
```

### Packet Flow Diagram

```
QDP Packet Flow:
Q-SYS Device ──(UDP 6504→2467)──> Multicast Group 224.0.23.175
                                         │
                                         ▼
                                  Plugin Listener
                                   (0.0.0.0:2467)

Browser Launch Flow:
Plugin ──(HTTP GET)──> Mac Service ──(macOS 'open')──> Browser
     192.168.1.x:8765           localhost:8765
```

---

## HTTP Client Integration

### HttpClient.Download Usage

```lua
HttpClient.Download {
  Url = "http://192.168.1.100:8765?url=http://192.168.1.50",
  Method = "GET",  -- Default
  Headers = {
    ["Content-Type"] = "application/json"
  },
  Timeout = 5,
  EventHandler = function(tbl, code, data, error, headers)
    -- code: HTTP status code (200, 400, 500, etc.)
    -- data: Response body (JSON string)
    -- error: Error message if failed
    -- headers: Response headers table
  end
}
```

### Response Handling

```lua
-- Success (200)
{
  status: "success",
  message: "Opened http://192.168.1.50",
  url: "http://192.168.1.50"
}

-- Error (400 - Bad Request)
Missing 'url' parameter

-- Error (500 - Internal Server Error)
Failed to execute 'open' command
```

### Error Codes

| Code | Meaning | Plugin Action |
|------|---------|---------------|
| 200 | Success | Set status to "Browser opened successfully" |
| 400 | Bad Request | Set status to "Invalid request" |
| 500 | Server Error | Set status to "Service error" |
| 0 | Timeout/Network | Set status to "Connection failed" |

---

## Mac Service Implementation

### Python Service Code Structure

```python
# qsys_browser_launcher.py

from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
import subprocess
import json

PORT = 8765

class BrowserLauncherHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        parsed = urlparse(self.path)
        params = parse_qs(parsed.query)
        
        if 'url' in params:
            url = params['url'][0]
            self.open_browser(url)
        else:
            self.send_error(400, "Missing 'url' parameter")
    
    def open_browser(self, url):
        if not (url.startswith('http://') or url.startswith('https://')):
            url = 'http://' + url
        
        result = subprocess.run(['open', url], 
                               capture_output=True, 
                               timeout=5)
        
        if result.returncode == 0:
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            response = json.dumps({
                'status': 'success',
                'message': f'Opened {url}',
                'url': url
            })
            self.wfile.write(response.encode())

# Start server
server = HTTPServer(('', PORT), BrowserLauncherHandler)
server.serve_forever()
```

### LaunchDaemon Configuration

```xml
<!-- /Library/LaunchDaemons/com.qsc.browser-launcher.plist -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" 
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
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

### Service Management Commands

```bash
# Load (start) service
sudo launchctl load /Library/LaunchDaemons/com.qsc.browser-launcher.plist

# Unload (stop) service
sudo launchctl unload /Library/LaunchDaemons/com.qsc.browser-launcher.plist

# Check status
sudo launchctl list | grep qsc

# View logs
tail -f "/Library/Application Support/QSC/browser_launcher.log"

# Test service
curl "http://localhost:8765?url=http://google.com"
```

---

## Debugging

### Debug Output

Enable comprehensive logging by setting `DEBUG = true` (default):

```lua
local DEBUG = true

function DebugPrint(message)
  if DEBUG then
    print("[QSC Discovery] " .. message)
  end
end
```

### Debug Messages

#### Discovery Process

```
[QSC Discovery] === StartDiscovery called ===
[QSC Discovery] Setting up QDP listener on port 2467
[QSC Discovery] Attempting to bind to 0.0.0.0:2467
[QSC Discovery] Successfully listening on 0.0.0.0:2467
[QSC Discovery] Listening for 5 seconds...
```

#### Packet Reception

```
[QSC Discovery] === QDP packet received ===
[QSC Discovery] From: 192.168.1.100:6504
[QSC Discovery] Packet length: 512 bytes
[QSC Discovery] Packet content (first 500 chars): <QDP><device>...
[QSC Discovery] Valid QDP device announcement detected
[QSC Discovery] --- Parsed Device Info ---
[QSC Discovery]   hostname: audio-core-main
[QSC Discovery]   ip: 192.168.1.100
[QSC Discovery]   type: lcqln
[QSC Discovery]   part_number: Core 110f
[QSC Discovery] --- End Parsed Info ---
[QSC Discovery] *** NEW DEVICE DISCOVERED: audio-core-main at 192.168.1.100 ***
```

#### Device Selection

```
[QSC Discovery] Select Device button pressed
[QSC Discovery] Device 1 selected: audio-core-main at 192.168.1.100
[QSC Discovery] Web URL: http://192.168.1.100
```

#### Browser Launch

```
[QSC Discovery] Open Browser button pressed
[QSC Discovery] Sending browser launch request to: http://192.168.1.50:8765?url=http://192.168.1.100
[QSC Discovery] URL to open: http://192.168.1.100
[QSC Discovery] Browser launch successful
```

### Common Issues

#### No Packets Received

```
Symptom: "Scan complete. Found 0 device(s)"
Causes:
  1. Multicast not reaching plugin
  2. Network switch blocking IGMP
  3. Wrong network segment
  
Debug:
  - Verify device is broadcasting (check device logs)
  - Test multicast with igmpproxy or similar
  - Check switch IGMP snooping config
  - Verify plugin and device on same subnet
```

#### Parsing Failed

```
Symptom: "QDP packet received" but no devices added
Causes:
  1. XML structure changed
  2. Hostname/IP in unexpected tags
  3. Filters excluding all devices
  
Debug:
  - Check raw packet content (first 500 chars in debug)
  - Verify XML tags match parser patterns
  - Temporarily disable all filters
  - Check --- Parsed Device Info --- section for NULL values
```

#### Socket Binding Failed

```
Symptom: "Error: Failed to open UDP port"
Causes:
  1. Insufficient permissions
  2. Port 2467 conflict
  3. Network adapter disabled
  
Debug:
  - Run Q-SYS Designer as administrator
  - Close Q-SYS Designer built-in discovery window
  - Check Windows Firewall rules
  - Verify network adapter status
```

#### Browser Launch Failed

```
Symptom: "Browser launch failed (code: 0)"
Causes:
  1. Mac service not running
  2. Wrong Mac IP address in properties
  3. Firewall blocking connection
  4. Network connectivity issue
  
Debug:
  - Test service: curl "http://localhost:8765?url=http://google.com"
  - Check service: sudo launchctl list | grep qsc
  - View logs: tail -f "/Library/Application Support/QSC/browser_launcher.log"
  - Verify Mac IP: ifconfig | grep "inet " | grep -v 127.0.0.1
  - Test from Q-SYS machine: ping <mac-ip>
```

### Troubleshooting Workflow

```
1. Check Q-SYS Designer Debug Output
   └─> Enable: View → Debug Output
   └─> Look for: [QSC Discovery] messages

2. Test Discovery
   └─> Click Scan Network
   └─> Wait 5 seconds
   └─> Check for packet reception messages

3. Test Browser Service (macOS)
   └─> Run: curl "http://localhost:8765?url=http://google.com"
   └─> Should open Google in browser

4. Test Plugin → Service Communication
   └─> Select a device
   └─> Click "Open Browser"
   └─> Check debug output for HTTP request
   └─> Check Mac service logs

5. Verify Network Path
   └─> From Q-SYS machine: ping <mac-ip>
   └─> From Q-SYS machine: telnet <mac-ip> 8765
   └─> Check firewall rules on both machines
```

---

## Customization

### Changing Scan Duration

Modify the timer start value in `StartDiscovery()`:

```lua
-- Change from 5 seconds to 10 seconds
discovery_timer:Start(10)

-- Remember to update debug message
DebugPrint("Listening for 10 seconds...")
```

### Adding Custom Device Fields

Extract additional fields from QDP packets:

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
  device_info.lan_b_ip = string.match(data, "<lan_b_ip>([^<]+)</lan_b_ip>")
  
  return device_info
end
```

### Custom Browser Launch URL

Modify URL format in `SelectDevice()`:

```lua
-- Default (HTTP)
Controls.selected_url.String = string.format("http://%s", ip)

-- HTTPS
Controls.selected_url.String = string.format("https://%s", ip)

-- Custom Port
Controls.selected_url.String = string.format("http://%s:8080", ip)

-- Specific Page
Controls.selected_url.String = string.format("http://%s/admin", ip)
```

### Alternative Browser Launch Methods

**Windows PowerShell Service:**

```powershell
# browser-launcher.ps1
param([string]$url)
Start-Process $url
```

**Linux systemd service:**

```bash
#!/bin/bash
# browser-launcher.sh
xdg-open "$1"
```

### Export Device List to CSV

```lua
function ExportToCSV()
  local csv = "Hostname,IP,Part Number,Type,MAC Address\n"
  for ip, device in pairs(discovered_devices) do
    csv = csv .. string.format("%s,%s,%s,%s,%s\n",
      device.hostname or "",
      ip,
      device.part_number or "",
      device.type or "",
      device.mac or "")
  end
  
  -- Note: Q-SYS Lua doesn't support file I/O directly
  -- Would need external service similar to browser launcher
  DebugPrint(csv)
end
```

### Custom Filter Logic

```lua
-- Example: Only show Cores and I/O Frames
function CustomFilterLogic(device)
  local allowed_types = {"core", "lcqln", "qio"}
  
  if device.type then
    for _, allowed in ipairs(allowed_types) do
      if string.find(device.type:lower(), allowed) then
        return false  -- Don't filter (show device)
      end
    end
  end
  
  return true  -- Filter out
end

-- Apply in UpdateDeviceList()
if CustomFilterLogic(device) then
  should_exclude = true
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

5. **No System Command Execution**: Cannot call `open` or `start` directly
   - Solution: External service architecture (Mac service)

6. **HttpClient Limitations**: 
   - No WebSocket support
   - No custom verb support (GET/POST only)
   - 60-second maximum timeout

### Network Limitations

1. **Same Subnet Requirement**: Multicast typically doesn't cross L3 boundaries
   - Solution: Configure multicast routing or use on same VLAN

2. **IGMP Snooping**: Some switches block multicast by default
   - Solution: Configure IGMP snooping/querier on switch

3. **Port Conflicts**: Q-SYS Designer may use port 2467 for its own discovery
   - Solution: Close Designer's built-in discovery or use plugin on different machine

4. **Firewall Rules**: Network/host firewalls may block traffic
   - Solution: Allow UDP 2467 inbound, TCP 8765 for browser service

### Implementation Limitations

1. **No Persistent Storage**: Devices cleared each scan
2. **No Historical Tracking**: No record of device up/down events
3. **Limited XML Parsing**: Pattern matching, not full XML parser
4. **Fixed Filter Count**: Only 10 filter slots
5. **Doesn't Work in Emulation Mode**: Requires deployed Core
6. **macOS Only Browser Launch**: Windows/Linux not yet supported
7. **No Device Authentication**: Cannot log into password-protected devices
8. **Fixed Timeout**: 5-second scan cannot be changed via UI

### Browser Launch Limitations

1. **Platform-Specific**: Currently macOS only
2. **Network-Dependent**: Requires Q-SYS and Mac on same network
3. **No HTTPS Validation**: No certificate checking for HTTPS URLs
4. **Single User**: Service runs system-wide, not per-user
5. **HTTP Only**: Cannot pass credentials or custom headers to opened URL

---

## Future Enhancements

### Planned Features

#### Short-term (v2.5-2.6)
- [ ] Windows browser launch support (PowerShell service)
- [ ] Linux browser launch support (xdg-open service)
- [ ] Configurable scan duration (property setting)
- [ ] Device details popup (full XML view)

#### Medium-term (v2.7-3.0)
- [ ] Active querying (send query packets)
- [ ] Persistent device list (accumulate across scans)
- [ ] CSV/JSON export functionality
- [ ] Historical logging (device up/down events)
- [ ] Regex support for filters
- [ ] Device status monitoring (ping integration)

#### Long-term (v3.1+)
- [ ] Multi-subnet discovery (mDNS-SD integration)
- [ ] Network topology mapping
- [ ] Automated device configuration
- [ ] SNMP integration for non-Q-SYS devices
- [ ] Web-based dashboard view
- [ ] Mobile app integration

### Community Requests

- Device grouping/tagging
- Save/load filter presets
- Alert on device offline
- Integration with Q-SYS UCI
- REST API for external control

---

## Version History

### v2.5 (Current - 2025-11-22)
- **Removed:** "Get URL" button (redundant functionality)
- **Changed:** Device selector knob now automatically populates URL on change
- **Improved:** Simplified user workflow (select → open)
- **Changed:** UI layout streamlined with fewer controls

### v2.4 (2025-11-22)
- **Changed:** Scan time reduced from 15 to 5 seconds
- **Changed:** Updated all documentation to reflect faster scan
- **Fixed:** Minor optimization in timer management

### v2.3 (2025-11-22)
- **Added:** Enhanced XML parsing with multiple tag fallbacks
- **Added:** Improved hostname detection for various device types
- **Added:** Better fallback logic when hostname missing
- **Fixed:** Hostname parsing for devices using alternative XML tags
- **Changed:** Expanded packet preview from 300 to 500 characters
- **Changed:** More detailed parsed device info debug output

### v2.2 (2025-11-22)
- **Added:** HTTP client integration for browser launch
- **Added:** Mac service communication protocol
- **Added:** Plugin properties (Mac IP Address, Service Port)
- **Added:** "Open Browser" button
- **Added:** Error handling for HTTP requests
- **Changed:** Status indicators for browser launch feedback

### v2.1 (2025-11-22)
- **Added:** Device selector knob (0-100 range)
- **Added:** "Get URL" button
- **Added:** Selected device info display
- **Added:** Selected URL display field
- **Added:** Device order tracking array
- **Changed:** UI layout with device selection section
- **Fixed:** Device mapping for selection by number

### v2.0 (2025-11-19)
- **Added:** 10 configurable filters
- **Added:** Real-time filter updates
- **Added:** Pattern-based filtering (hostname, IP, part number)
- **Fixed:** Continuous packet reception bug
- **Fixed:** Socket cleanup on timeout
- **Changed:** Improved XML parsing robustness
- **Changed:** Enhanced debug logging
- **Changed:** Updated UI with filter section

### v1.0 (2025-11-15)
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
5. **Test Platforms**: Help test on different OS/network configurations

### Contribution Guidelines

- Follow existing code style and conventions
- Add debug logging for new features
- Test your changes thoroughly in Q-SYS Designer
- Update documentation for any new features or changes
- Be respectful and constructive in all interactions
- Include comments for complex logic

### Priority Contributions

We're especially interested in:
- Windows browser launch implementation
- Linux browser launch implementation
- Network configuration edge case testing
- UI/UX improvements
- Documentation improvements
- Example use cases and workflows

### Contact

For questions, support, or collaboration:
- **Author**: Brandon Cecil
- **Company**: Fresh AVL Co.
- **GitHub**: https://github.com/bcecilpgh/QDP-Device-Discovery
- **Email**: Available via GitHub

### Building from Source

```lua
-- No build process required
-- Direct .qplug file deployment to Q-SYS Designer

-- File structure:
QSC_Device_Discovery_URL_Enhanced.qplug
  └── Single Lua file with embedded layout/controls
  
-- Testing:
1. Copy .qplug to Q-SYS Plugins folder
2. Restart Q-SYS Designer (or refresh plugins)
3. Add to design and test
```

### Testing Checklist

- [ ] Discovery functionality (scan, display, filters)
- [ ] Device selection (knob, button, display)
- [ ] Browser launch (Mac service integration)
- [ ] Error handling (network, service, validation)
- [ ] Debug output (comprehensive logging)
- [ ] UI responsiveness (5-second timeout)
- [ ] Edge cases (0 devices, 100+ devices, filters)
- [ ] Cross-network scenarios (same/different subnets)

---

**Document Version**: 2.4  
**Last Updated**: November 22, 2025  
**Maintainer**: Brandon Cecil - Fresh AVL Co.
