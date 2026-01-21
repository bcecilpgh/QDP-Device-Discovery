# Q-SYS Browser Launcher - Windows Installation Guide

Simple service to open Q-SYS device web interfaces from Q-SYS Designer with one click.

---

## Quick Start (Easiest Method)

### Step 1: Download Files
1. Download all files to a folder (e.g., `C:\QSC\BrowserLauncher\`)
2. You should have:
   - `start_browser_service.bat`
   - `qsys_browser_launcher.ps1`
   - `qsys_browser_launcher_windows.py` (optional)

### Step 2: Start the Service
1. **Double-click** `start_browser_service.bat`
2. If prompted, click **"Run anyway"** or **"More info" → "Run anyway"**
3. You should see:
   ```
   Q-SYS Browser Launcher Service for Windows
   ===========================================
   Listening on: http://localhost:8765
   ```

### Step 3: Get Your PC's IP Address
```cmd
ipconfig
```
Look for "IPv4 Address" under your active network adapter (e.g., 192.168.1.100)

### Step 4: Configure Q-SYS Plugin
1. Open Q-SYS Designer
2. Add the QSC Device Discovery plugin to your design
3. Right-click plugin → **Properties**
4. Set **"Mac IP Address"** to your Windows PC's IP (e.g., 192.168.1.100)
5. Set **"Service Port"** to `8765`
6. Click **OK**

### Step 5: Use It!
1. Click **"Scan Network"**
2. Turn the **Device #** knob to select a device
3. Click **"Open Browser"**
4. Device web interface opens automatically!

---

## Installation Methods

### Method 1: PowerShell (Recommended - No Installation Required)

**Advantages:**
- No additional software needed
- Built into Windows 10/11
- Lightweight and fast

**To Run:**
```powershell
powershell -ExecutionPolicy Bypass -File qsys_browser_launcher.ps1
```

Or simply double-click `start_browser_service.bat`

### Method 2: Python (If You Have Python Installed)

**Advantages:**
- More portable code
- Consistent with Mac version
- Easier to customize

**Requirements:**
- Python 3.6 or later

**To Run:**
```cmd
python qsys_browser_launcher_windows.py
```

**Install Python (if needed):**
1. Download from https://www.python.org/downloads/
2. Run installer, check **"Add Python to PATH"**
3. Restart command prompt

---

## Running as a Windows Service (Auto-Start on Boot)

### Option 1: Task Scheduler (Built-in, Easiest)

#### PowerShell Version:

1. **Open Task Scheduler**
   - Press `Win+R`, type `taskschd.msc`, press Enter

2. **Create Basic Task**
   - Click **"Create Basic Task"** in the right panel
   - Name: `QSC Browser Launcher`
   - Description: `Launches browsers from Q-SYS Designer`
   - Click **Next**

3. **Trigger: When the computer starts**
   - Select **"When the computer starts"**
   - Click **Next**

4. **Action: Start a program**
   - Select **"Start a program"**
   - Click **Next**

5. **Program Settings**
   - Program/script: `powershell.exe`
   - Arguments: `-ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\QSC\BrowserLauncher\qsys_browser_launcher.ps1"`
   - Start in: `C:\QSC\BrowserLauncher\`
   - Click **Next**, then **Finish**

6. **Additional Settings** (Right-click task → Properties)
   - General tab: Check **"Run with highest privileges"**
   - General tab: Check **"Run whether user is logged on or not"**
   - Conditions tab: Uncheck **"Start the task only if the computer is on AC power"**
   - Click **OK**

#### Python Version:

Same steps, but for Program Settings:
- Program/script: `pythonw.exe` (or `python.exe`)
- Arguments: `"C:\QSC\BrowserLauncher\qsys_browser_launcher_windows.py"`
- Start in: `C:\QSC\BrowserLauncher\`

### Option 2: NSSM (Non-Sucking Service Manager)

**More advanced, better service management:**

1. **Download NSSM**
   - Get from: https://nssm.cc/download
   - Extract to `C:\QSC\nssm\`

2. **Install Service** (Run as Administrator):
   ```cmd
   C:\QSC\nssm\nssm.exe install QSCBrowserLauncher
   ```

3. **Configure in GUI:**
   - Application Path: `C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe`
   - Arguments: `-ExecutionPolicy Bypass -File "C:\QSC\BrowserLauncher\qsys_browser_launcher.ps1"`
   - Startup directory: `C:\QSC\BrowserLauncher\`
   - Click **Install service**

4. **Start Service:**
   ```cmd
   net start QSCBrowserLauncher
   ```

5. **Manage Service:**
   - Start: `net start QSCBrowserLauncher`
   - Stop: `net stop QSCBrowserLauncher`
   - Remove: `nssm.exe remove QSCBrowserLauncher confirm`

---

## Testing the Service

### Test 1: Local Test
```powershell
Invoke-WebRequest -Uri "http://localhost:8765?url=http://google.com"
```
Google should open in your browser.

### Test 2: From Another Computer
```powershell
Invoke-WebRequest -Uri "http://192.168.1.100:8765?url=http://google.com"
```
(Replace 192.168.1.100 with your PC's IP)

### Test 3: Using curl (if installed)
```cmd
curl "http://localhost:8765?url=http://google.com"
```

---

## Firewall Configuration

### Allow Incoming Connections

1. **Open Windows Defender Firewall**
   - Press `Win+R`, type `wf.msc`, press Enter

2. **Create Inbound Rule**
   - Click **"Inbound Rules"** in left panel
   - Click **"New Rule..."** in right panel
   - Rule Type: **"Port"**
   - Click **Next**

3. **Port Settings**
   - Protocol: **TCP**
   - Specific local ports: **8765**
   - Click **Next**

4. **Action**
   - Select **"Allow the connection"**
   - Click **Next**

5. **Profile**
   - Check all (Domain, Private, Public)
   - Click **Next**

6. **Name**
   - Name: `QSC Browser Launcher`
   - Description: `Allows Q-SYS to trigger browser opening`
   - Click **Finish**

---

## Troubleshooting

### Service Won't Start

**Error: "Port already in use"**
```cmd
netstat -ano | findstr :8765
```
If port is in use, either:
- Kill the process using the PID shown
- Use a different port (edit scripts, change 8765 to 8766)

**Error: "Access Denied" or "Permission Required"**
- Run as Administrator
- Or use a port above 1024 (current default 8765 should work)

**PowerShell: "Execution Policy Error"**
```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass
```
Then try again.

### Browser Doesn't Open

**Test the service:**
```powershell
Invoke-WebRequest "http://localhost:8765?url=http://google.com"
```

**Check Windows Firewall:**
- Make sure the firewall rule is active
- Temporarily disable firewall to test

**Check Q-SYS Plugin Properties:**
- Verify Windows PC IP address is correct
- Try using hostname instead: `DESKTOP-12345` or `my-pc.local`

**Check Network:**
```cmd
ping <qsys-core-ip>
```
From Windows PC to Q-SYS Core (or Designer PC)

### Service Stops Unexpectedly

**PowerShell windows closes:**
- Use Task Scheduler with "Run whether user is logged on or not"
- Or use NSSM to run as true Windows service

**Python crashes:**
- Check if Python is still installed
- Verify Python is in PATH: `python --version`

---

## Command Reference

### PowerShell Service

**Start (foreground):**
```powershell
powershell -ExecutionPolicy Bypass -File qsys_browser_launcher.ps1
```

**Start (background):**
```powershell
Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -File C:\QSC\BrowserLauncher\qsys_browser_launcher.ps1"
```

**Change Port:**
```powershell
powershell -ExecutionPolicy Bypass -File qsys_browser_launcher.ps1 8766
```

### Python Service

**Start:**
```cmd
python qsys_browser_launcher_windows.py
```

**Start (background, no console):**
```cmd
pythonw qsys_browser_launcher_windows.py
```

**Change Port:**
```cmd
python qsys_browser_launcher_windows.py 8766
```

### Task Scheduler

**List scheduled tasks:**
```cmd
schtasks /query /tn "QSC Browser Launcher"
```

**Run task manually:**
```cmd
schtasks /run /tn "QSC Browser Launcher"
```

**Stop task:**
```cmd
schtasks /end /tn "QSC Browser Launcher"
```

**Delete task:**
```cmd
schtasks /delete /tn "QSC Browser Launcher" /f
```

---

## Uninstall

### If Using Task Scheduler:
1. Open Task Scheduler (`taskschd.msc`)
2. Find "QSC Browser Launcher" task
3. Right-click → **Delete**

### If Using NSSM:
```cmd
nssm.exe stop QSCBrowserLauncher
nssm.exe remove QSCBrowserLauncher confirm
```

### Remove Files:
Delete the folder: `C:\QSC\BrowserLauncher\`

### Remove Firewall Rule:
1. Open Windows Defender Firewall (`wf.msc`)
2. Find "QSC Browser Launcher" rule
3. Right-click → **Delete**

---

## Security Considerations

- Service listens on all network interfaces (0.0.0.0)
- Any device on your network can send URLs to open
- Service only accepts HTTP/HTTPS URLs
- Consider restricting firewall rule to specific IPs if concerned
- Service runs with user permissions (not elevated unless configured)

---

## Comparison: PowerShell vs Python

| Feature | PowerShell | Python |
|---------|-----------|---------|
| Installation Required | No (built-in) | Yes (python.org) |
| Startup Speed | Fast | Fast |
| Memory Usage | ~20MB | ~15MB |
| Customization | Moderate | Easy |
| Cross-platform | Windows only | Windows/Mac/Linux |
| **Recommendation** | **Best for most users** | Best if you know Python |

---

## Advanced: Custom Port

To use a different port (e.g., 8766):

**PowerShell:**
```powershell
powershell -ExecutionPolicy Bypass -File qsys_browser_launcher.ps1 8766
```

**Python:**
```cmd
python qsys_browser_launcher_windows.py 8766
```

**Q-SYS Plugin:**
- Update "Service Port" property to `8766`

**Firewall:**
- Create rule for port 8766 instead of 8765

---

## Files Reference

| File | Purpose | Required |
|------|---------|----------|
| `start_browser_service.bat` | Easy double-click startup | Recommended |
| `qsys_browser_launcher.ps1` | PowerShell service (no install) | Recommended |
| `qsys_browser_launcher_windows.py` | Python service | Optional |

**Minimum Required:**
- `qsys_browser_launcher.ps1` (PowerShell version)

**OR**

- `qsys_browser_launcher_windows.py` (Python version - requires Python)

---

## Support

**Common Issues:**
- Port already in use → Change to different port
- Access denied → Run as Administrator
- Firewall blocking → Add firewall rule
- Can't find PC IP → Use `ipconfig` command

**For Help:**
- Check Q-SYS Designer debug output
- Check service console window for errors
- Test with `Invoke-WebRequest` locally first
- Verify network connectivity with `ping`

---

**License:** MIT License  
**Author:** Brandon Cecil / Fresh AVL Co.  
**Copyright:** 2025
