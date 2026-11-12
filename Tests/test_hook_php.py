"""Regression tests for idsconnect.php. Requires Python 3 and php on PATH.

Runs the hook script on PHP's built-in server in a temporary directory and
checks the queue per sid: every transfer is kept, every GET delivers the
oldest one exactly once. Also: storage outside the script folder, writing
only per POST, safe headers on delivery, total size limit.
"""
from pathlib import Path
import os
import shutil
import socket
import subprocess
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request


ROOT = Path(__file__).resolve().parents[1]
SID = '0123abcd-0000-4000-8000-00000000abcd'
LAST_ID = [None]
LAST_HEADERS = [None]


def free_port():
    with socket.socket() as s:
        s.bind(('127.0.0.1', 0))
        return s.getsockname()[1]


def request(base, sid, data=None, query=''):
    url = f'{base}/idsconnect.php?sid={sid}{query}'
    body = None if data is None else urllib.parse.urlencode({'warenkorb': data}).encode()
    try:
        with urllib.request.urlopen(url, body, timeout=10) as res:
            LAST_ID[0] = res.headers.get('X-IDSConnect-Id')
            LAST_HEADERS[0] = res.headers
            return res.status, res.read().decode()
    except urllib.error.HTTPError as e:
        LAST_ID[0] = None
        LAST_HEADERS[0] = None
        return e.code, ''


def start_server(docroot, env=None):
    port = free_port()
    # Never inherit a live storage configuration from the calling shell
    full_env = {k: v for k, v in os.environ.items()
                if k not in ('IDSCONNECT_DIR', 'IDSCONNECT_MAX_TOTAL')}
    full_env.update(env or {})
    server = subprocess.Popen(['php', '-S', f'127.0.0.1:{port}', '-t', docroot],
                              cwd=docroot, env=full_env, stdout=subprocess.DEVNULL,
                              stderr=subprocess.DEVNULL)
    for _ in range(50):
        try:
            socket.create_connection(('127.0.0.1', port), timeout=0.2).close()
            break
        except OSError:
            time.sleep(0.1)
    return server, f'http://127.0.0.1:{port}'


def check(value, message):
    if not value:
        raise SystemExit('FAIL: ' + message)


with tempfile.TemporaryDirectory(prefix='idsconnect-php-') as tmp:
    # The script lives in <tmp>/www (the "webroot"); storage goes next to it
    docroot = os.path.join(tmp, 'www')
    os.mkdir(docroot)
    shutil.copy(ROOT / 'idsconnect.php', docroot)
    data_dir = Path(tmp) / 'idsconnect-data'
    server, base = start_server(docroot)
    try:
        check(request(base, '../etc/passwd')[0] == 400, 'invalid sid accepted')
        check(request(base, SID + '%0A', '<Warenkorb>n</Warenkorb>')[0] == 400,
              'sid with trailing newline accepted')
        check(request(base, SID)[0] == 404, 'empty queue did not answer 404')

        # Two transfers before the first fetch: both must survive, in order
        check(request(base, SID, '<Warenkorb>1</Warenkorb>')[0] == 200, 'first POST failed')
        check(request(base, SID, '<Warenkorb>2</Warenkorb>')[0] == 200, 'second POST failed')
        check(request(base, SID.upper()) == (200, '<Warenkorb>1</Warenkorb>'), 'first return missing')
        check(request(base, SID) == (200, '<Warenkorb>2</Warenkorb>'), 'second return missing')
        check(request(base, SID)[0] == 404, 'return delivered twice')

        # Identical content in two transfers: two deliveries with distinct ids
        request(base, SID, '<Warenkorb>same</Warenkorb>')
        request(base, SID, '<Warenkorb>same</Warenkorb>')
        check(request(base, SID)[1] == '<Warenkorb>same</Warenkorb>', 'first identical missing')
        first_id = LAST_ID[0]
        check(request(base, SID)[1] == '<Warenkorb>same</Warenkorb>', 'second identical missing')
        check(first_id and LAST_ID[0] and first_id != LAST_ID[0], 'transfer ids missing or equal')

        # Other sessions are not affected
        other = SID.replace('abcd', 'ef01')
        request(base, other, '<Warenkorb>x</Warenkorb>')
        check(request(base, SID)[0] == 404, 'return leaked between sessions')
        check(request(base, other)[1] == '<Warenkorb>x</Warenkorb>', 'other session lost')

        # Delivery of stored content: no sniffing, no script, no caching
        request(base, SID, '<Warenkorb>h</Warenkorb>')
        check(request(base, SID)[0] == 200, 'header check return missing')
        h = LAST_HEADERS[0]
        check(h.get('X-Content-Type-Options') == 'nosniff', 'nosniff missing')
        check('sandbox' in (h.get('Content-Security-Policy') or ''), 'CSP sandbox missing')
        check(h.get('Cache-Control') == 'no-store', 'no-store missing')

        # GET with ?warenkorb=... must not store anything
        check(request(base, SID, query='&warenkorb=%3Cx%2F%3E')[0] == 404, 'GET treated as transfer')
        check(request(base, SID)[0] == 404, 'GET stored a transfer')

        check(data_dir.is_dir(), 'storage not created next to the script folder')
        check(not (Path(docroot) / 'idsconnect').exists(), 'storage created inside the webroot')
        # Protection files in every storage folder (nested deployments)
        check('Require all denied' in (data_dir / '.htaccess').read_text(), 'htaccess missing')
        check((data_dir / 'index.html').exists(), 'index.html missing')
        leftovers = [x.name for x in data_dir.iterdir() if '.dat' in x.name]
        check(not leftovers, f'files left behind: {leftovers}')
    finally:
        server.terminate()
        server.wait(timeout=10)

    # Total size limit and IDSCONNECT_DIR, configured per environment. The
    # brackets in the folder name must not act as a glob pattern.
    custom = Path(tmp) / 'custom[1]'
    server, base = start_server(docroot, {'IDSCONNECT_DIR': str(custom),
                                          'IDSCONNECT_MAX_TOTAL': '10000'})
    try:
        check(request(base, SID, 'a' * 6000)[0] == 200, 'POST below the limit failed')
        check(request(base, SID, 'b' * 6000)[0] == 507, 'total size limit not enforced')
        check(request(base, SID) == (200, 'a' * 6000), 'stored return missing in IDSCONNECT_DIR')
        check(request(base, SID, 'c' * 6000)[0] == 200, 'space not released after delivery')
        check(len([x for x in custom.iterdir() if x.name.endswith('.dat')]) == 1,
              'IDSCONNECT_DIR not used')
        check(request(base, SID)[0] == 200, 'second delivery failed')
        # Empty transfers count with a minimum size, otherwise unlimited files
        check(request(base, SID, '')[0] == 200, 'first empty POST failed')
        check(request(base, SID, '')[0] == 200, 'second empty POST failed')
        check(request(base, SID, '')[0] == 507, 'empty files not counted against the limit')
    finally:
        server.terminate()
        server.wait(timeout=10)

# Fallback: storage next to the script folder not possible (a file blocks
# the name) -> folder inside the script folder, protected for Apache
with tempfile.TemporaryDirectory(prefix='idsconnect-php-') as tmp:
    docroot = os.path.join(tmp, 'www')
    os.mkdir(docroot)
    shutil.copy(ROOT / 'idsconnect.php', docroot)
    Path(tmp, 'idsconnect-data').write_text('blocker')
    server, base = start_server(docroot)
    try:
        check(request(base, SID, '<Warenkorb>f</Warenkorb>')[0] == 200, 'fallback POST failed')
        inside = Path(docroot) / 'idsconnect'
        htaccess = (inside / '.htaccess').read_text()
        check('Require all denied' in htaccess and 'Deny from all' in htaccess, 'htaccess missing')
        check((inside / 'index.html').exists(), 'index.html missing')
        check(request(base, SID) == (200, '<Warenkorb>f</Warenkorb>'), 'fallback return missing')
        # Cleanup must not remove the protection files
        check(not [x.name for x in inside.iterdir() if '.dat' in x.name],
              'files left behind in fallback folder')
    finally:
        server.terminate()
        server.wait(timeout=10)

print('PASS: hook queue keeps every transfer and delivers each exactly once')
print('PASS: storage outside the webroot, POST only, safe headers, total size limit')
