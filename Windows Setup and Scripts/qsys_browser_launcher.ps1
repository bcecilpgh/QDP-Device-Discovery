# Q-SYS Browser Launcher Service for Windows (PowerShell)
# No Python required - uses built-in PowerShell
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File qsys_browser_launcher.ps1 [port]
#
# Default port: 8765

param(
    [int]$Port = 8765
)

Write-Host "Q-SYS Browser Launcher Service for Windows (PowerShell)" -ForegroundColor Green
Write-Host "=======================================================" -ForegroundColor Green
Write-Host "Listening on: http://localhost:$Port"
Write-Host "Access from Q-SYS: http://<pc-ip>:$Port`?url=<device-url>"
Write-Host "Press Ctrl+C to stop`n"

# Create HTTP listener
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://+:$Port/")

try {
    $listener.Start()
    Write-Host "Server started successfully on port $Port`n" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: Failed to start server on port $Port" -ForegroundColor Red
    Write-Host "This may require administrator privileges or the port may be in use.`n" -ForegroundColor Yellow
    Write-Host "Try running PowerShell as Administrator, or use a different port:" -ForegroundColor Yellow
    Write-Host "  powershell -ExecutionPolicy Bypass -File qsys_browser_launcher.ps1 8766`n" -ForegroundColor Yellow
    exit 1
}

Write-Host "Waiting for requests...`n"

# Main request handling loop
while ($listener.IsListening) {
    try {
        # Wait for incoming request
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Host "[$timestamp] Request from: $($request.RemoteEndPoint)"
        
        # Parse query string for 'url' parameter
        $url = $null
        if ($request.QueryString["url"]) {
            $url = $request.QueryString["url"]
        }
        
        if ($url) {
            # Ensure URL has protocol
            if (-not ($url -match "^https?://")) {
                $url = "http://$url"
            }
            
            Write-Host "Opening URL: $url" -ForegroundColor Cyan
            
            try {
                # Open URL in default browser
                Start-Process $url
                
                # Send success response
                $responseData = @{
                    status = "success"
                    message = "Opened $url"
                    url = $url
                } | ConvertTo-Json
                
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseData)
                $response.ContentType = "application/json"
                $response.ContentLength64 = $buffer.Length
                $response.StatusCode = 200
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
                
                Write-Host "Success: Browser opened`n" -ForegroundColor Green
            }
            catch {
                Write-Host "ERROR: Failed to open browser - $($_.Exception.Message)" -ForegroundColor Red
                
                $errorData = "Failed to open URL: $($_.Exception.Message)"
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($errorData)
                $response.ContentType = "text/plain"
                $response.ContentLength64 = $buffer.Length
                $response.StatusCode = 500
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
            }
        }
        else {
            # Missing URL parameter
            Write-Host "ERROR: Missing 'url' parameter" -ForegroundColor Red
            
            $errorData = "Missing 'url' parameter"
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($errorData)
            $response.ContentType = "text/plain"
            $response.ContentLength64 = $buffer.Length
            $response.StatusCode = 400
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        
        $response.Close()
    }
    catch {
        Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Cleanup
$listener.Stop()
$listener.Close()
Write-Host "`nServer stopped." -ForegroundColor Yellow
