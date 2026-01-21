@echo off
REM Q-SYS Browser Launcher - Easy Startup Script
REM Double-click this file to start the browser launcher service

echo ================================================
echo Q-SYS Browser Launcher Service
echo ================================================
echo.

REM Check if Python is available
python --version >nul 2>&1
if %errorlevel% equ 0 (
    echo Python detected - starting Python service...
    echo.
    python qsys_browser_launcher_windows.py
    goto :end
)

REM Python not found, try PowerShell
echo Python not found, using PowerShell...
echo.
powershell -ExecutionPolicy Bypass -File qsys_browser_launcher.ps1

:end
echo.
echo Service stopped.
pause
