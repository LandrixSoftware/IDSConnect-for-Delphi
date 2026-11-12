"""Local HTTP regression tests. Requires Python 3 and dcc32 on PATH."""
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import subprocess
import tempfile
import threading
import re
import gzip


ROOT = Path(__file__).resolve().parents[1]
# XML library as git submodule (git submodule update --init)
XML_SOURCE = ROOT / 'Lib' / 'LandrixXML' / 'source'
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
    # "1252" in the content must not switch UTF-8 to a single-byte encoding
    '/utf8-1252': (200, ('<?xml version="1.0" encoding="UTF-8"?>'
                         + CART.replace('A&amp;B', 'B-1252 M\u00fcller')).encode('utf-8')),
    # Latin-1 declared, but UTF-8 bytes sent
    '/latin1-decl-utf8': (200, ('<?xml version="1.0" encoding="ISO-8859-1"?>'
                                + CART.replace('A&amp;B', 'Gr\u00fcn')).encode('utf-8')),
    # Tab after "=" in the declaration, Windows-1250 bytes
    '/decl-tab': (200, ('<?xml version="1.0" encoding=\t"windows-1250"?>'
                        + CART.replace('A&amp;B', '\u0141')).encode('cp1250')),
    # No declaration, Windows-1252 bytes
    '/cp1252-nodecl': (200, CART.replace('A&amp;B', 'Ma\u00dfband \u20ac').encode('cp1252')),
    # Namespace prefix on every element
    '/ns': (200, ('<ids:Warenkorb xmlns:ids="urn:ids"><ids:WarenkorbInfo>'
                  '<ids:Version>2.5.1</ids:Version></ids:WarenkorbInfo><ids:Order>'
                  '<ids:OrderInfo><ids:Cur>CHF</ids:Cur></ids:OrderInfo>'
                  '<ids:OrderItem><ids:ArtNo>NS1</ids:ArtNo><ids:Qty>3</ids:Qty>'
                  '<ids:QU>PCE</ids:QU></ids:OrderItem></ids:Order></ids:Warenkorb>').encode()),
    # Codes outside the code lists
    '/unknown-codes': (200, CART.replace('<QU>PCE</QU>',
                       '<QU>ROL</QU><Rohstoffanteil><Rohstoff>XX</Rohstoff></Rohstoffanteil>').encode()),
    # Text, CDATA and a comment in one element
    '/mixed-text': (200, CART.replace('<ArtNo>A&amp;B</ArtNo>',
                    '<ArtNo>ab<![CDATA[c&d]]><!--x-->e</ArtNo>').encode()),
}

# Hook server with a queue: every GET consumes the oldest return.
HEADER_CART = (
    '<Warenkorb><WarenkorbInfo><Version>2.5.1</Version></WarenkorbInfo>'
    '<Order><OrderInfo><Kommission>K-1</Kommission><Cur>CHF</Cur></OrderInfo>'
    '<SupplierInfo><Address><Name1>Lieferant</Name1></Address></SupplierInfo>'
    '<OrderItem><ArtNo>Q1</ArtNo><Qty>1</Qty><QU>PCE</QU></OrderItem>'
    '</Order></Warenkorb>'
)
QUEUE = [HEADER_CART.encode(), CART.replace('A&amp;B', 'Q2').encode()]
# Queue with transfer ids: two identical but separate transfers, then another
SAME = CART.replace('A&amp;B', 'S').encode()
ID_QUEUE = [(SAME, 'id-1'), (SAME, 'id-2'), (CART.replace('A&amp;B', 'T').encode(), 'id-3')]
# A server that delivers cyclically: A, B, A
CYCLE = [(CART.replace('A&amp;B', 'CA').encode(), 'c-a'),
         (CART.replace('A&amp;B', 'CB').encode(), 'c-b'),
         (CART.replace('A&amp;B', 'CA').encode(), 'c-a')]
# Mixed server: first with id, then the same return repeatedly without id
MIXED = [(CART.replace('A&amp;B', 'XA').encode(), 'x-a'),
         (CART.replace('A&amp;B', 'XB').encode(), None),
         (CART.replace('A&amp;B', 'XB').encode(), None)]
# More transfers than one CollectResults call may take
MANY = [(CART.replace('A&amp;B', f'M{i}').encode(), f'm-{i}') for i in range(120)]


class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        body = self.rfile.read(int(self.headers['Content-Length']))
        version = re.search(br'name="version"\r\n\r\n([^\r]+)', body)
        expected = b'2.5' if self.path == '/post25' else b'2.5.1'
        valid = version is not None and version.group(1) == expected
        if b'name="action"\r\n\r\nSV\r\n' in body:
            answer = '<Schnittstellenversionen><Version>2.5</Version></Schnittstellenversionen>'
        else:
            answer = '<Logininformationen/>'
        charset, payload = 'utf-8', answer.encode()
        if self.path == '/post-utf16':
            # charset only in the HTTP header, no BOM
            charset, payload = 'utf-16le', answer.encode('utf-16-le')
        compressed = (self.path == '/post-gzip'
                      and 'gzip' in (self.headers.get('Accept-Encoding') or ''))
        if compressed:
            payload = gzip.compress(payload)
        elif self.path == '/post-gzip':
            valid = False  # the client must offer gzip, otherwise the test proves nothing
        self.send_response(200 if valid else 400)
        self.send_header('Content-Type', f'text/xml; charset={charset}')
        if compressed:
            self.send_header('Content-Encoding', 'gzip')
        self.send_header('Content-Length', str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def do_GET(self):
        transfer_id = None
        if self.path == '/queue':
            status, body = (200, QUEUE.pop(0)) if QUEUE else (404, b'')
        elif self.path == '/sticky':
            status, body = 200, CART.encode()
        elif self.path == '/sticky-unknown':
            status, body = 200, CART.replace('<QU>PCE</QU>', '<QU>ROL</QU>').encode()
        elif self.path == '/sticky-id':
            status, body, transfer_id = 200, CART.encode(), 'same-id'
        elif self.path in ('/id-queue', '/many', '/cycle', '/mixed'):
            queue = {'/id-queue': ID_QUEUE, '/many': MANY, '/cycle': CYCLE,
                     '/mixed': MIXED}[self.path]
            if queue:
                (body, transfer_id), status = queue.pop(0), 200
            else:
                status, body = 404, b''
        else:
            status, body = RESPONSES[self.path]
        self.send_response(status)
        if transfer_id:
            self.send_header('X-IDSConnect-Id', transfer_id)
        self.send_header('Content-Type', 'text/xml')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *_args):
        pass


# The freshly built exe can stay locked briefly (virus scanner); a leftover
# temp folder must not turn a passed run into a failure.
with tempfile.TemporaryDirectory(prefix='idsconnect-tests-', ignore_cleanup_errors=True) as output:
    subprocess.run([
        'dcc32', '-B', f'-U{ROOT};{XML_SOURCE}', f'-I{XML_SOURCE}',
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
