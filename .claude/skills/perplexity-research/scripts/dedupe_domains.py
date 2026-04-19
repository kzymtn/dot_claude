#!/usr/bin/env python3
"""
Domain-level deduplication for URL lists.
Usage:
  echo "https://example.com/page1\nhttps://example.com/page2\nhttps://other.com/x" | python3 dedupe_domains.py
  python3 dedupe_domains.py < urls.txt
Output: one URL per domain (first occurrence wins), printed to stdout.
"""
import sys
from urllib.parse import urlparse

seen: set[str] = set()
for line in sys.stdin:
    url = line.strip()
    if not url:
        continue
    domain = urlparse(url).netloc.removeprefix("www.")
    if domain not in seen:
        seen.add(domain)
        print(url)
