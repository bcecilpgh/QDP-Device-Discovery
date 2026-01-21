"""
Q-SYS Browser Launcher Service for Windows
Listens for HTTP requests from Q-SYS and opens URLs in default browser

Usage:
    python qsys_browser_launcher_windows.py [port]
    
Default port: 8765

Requirements:
    - Python 3.6 or later
    - No additional packages required (uses standard library)
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
import subprocess
import sys
import json
import os

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
        """Open URL in default browser using Windows start command"""
        try:
            # Validate URL format
            if not (url.startswith('http://') or url.startswith('https://')):
                url = 'http://' + url
            
            print(f"Opening URL: {url}")
            
            # Use os.startfile() which is Windows-specific and works reliably
            os.startfile(url)
            
            # Send success response
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
                
        except Exception as e:
            self.send_error(500, str(e))
            print(f"Error: {e}")

def run_server():
    server_address = ('', PORT)
    httpd = HTTPServer(server_address, BrowserLauncherHandler)
    
    print(f"Q-SYS Browser Launcher Service for Windows")
    print(f"===========================================")
    print(f"Listening on: http://localhost:{PORT}")
    print(f"Access from Q-SYS: http://<pc-ip>:{PORT}?url=<device-url>")
    print(f"Press Ctrl+C to stop\n")
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down server...")
        httpd.shutdown()

if __name__ == '__main__':
    run_server()
