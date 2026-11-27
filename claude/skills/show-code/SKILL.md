---
name: show-code
description: Build an in-editor code walkthrough in Neovim. Splits a diff (or a feature, or a file) into small highlighted snippets, each with a short explanation, that the user steps through with <leader>an / <leader>aN. Use when the user runs /show-code, asks to "walk me through" a diff/change/code, or asks to update a saved walkthrough.
argument-hint: "[diff target, e.g. HEAD~1, --staged, a branch, a file, or a topic]"
allowed-tools: Bash(python3 "$NVIM_SHOW_CODE":*), Bash(python3 *show_code.py:*), Bash(git diff:*), Bash(git show:*), Bash(git log:*), Bash(git status:*), Read, Grep, Glob
---

# Show code

You are running inside Neovim (claudecode.nvim). Neovim renders a walkthrough:
it opens each stop's file, highlights the line range, and shows your note in a
side pane. The user moves with `<leader>an` (next) / `<leader>aN` (previous),
`<leader>ae` toggles notes/chat, `<leader>aR` re-anchors a range. When this turn
ends, the walkthrough is saved and can be reopened from the saved-walkthrough picker.

Session id for this conversation: `${CLAUDE_SESSION_ID}`

## 1. Work out what to walk through

Target: `$ARGUMENTS`

- Empty → the working-tree diff (`git diff` plus `git diff --staged`; if both
  are empty, the last commit `git show HEAD`).
- A rev/range/branch/`--staged` → that diff.
- A path or topic → the relevant code (not a diff).

Read the diff, then **read the post-change files** for every hunk you'll cover.
Line numbers must refer to the file **as it is on disk now**. Diffs of deleted
code can't be highlighted: mention removals in the note of a nearby stop.

## 2. Design the stops

- One stop = one logical change. Merge adjacent hunks that serve one purpose;
  split one large hunk that does two things.
- Order the stops so they tell a story: entry point / core change first, then
  callers, wiring, config, tests.
- Skip noise: import-only changes, formatting, lockfiles, trivial renames
  (fold them into another note in one clause if they matter).
- Keep ranges tight (roughly 3–40 lines): the highlight should show exactly the
  code the note talks about.
- Aim for about 4–12 stops. Fewer for a small diff.

Each note is Markdown, roughly 2–6 sentences:
- **What** the code does now, in plain words.
- **Why** it changed or why it matters. Say so when the reason is inferred
  rather than evident.
- Optionally, one thing to watch for (an edge case, a risk, how it connects to
  the next stop).
Don't paste the code back into the note; it's already highlighted beside it.
`title` is a short label (≤ 6 words).

## 3. Send it to Neovim

Pipe a JSON array of stops into the helper (paths may be relative to the cwd):

```bash
python3 "$NVIM_SHOW_CODE" show ${CLAUDE_SESSION_ID} <<'JSON'
[
  {"file": "lua/configs/foo.lua", "first_line": 12, "last_line": 30,
   "title": "New cache lookup", "note": "Checks the cache before ..."},
  {"file": "lua/plugins/init.lua", "first_line": 85, "last_line": 96,
   "title": "Wiring it up", "note": "..."}
]
JSON
```

If it errors (for example, a range is outside the file), fix the stop and resend.
If `NVIM_SERVER` is unset, tell the user that the walkthrough only works when
Claude runs inside their Neovim, and give the walkthrough as text instead.

After it succeeds, reply with **one short line** only (e.g. "Walkthrough ready:
7 stops. `<leader>an` to step through."). Don't repeat the notes in chat.

## 4. Updating a saved walkthrough

When the user asks to fix or refresh stops, or after edits that touched
walkthrough code ("Use /show-code to update the affected saved walkthrough stops"):

```bash
python3 "$NVIM_SHOW_CODE" status ${CLAUDE_SESSION_ID}
```

This returns the tour `id` and each stop's current resolved range (`first_line`
is null if the anchor was lost). Re-read the files, then send only the changed
stops. `index` and `file` must match the saved stop:

```bash
python3 "$NVIM_SHOW_CODE" update ${CLAUDE_SESSION_ID} <id> <<'JSON'
[{"index": 2, "file": "lua/configs/foo.lua", "first_line": 14, "last_line": 33,
  "note": "Updated explanation ..."}]
JSON
```

To change which stops exist or their order, send a fresh walkthrough with `show`.
