"""Local HTTP regression tests. Requires Python 3 and dcc32 on PATH."""
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import subprocess
import tempfile
import threading
import re


ROOT = Path(__file__).resolve().parents[1]
CART = (
    '<Warenkorb><WarenkorbInfo><Version>2.5.1</Version></WarenkorbInfo>'
    '<Order><OrderItem><ArtNo>A&amp;B</ArtNo><Qty>2.5</Qty><QU>PCE</QU>'
    '</OrderItem></Order></Warenkorb>'
)
RESPONSES = {
    '/valid': (200, CART.encode()),
    '/invalid': (200, b'<Warenkorb>'),
    '/html': (200, b'<html><body>Login required</body></html>'),
    '/error': (500, b'mock error'),
    '/pending': (404, b''),
    '/empty': (200, b''),
    '/latin1': (200, ('<?xml version="1.0" encoding="ISO-8859-1"?>'
                     + CART.replace('A&amp;B', 'Caf\u00e9') + '<!--\u00e9-->').encode('latin1')),
}


class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        body = self.rfile.read(int(self.headers['Content-Length']))
        version = re.search(br'name="version"\r\n\r\n([^\r]+)', body)
        expected = b'2.5' if self.path == '/post25' else b'2.5.1'
        valid = version is not None and version.group(1) == expected
        self.send_response(200 if valid else 400)
        self.send_header('Content-Type', 'text/xml; charset=utf-8')
        self.end_headers()
        if b'name="action"\r\n\r\nSV\r\n' in body:
            self.wfile.write(b'<Schnittstellenversionen><Version>2.5</Version></Schnittstellenversionen>')
        else:
            self.wfile.write(b'<Logininformationen/>')

    def do_GET(self):
        status, body = RESPONSES[self.path]
        self.send_response(status)
        self.send_header('Content-Type', 'text/xml')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *_args):
        pass


with tempfile.TemporaryDirectory(prefix='idsconnect-tests-') as output:
    subprocess.run([
        'dcc32', '-B', f'-U{ROOT}',
        '-NSSystem;Xml;Data;Datasnap;Web;Soap;Vcl;Winapi',
        f'-E{output}', f'-N0{output}', 'IDSConnectDiagnosticsTests.dpr',
    ], cwd=ROOT / 'Tests', check=True)
    server = ThreadingHTTPServer(('127.0.0.1', 0), Handler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    try:
        subprocess.run([
            str(Path(output) / 'IDSConnectDiagnosticsTests.exe'),
            f'http://127.0.0.1:{server.server_port}',
        ], check=True, timeout=60)
    finally:
        server.shutdown()
        server.server_close()
        thread.join()
