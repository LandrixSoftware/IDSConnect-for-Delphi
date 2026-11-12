"""Regression tests for idsconnect.php. Requires Python 3 and php on PATH.

Runs the hook script on PHP's built-in server in a temporary directory and
checks the queue per sid: every transfer is kept, every GET delivers the
oldest one exactly once.
"""
from pathlib import Path
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


def free_port():
    with socket.socket() as s:
        s.bind(('127.0.0.1', 0))
        return s.getsockname()[1]


def request(base, sid, data=None):
    url = f'{base}/idsconnect.php?sid={sid}'
    body = None if data is None else urllib.parse.urlencode({'warenkorb': data}).encode()
    try:
        with urllib.request.urlopen(url, body, timeout=10) as res:
            LAST_ID[0] = res.headers.get('X-IDSConnect-Id')
            return res.status, res.read().decode()
    except urllib.error.HTTPError as e:
        LAST_ID[0] = None
        return e.code, ''


def check(value, message):
    if not value:
        raise SystemExit('FAIL: ' + message)


with tempfile.TemporaryDirectory(prefix='idsconnect-php-') as docroot:
    shutil.copy(ROOT / 'idsconnect.php', docroot)
    port = free_port()
    server = subprocess.Popen(['php', '-S', f'127.0.0.1:{port}', '-t', docroot],
                              cwd=docroot, stdout=subprocess.DEVNULL,
                              stderr=subprocess.DEVNULL)
    base = f'http://127.0.0.1:{port}'
    try:
        for _ in range(50):
            try:
                socket.create_connection(('127.0.0.1', port), timeout=0.2).close()
                break
            except OSError:
                time.sleep(0.1)

        check(request(base, '../etc/passwd')[0] == 400, 'invalid sid accepted')
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

        leftovers = list((Path(docroot) / 'idsconnect').iterdir())
        check(not leftovers, f'files left behind: {leftovers}')
    finally:
        server.terminate()
        server.wait(timeout=10)

print('PASS: hook queue keeps every transfer and delivers each exactly once')
