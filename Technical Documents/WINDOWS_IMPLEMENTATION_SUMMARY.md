# Windows Browser Launch Implementation Summary

## Overview

Full cross-platform browser launch support is now available for both macOS and Windows. Windows users can now open Q-SYS device web interfaces with one click from Q-SYS Designer.

---

## Windows Implementation Options

### Option 1: PowerShell Service (Recommended)

**Why Recommended:**
- Built into Windows 10/11 - no installation required
- Lightweight (~20MB memory)
- Fast startup
- Easy to use - just double-click the .bat file

**Files:**
- `qsys_browser_launcher.ps1` - PowerShell HTTP server
- `start_browser_service.bat` - Easy launcher

**Usage:**
```powershell
powershell -ExecutionPolicy Bypass -File qsys_browser_launcher.ps1
```

Or simply double-click `start_browser_service.bat`

**How It Works:**
- Uses `System.Net.HttpListener` to create HTTP server
- Listens on port 8765
- Parses URL parameter from query string
- Uses PowerShell's `Start-Process` to open URLs in default browser
- Returns JSON response with success/failure status

### Option 2: Python Service (Alternative)

**When to Use:**
- User already has Python installed
- Want consistency with Mac version
- Prefer Python for customization

**Files:**
- `qsys_browser_launcher_windows.py` - Python HTTP server

**Usage:**
```cmd
python qsys_browser_launcher_windows.py
```

**How It Works:**
- Uses Python's `http.server` module
- Listens on port 8765
- Uses `os.startfile()` (Windows-specific) to open URLs
- Returns JSON response

---

## Technical Comparison

| Feature | macOS Version | Windows PowerShell | Windows Python |
|---------|---------------|-------------------|----------------|
| Language | Python 3 | PowerShell 5.1+ | Python 3.6+ |
| Pre-installed | Yes | Yes (Win10/11) | No |
| Memory | ~15MB | ~20MB | ~15MB |
| Startup | Fast | Fast | Fast |
| Browser Launch | `open` command | `Start-Process` | `os.startfile()` |
| Service Type | LaunchDaemon | Task Scheduler/NSSM | Task Scheduler/NSSM |
| Auto-start Setup | `launchctl` | Task Scheduler | Task Scheduler |

---

## Protocol Compatibility

All three implementations use the identical HTTP protocol:

**Request:**
```
GET http://<ip>:8765?url=http://<device-ip>
```

**Response (Success):**
```json
{
  "status": "success",
  "message": "Opened http://192.168.1.100",
  "url": "http://192.168.1.100"
}
```

**Response (Error):**
```
HTTP 400 Bad Request - Missing 'url' parameter
HTTP 500 Internal Server Error - Failed to open URL
```

This ensures the Q-SYS plugin works identically across platforms.

---

## Key Implementation Details

### PowerShell Service

```powershell
# Create HTTP listener
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://+:8765/")
$listener.Start()

# Handle requests
$context = $listener.GetContext()
$url = $context.Request.QueryString["url"]

# Open in browser
Start-Process $url

# Send response
$response.StatusCode = 200
```

**Advantages:**
- No dependencies
- Native Windows functionality
- Easy error handling
- Built-in JSON serialization

**Considerations:**
- Requires Execution Policy bypass
- May need Administrator for port binding (8765 is safe)

### Python Service (Windows)

```python
import os
from http.server import HTTPServer, BaseHTTPRequestHandler

class Handler(BaseHTTPRequestHandler):
    def open_browser(self, url):
        os.startfile(url)  # Windows-specific
        self.send_response(200)
```

**Advantages:**
- Cross-platform code (with platform detection)
- Familiar Python syntax
- Easy to customize

**Considerations:**
- Requires Python installation
- Need to ensure Python in PATH

---

## Auto-Start Configuration

### Windows Task Scheduler

**PowerShell Version:**
- Trigger: At system startup
- Program: `powershell.exe`
- Arguments: `-ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\path\to\qsys_browser_launcher.ps1"`
- Run with highest privileges: Yes
- Run whether user is logged on or not: Yes

**Python Version:**
- Same as above, but:
- Program: `pythonw.exe` (no console window)
- Arguments: `"C:\path\to\qsys_browser_launcher_windows.py"`

### NSSM (Alternative)

For more advanced service management:
```cmd
nssm.exe install QSCBrowserLauncher powershell.exe
nssm.exe set QSCBrowserLauncher AppParameters "-ExecutionPolicy Bypass -File C:\path\to\qsys_browser_launcher.ps1"
```

---

## Security Considerations

### Windows Firewall

Unlike macOS, Windows Firewall may require explicit configuration:

**Inbound Rule Required:**
- Protocol: TCP
- Port: 8765
- Action: Allow
- Profile: All (Domain, Private, Public)

**Automatic Rule Creation:**
Windows may prompt on first run. Click "Allow access" when prompted.

### Network Security

Same as macOS:
- Listens on all interfaces (0.0.0.0)
- Any network device can send URLs
- Only HTTP/HTTPS URLs accepted
- No authentication required
- Consider restricting to specific IP ranges if concerned

---

## Testing

### Quick Test (PowerShell)

```powershell
# Test locally
Invoke-WebRequest -Uri "http://localhost:8765?url=http://google.com"

# Test from Q-SYS (use actual PC IP)
Invoke-WebRequest -Uri "http://192.168.1.100:8765?url=http://google.com"
```

### Quick Test (Command Prompt)

```cmd
curl "http://localhost:8765?url=http://google.com"
```

### From Another Computer

```bash
curl "http://192.168.1.100:8765?url=http://google.com"
```

---

## Installation Steps Summary

### For End Users (Simplest):

1. Extract files to `C:\QSC\BrowserLauncher\`
2. Double-click `start_browser_service.bat`
3. Note Windows PC's IP address (run `ipconfig`)
4. Configure Q-SYS plugin properties with PC IP
5. Done!

### For Auto-Start on Boot:

1. Follow "For End Users" steps
2. Open Task Scheduler
3. Create Basic Task → "When computer starts"
4. Point to PowerShell + script
5. Set "Run with highest privileges"
6. Done!

---

## Troubleshooting

### Common Issues

**"Execution Policy Error"**
```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass
```

**"Port 8765 in use"**
```cmd
netstat -ano | findstr :8765
```
Kill the process or use different port.

**"Access Denied"**
- Run as Administrator
- Or use port > 1024 (8765 is fine)

**Firewall Blocking**
- Create inbound rule for TCP port 8765
- Or temporarily disable firewall to test

**Browser Doesn't Open**
```powershell
# Test locally first
Start-Process "http://google.com"

# If this works, issue is with the service
# If this doesn't work, issue is with browser configuration
```

---

## Files Provided

**Windows-Specific:**
1. `qsys_browser_launcher.ps1` - PowerShell service (recommended)
2. `qsys_browser_launcher_windows.py` - Python service (alternative)
3. `start_browser_service.bat` - Easy launcher
4. `WINDOWS_SETUP_INSTRUCTIONS.md` - Complete installation guide

**Cross-Platform:**
- Q-SYS plugin works with both Mac and Windows services
- Same HTTP protocol
- Same port (8765)
- Same configuration

---

## Future Enhancements

### Potential Improvements:

1. **Linux Support**
   - Add `xdg-open` support for Linux
   - Create systemd service files

2. **GUI Configuration Tool**
   - Windows Forms or WPF app
   - Configure port, auto-start, etc.

3. **Authentication**
   - Add API key requirement
   - IP whitelist configuration

4. **Logging**
   - File-based logging
   - Rotation and retention

5. **Custom Browser**
   - Ability to specify browser
   - Browser profiles

---

## Architecture Decision Rationale

### Why PowerShell Over Batch/VBScript?

**PowerShell Advantages:**
- Modern, maintained language
- Native HTTP server support
- JSON serialization built-in
- Better error handling
- Cross-session support

**Batch/VBScript Issues:**
- No native HTTP server
- Would require third-party tools
- Difficult error handling
- Limited string processing

### Why os.startfile() for Python?

**Windows-Specific:**
- `os.startfile()` is Windows-specific but most reliable
- Alternative `subprocess.run(['start', url], shell=True)` has issues
- `webbrowser.open()` works but `startfile` is cleaner

**Platform Detection:**
Could add:
```python
import platform
if platform.system() == 'Windows':
    os.startfile(url)
elif platform.system() == 'Darwin':
    subprocess.run(['open', url])
elif platform.system() == 'Linux':
    subprocess.run(['xdg-open', url])
```

---

## Documentation Updates

All documentation updated to reflect Windows support:

- ✅ README.md - Windows quick start
- ✅ CHANGELOG.md - v2.5 with Windows support
- ✅ WINDOWS_SETUP_INSTRUCTIONS.md - Complete Windows guide
- ✅ Files included section updated
- ✅ Version history updated
- ✅ Known limitations updated

---

## Success Criteria

Windows implementation is successful because:

1. ✅ Works without installation (PowerShell version)
2. ✅ Simple user experience (double-click .bat)
3. ✅ Protocol-compatible with Mac version
4. ✅ Auto-start capability (Task Scheduler)
5. ✅ Comprehensive documentation
6. ✅ Multiple implementation options (PS + Python)
7. ✅ Easy troubleshooting
8. ✅ Firewall configuration documented

---

**Implementation Date:** November 22, 2025  
**Version:** 2.5  
**Author:** Brandon Cecil / Fresh AVL Co.
