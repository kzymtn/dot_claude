#!/usr/bin/env python3
"""
get_cells.py - marimo notebook のセル一覧をフルコード付きの JSON で返す。

marimo-cell-edit --list-cells は表示を 60 文字で切り詰めるため、
Claude がプログラム的にセル内容を把握するにはこのスクリプトを使う。

Usage:
  python get_cells.py [--port PORT] [--host HOST] [--file FILE]

Options:
  --port PORT   marimo server port (default: auto-detect from registry)
  --host HOST   marimo server host (default: auto-detect from registry)
  --file FILE   Match session by notebook file path (when multiple sessions)

Output (stdout, JSON):
  {
    "base_url": "http://127.0.0.1:2721",
    "session_id": "s_abc123",
    "notebook_path": "/path/to/notebook.py",
    "cells": [
      {"cell_id": "Hbol", "name": "imports", "code": "import marimo as mo\\n..."},
      ...
    ]
  }

Exit codes:
  0  success
  1  error (details on stderr)
"""

import argparse
import ast
import json
import re
import sys
import textwrap
import urllib.error
import urllib.request
from pathlib import Path


# ---------------------------------------------------------------------------
# Server discovery (same logic as ~/bin/marimo-cell-edit)
# ---------------------------------------------------------------------------

def find_server() -> tuple[str, int]:
    """Find running marimo server from the registry file."""
    registry_dir = Path.home() / ".local" / "state" / "marimo" / "servers"
    if not registry_dir.exists():
        raise RuntimeError(
            "No marimo server registry found at ~/.local/state/marimo/servers/\n"
            "Start marimo with: uvx marimo edit --no-token --no-skew-protection <notebook.py>"
        )
    servers = sorted(registry_dir.glob("*.json"), key=lambda p: p.stat().st_mtime, reverse=True)
    if not servers:
        raise RuntimeError("No running marimo server found in registry.")
    data = json.loads(servers[0].read_text())
    return data["host"], data["port"]


# ---------------------------------------------------------------------------
# HTTP helpers
# ---------------------------------------------------------------------------

def http_get(url: str) -> dict:
    req = urllib.request.Request(url, headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        raise RuntimeError(f"HTTP {e.code} {e.reason}: {body}") from e


def resolve_session(sessions: dict, file_filter: str | None) -> tuple[str, str]:
    """Returns (session_id, notebook_path)."""
    if not sessions:
        raise RuntimeError("No active sessions. Is marimo running?")
    if file_filter:
        for sid, info in sessions.items():
            path = info.get("filename", "") or info.get("path", "")
            if file_filter in path:
                return sid, path
        raise RuntimeError(
            f"No session found for file matching '{file_filter}'.\n"
            f"Active sessions: {list(sessions.values())}"
        )
    if len(sessions) > 1:
        session_list = "\n".join(
            f"  {sid}: {info.get('filename', '?')}" for sid, info in sessions.items()
        )
        raise RuntimeError(
            f"Multiple sessions active. Use --file to select one:\n{session_list}"
        )
    sid = next(iter(sessions))
    path = sessions[sid].get("filename", "") or sessions[sid].get("path", "")
    return sid, path


# ---------------------------------------------------------------------------
# Cell parsing (same logic as ~/bin/marimo-cell-edit)
# ---------------------------------------------------------------------------

def _compute_marimo_internal_ids(n: int) -> list[str]:
    """Reproduce marimo's deterministic cell ID generation (seed=42)."""
    import random as _random
    import string as _string
    r = _random.Random(42)
    seen: set[str] = set()
    ids: list[str] = []
    while len(ids) < n:
        _id = "".join(r.choices(_string.ascii_letters, k=4))
        if _id not in seen:
            seen.add(_id)
            ids.append(_id)
    return ids


def parse_cells(notebook_path: str) -> list[dict]:
    """
    Parse a marimo .py notebook and return cells as:
      [{"cell_id": <internal_id>, "name": <func_name>, "code": <body>}, ...]
    """
    src = Path(notebook_path).read_text()

    pattern = re.compile(
        r"@app\.cell(?:\([^)]*\))?\s*\n"
        r"def\s+(\w+)\s*\(",
        re.MULTILINE,
    )

    # Extract function bodies via AST
    func_bodies: dict[str, str] = {}
    try:
        tree = ast.parse(src)
        src_lines = src.splitlines()
        for node in ast.walk(tree):
            if isinstance(node, ast.FunctionDef):
                body_start = node.body[0].lineno - 1
                last_child = node.body[-1]
                body_end = (
                    last_child.end_lineno
                    if hasattr(last_child, "end_lineno")
                    else last_child.lineno
                )
                body_lines = src_lines[body_start:body_end]
                # Strip trailing return statements added by marimo
                while body_lines and re.match(r"^\s*return\b", body_lines[-1]):
                    body_lines.pop()
                func_bodies[node.name] = textwrap.dedent("\n".join(body_lines))
    except SyntaxError:
        pass

    func_names = [m.group(1) for m in pattern.finditer(src)]
    internal_ids = _compute_marimo_internal_ids(len(func_names))

    return [
        {
            "cell_id": internal_ids[idx],
            "name": func_name,
            "code": func_bodies.get(func_name, ""),
        }
        for idx, func_name in enumerate(func_names)
    ]


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> int:
    parser = argparse.ArgumentParser(
        description="Return marimo notebook cell list as JSON (full code, no truncation).",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument("--port", type=int, help="marimo server port (default: auto-detect)")
    parser.add_argument("--host", default=None, help="marimo server host (default: auto-detect)")
    parser.add_argument("--file", help="Match session by notebook filename")
    args = parser.parse_args()

    try:
        if args.port:
            host = args.host or "127.0.0.1"
            port = args.port
        else:
            host, port = find_server()
        base_url = f"http://{host}:{port}"

        sessions = http_get(f"{base_url}/api/sessions")
        session_id, notebook_path = resolve_session(sessions, args.file)

        cells: list[dict] = []
        if notebook_path:
            cells = parse_cells(notebook_path)

        result = {
            "base_url": base_url,
            "session_id": session_id,
            "notebook_path": notebook_path or "",
            "cells": cells,
        }
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return 0

    except RuntimeError as e:
        print(f"error: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
