"""Send a /show-code walkthrough to the Neovim instance hosting Claude.

Usage:
  show_code.py show   <session_id>       < stops.json   # [{file, first_line, last_line, title?, note}]
  show_code.py status <session_id>
  show_code.py update <session_id> <id>  < updates.json # [{index, file, first_line, last_line, title?, note}]
"""

import base64
import json
import os
import secrets
import subprocess
import sys

MODULE = "configs.claude_window"


def call(expression):
    client = os.environ.get("NVIM_CLIENT")
    server = os.environ.get("NVIM_SERVER")
    if not client or not server:
        sys.exit("NVIM_SERVER/NVIM_CLIENT are not set: Claude is not running inside Neovim.")
    result = subprocess.run(
        [client, "--server", server, "--remote-expr", f"luaeval({json.dumps(expression)})"],
        capture_output=True, text=True, timeout=10,
    )
    out = (result.stdout + result.stderr).strip()
    if result.returncode != 0 or result.stderr.strip() or out.startswith(("Lua:", "E5108")):
        sys.exit(out or "Neovim call failed")
    return out


def encoded(value):
    return base64.b64encode(json.dumps(value).encode()).decode("ascii")


def absolute(items):
    for item in items:
        item["file"] = os.path.abspath(item["file"])
        item["first_line"] = int(item["first_line"])
        item["last_line"] = int(item.get("last_line", item["first_line"]))
        if not str(item.get("note", "")).strip():
            sys.exit(f"Stop for {item['file']} is missing a note")
    return items


def main():
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    action, session = sys.argv[1], sys.argv[2]
    if action == "show":
        stops = absolute(json.load(sys.stdin))
        tour_id = secrets.token_hex(8)
        call(f"require('{MODULE}').show_code_tour(vim.json.decode(vim.base64.decode('{encoded(stops)}')), "
             f"'{tour_id}', {json.dumps(session)})")
        print(f"ok: walkthrough {tour_id} with {len(stops)} stops opened")
    elif action == "status":
        print(call(f"require('{MODULE}').code_tour_status({json.dumps(session)})"))
    elif action == "update":
        tour_id = sys.argv[3]
        updates = absolute(json.load(sys.stdin))
        print(call(f"require('{MODULE}').update_code_tour({json.dumps(session)}, {json.dumps(tour_id)}, "
                   f"vim.json.decode(vim.base64.decode('{encoded(updates)}')))"))
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()
