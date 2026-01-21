#!/usr/bin/env python3
"""
Q-SYS Browser Launcher Service for macOS
Listens for HTTP requests from Q-SYS and opens URLs in default browser

Usage:
    python3 qsys_browser_launcher.py [port]
    
Default port: 8765
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
import subprocess
import sys
import json

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8765

class BrowserLauncherHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        """Custom logging"""
        print(f"[{self.log_date_time_string()}] {format % args}")
    
    def do_GET(self):
        """Handle GET requests with URL parameter"""
        parsed = urlparse(self.path)
        params = parse_qs(parsed.query)
        
        if 'url' in params:
            url = params['url'][0]
            self.open_browser(url)
        else:
            self.send_error(400, "Missing 'url' parameter")
    
    def do_POST(self):
        """Handle POST requests with JSON body"""
        content_length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_length)
        
        try:
            data = json.loads(body.decode('utf-8'))
            url = data.get('url')
            
            if url:
                self.open_browser(url)
            else:
                self.send_error(400, "Missing 'url' in JSON body")
        except json.JSONDecodeError:
            self.send_error(400, "Invalid JSON")
    
    def open_browser(self, url):
        """Open URL in default browser using macOS 'open' command"""
        try:
            # Validate URL format
            if not (url.startswith('http://') or url.startswith('https://')):
                url = 'http://' + url
            
            print(f"Opening URL: {url}")
            
            # Use macOS 'open' command to launch default browser
            result = subprocess.run(
                ['open', url],
                capture_output=True,
                text=True,
                timeout=5
            )
            
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
                print(f"Success: Opened {url}")
            else:
                self.send_error(500, f"Failed to open URL: {result.stderr}")
                print(f"Error: {result.stderr}")
                
        except subprocess.TimeoutExpired:
            self.send_error(500, "Timeout opening URL")
            print("Error: Timeout")
        except Exception as e:
            self.send_error(500, str(e))
            print(f"Error: {e}")

def run_server():
    server_address = ('', PORT)
    httpd = HTTPServer(server_address, BrowserLauncherHandler)
    
    print(f"Q-SYS Browser Launcher Service")
    print(f"===============================")
    print(f"Listening on: http://localhost:{PORT}")
    print(f"Access from Q-SYS: http://<mac-ip>:{PORT}?url=<device-url>")
    print(f"Press Ctrl+C to stop\n")
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down server...")
        httpd.shutdown()

if __name__ == '__main__':
    run_server()
