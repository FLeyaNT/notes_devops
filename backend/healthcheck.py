import json
import sys
import urllib.request

URL = 'http://127.0.0.1:8000/api/health'

try:
    with urllib.request.urlopen(URL, timeout=2) as r:
        body = json.load(r)
        ok = r.status == 200 and body.get('db') is True
except Exception as e:
    print(f'healthcheck failed: {e}', file=sys.stderr)
    sys.exit(1)

if not ok:
    print(f'unhealthy response: {body}', file=sys.stderr)
    sys.exit(1)
