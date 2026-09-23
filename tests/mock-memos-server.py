#!/usr/bin/env python3
"""A small stand-in for a UseMemos server, for manual tests of the widget.

It serves the two API calls that Memos ToDo uses:
    GET   /api/v1/memos/<id>
    PATCH /api/v1/memos/<id>   body: {"content": "..."}
and a plain page at /memos/<id> for "Open in Browser".

Usage: tests/mock-memos-server.py [PORT]
Then set the widget to Server URL http://127.0.0.1:PORT, token "test-token",
memo ID 1. Each request is logged to stdout.
"""
import json
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

TOKEN = "test-token"
MEMOS = {
    "1": "Shopping for the weekend\n"
         "☑ Do a little dance\n"
         "☑ Make a little love\n"
         "☐ Get down tonight\n"
         "☐ A task with a long description that has to wrap onto more than one line in the popup\n"
         "a note that belongs to the task above\n"
         "☐ Buy milk",
}


class Handler(BaseHTTPRequestHandler):
    def _memo_id(self, prefix):
        return self.path[len(prefix):].split("?")[0] if self.path.startswith(prefix) else None

    def _send(self, status, body, content_type="application/json"):
        data = body.encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", content_type + "; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def _authorized(self):
        return self.headers.get("Authorization") == "Bearer " + TOKEN

    def do_GET(self):
        memo_id = self._memo_id("/api/v1/memos/")
        if memo_id is not None:
            if not self._authorized():
                return self._send(401, '{"message":"unauthorized"}')
            if memo_id not in MEMOS:
                return self._send(404, '{"message":"not found"}')
            return self._send(200, json.dumps({"name": "memos/" + memo_id, "content": MEMOS[memo_id]}))
        memo_id = self._memo_id("/memos/")
        if memo_id is not None and memo_id in MEMOS:
            return self._send(200, "<pre>" + MEMOS[memo_id] + "</pre>", "text/html")
        self._send(404, '{"message":"not found"}')

    def do_PATCH(self):
        memo_id = self._memo_id("/api/v1/memos/")
        if memo_id is None:
            return self._send(404, '{"message":"not found"}')
        if not self._authorized():
            return self._send(401, '{"message":"unauthorized"}')
        length = int(self.headers.get("Content-Length") or 0)
        try:
            body = json.loads(self.rfile.read(length) or b"{}")
        except json.JSONDecodeError:
            return self._send(400, '{"message":"bad json"}')
        MEMOS[memo_id] = body.get("content", "")
        print("--- memo", memo_id, "is now:\n" + MEMOS[memo_id] + "\n---", flush=True)
        self._send(200, json.dumps({"name": "memos/" + memo_id, "content": MEMOS[memo_id]}))


if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 5230
    print(f"Mock Memos server on http://127.0.0.1:{port}, token {TOKEN!r}", flush=True)
    ThreadingHTTPServer(("127.0.0.1", port), Handler).serve_forever()
