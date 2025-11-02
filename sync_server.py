# ~/Desktop/Oud_SmartShop/smartshoplist_v140/sync_server.py
from http.server import BaseHTTPRequestHandler, HTTPServer
import json, os

DATA_FILE = "sync_data.json"

class SyncHandler(BaseHTTPRequestHandler):
    def _set_headers(self, code=200, ctype="application/json"):
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()

    def do_OPTIONS(self):
        self._set_headers()

    def do_GET(self):
        self._set_headers()
        if os.path.exists(DATA_FILE):
            with open(DATA_FILE, "rb") as f:
                self.wfile.write(f.read())
        else:
            self.wfile.write(b"{}")

    def do_POST(self):
        # NB: we vertrouwen de app; read-only voor andere clients is in de UI afgedwongen.
        length = int(self.headers.get("Content-Length", "0"))
        body = self.rfile.read(length) if length else b"{}"
        try:
            # valide JSON?
            json.loads(body.decode("utf-8") or "{}")
        except Exception:
            self._set_headers(400)
            self.wfile.write(b'{"error":"invalid json"}')
            return
        with open(DATA_FILE, "wb") as f:
            f.write(body)
        self._set_headers(200)
        self.wfile.write(b'{"ok":true}')

if __name__ == "__main__":
    print("LAN Sync Server actief op http://0.0.0.0:9000/sync")
    HTTPServer(("0.0.0.0", 9000), SyncHandler).serve_forever()
