#!/usr/bin/env bash
# Serve builds/html5 with the COOP/COEP headers Godot 4 Web needs for
# SharedArrayBuffer / cross-origin isolation.
#
# Usage (from repo root, after export_web.sh):
#   bash scripts/serve_web.sh            # http://127.0.0.1:8080
#   PORT=9090 bash scripts/serve_web.sh

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIR="${WEB_ROOT:-$ROOT/builds/html5}"
PORT="${PORT:-8080}"

if [ ! -f "$DIR/index.html" ]; then
  echo "No $DIR/index.html — run: bash scripts/export_web.sh" >&2
  exit 1
fi

echo "Serving Periliminal Web build at http://127.0.0.1:${PORT}/"
echo "  root: $DIR"
echo "  (Play Offline → Play Prototype Spine)"
echo "Ctrl+C to stop."

exec python3 - "$DIR" "$PORT" <<'PY'
import http.server, socketserver, sys, os

root, port = sys.argv[1], int(sys.argv[2])
os.chdir(root)

class Handler(http.server.SimpleHTTPRequestHandler):
    extensions_map = {
        **getattr(http.server.SimpleHTTPRequestHandler, "extensions_map", {}),
        ".wasm": "application/wasm",
        ".pck": "application/octet-stream",
        ".js": "application/javascript",
        ".json": "application/json",
        ".html": "text/html",
        ".png": "image/png",
    }

    def end_headers(self):
        # Required for Godot 4 threaded Web builds / SharedArrayBuffer.
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cross-Origin-Resource-Policy", "same-origin")
        super().end_headers()

with socketserver.TCPServer(("0.0.0.0", port), Handler) as httpd:
    httpd.serve_forever()
PY
