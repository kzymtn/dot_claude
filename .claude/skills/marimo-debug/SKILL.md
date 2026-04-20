# marimo-debug

Diagnose and fix errors in a **running** marimo notebook by inspecting its live state through the MCP server. Always query MCP first — never read source files to gather diagnostic information.

## When to Use

- User reports a cell error, traceback, or unexpected output in a running notebook
- User asks "why is this cell failing?" or "fix the bug in my notebook"
- Proactively: after generating or editing notebook cells, verify with MCP before declaring done

## Workflow

### Step 1 — Discover sessions

Call `get_active_notebooks`.

- If only one session exists, use it automatically.
- If multiple sessions exist, show the list (name + path) and ask the user which one to debug.
- If no sessions are active, inform the user that marimo must be running (`marimo edit <file>`) before MCP inspection is possible. Fall back to reading the source file directly.

### Step 2 — Collect all errors and lint issues

Call in parallel:
- `get_notebook_errors` with the session ID → full error summary per cell
- `lint_notebook` → marimo-specific structural issues (multiple definitions, import-star, cycles, etc.)

Summarize findings: total error count, affected cell IDs, lint warning count.

If there are no errors and no lint issues, report that the notebook is clean and stop.

### Step 3 — Deep-dive into errored cells

For each cell that has an error, call `get_cell_runtime_data` with `cell_ids` = [errored cell IDs].

Extract from the response:
- Full cell source code
- Error type and message
- Full traceback
- Variables defined by the cell (to understand side-effects)

### Step 4 — Trace upstream dependencies

Call `get_cell_dependency_graph` with the session ID and set `cell_id` to the first errored cell, `depth` = 3 (or more if needed).

Look for:
- Parent cells that define variables referenced by the errored cell
- Whether any parent is itself in an error or stale state (`get_cell_runtime_data` on parents if unclear)
- Multiply-defined variables that could cause shadowing
- Cycles that block execution

### Step 5 — Root-cause analysis

Synthesize the information collected in steps 2-4:

1. Is the error caused by the cell itself (logic bug, missing import, wrong API call)?
2. Is it caused by a variable from an upstream cell being `None`, wrong type, or undefined?
3. Is it a marimo structural issue (multiple definition, import star, cycle)?
4. Is it an environment issue (missing package, wrong Python version)?

State the root cause explicitly before proposing any fix.

### Step 6 — Propose and apply fixes

Once the root cause is identified:

1. Describe the fix in plain language.
2. Show the corrected code snippet.
3. Apply the fix to the source `.py` file using the `Edit` tool (follow `marimo-notebook` skill conventions).
4. Remind the user to save/reload if the notebook is running with `--watch` or to re-run the affected cell.

## Rules

- **Never read source files to diagnose errors** — always use MCP inspection first. File reads are only allowed when applying a fix.
- When calling `get_cell_runtime_data`, batch multiple cell IDs in a single call rather than calling one-by-one.
- If `get_active_notebooks` returns an empty list, tell the user explicitly and offer to inspect the source file statically instead.
- Always call `get_marimo_rules` before writing any fix code if you are unsure about marimo-specific constraints (e.g., how to handle state, output, reactivity).
- Do not modify cells that are working correctly even if you think they could be improved — scope is bug fixes only unless the user asks for more.

## Example Session Outline

```
1. get_active_notebooks
   → session_id = "abc123", notebook = "analysis.py"

2. get_notebook_errors(session_id="abc123")
   → cell_id="cell-5" has NameError: name 'df' is not defined

3. lint_notebook(session_id="abc123")
   → no lint issues

4. get_cell_runtime_data(session_id="abc123", cell_ids=["cell-5"])
   → source: "result = df.groupby('category').sum()"
   → error: NameError: name 'df' is not defined

5. get_cell_dependency_graph(session_id="abc123", cell_id="cell-5", depth=2)
   → cell-3 defines 'df', but cell-3 runtime_state = "stale"

Root cause: cell-3 (which loads df) is stale and has not been executed.
Fix: ensure cell-3 runs before cell-5, or check why cell-3 is stale.
```
