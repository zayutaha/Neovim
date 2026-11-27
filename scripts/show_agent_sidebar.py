"""Move an assistant terminal for approval and restore its prior layout."""

import base64
import json
import os
import subprocess
import sys
import tempfile


ASSISTANTS = {
    "claude": "configs.claude_window",
    "codex": "configs.codex_window",
}


def send_to_neovim(client, server, expression):
    subprocess.run(
        [client, "--server", server, "--remote-expr", f"luaeval({json.dumps(expression)})"],
        check=False,
        capture_output=True,
        timeout=5,
    )


def main():
    raw_input = sys.stdin.read()
    agent = sys.argv[1] if len(sys.argv) > 1 else ""
    action = sys.argv[2] if len(sys.argv) > 2 else "show"
    module = ASSISTANTS.get(agent)
    method = "restore_after_approval" if action == "restore" else "prepare_for_approval"
    client = os.environ.get("NVIM_CLIENT")
    server = os.environ.get("NVIM_SERVER")
    if not module or not client or not server:
        return

    if agent == "claude" and action == "walkthrough":
        payload = json.loads(raw_input)
        event = [
            payload.get("hook_event_name"),
            payload.get("session_id"),
            payload.get("cwd"),
        ]
        encoded = base64.b64encode(json.dumps(event).encode()).decode("ascii")
        send_to_neovim(client, server, (
            f"require('{module}').walkthrough_event("
            f"unpack(vim.json.decode(vim.base64.decode('{encoded}'))))"
        ))
        return

    expression = f"require('{module}').{method}"
    if agent == "codex" and action == "show":
        payload = json.loads(raw_input)
        if payload.get("tool_name") == "apply_patch":
            patch = payload.get("tool_input", {}).get("command")
            if isinstance(patch, str) and patch.startswith("*** Begin Patch"):
                with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8") as file:
                    file.write(patch)
                    file.flush()
                    send_to_neovim(client, server, f"{expression}({json.dumps(file.name)})")
                return
    send_to_neovim(client, server, f"{expression}()")


if __name__ == "__main__":
    try:
        main()
    except (OSError, subprocess.SubprocessError, json.JSONDecodeError):
        pass
