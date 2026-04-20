# marimo-inspect

Get a comprehensive snapshot of a **running** marimo notebook's current state — cell structure, runtime states, outputs, and live variable values — entirely through MCP without touching source files.

## When to Use

- User asks "what is this notebook doing?" or "show me the current state of the notebook"
- Before editing a running notebook (use as a prerequisite step to understand live state)
- When `marimo-debug` or `marimo-data-explore` need initial context
- When the user wants to understand outputs without opening the browser UI

## Workflow

### Step 1 — Discover sessions

Call `get_active_notebooks`.

- Single session: proceed automatically.
- Multiple sessions: list them (name + path + session ID) and ask the user which to inspect.
- No sessions: inform the user that marimo must be running and stop.

### Step 2 — Get cell map overview

Call `get_lightweight_cell_map` with the session ID. Use default `preview_lines` (3) unless the user requests more detail.

From the response, build an overview table:

| # | Cell ID | Type | Runtime State | Lines | Has Output | Preview |
|---|---------|------|---------------|-------|------------|---------|
| 1 | cell-1  | code | idle          | 5     | yes        | `import pandas...` |

Cell types: `code`, `markdown`, `sql`
Runtime states: `idle` (clean), `running`, `queued`, `stale` (needs re-run), `stopped`, `disabled`

Highlight any cells in `stale`, `running`, or error states.

### Step 3 — Fetch outputs for cells with output

From the cell map, collect all cell IDs where `has_output = true` or `has_console_output = true`.

Call `get_cell_outputs` with those cell IDs (batch in a single call).

For each cell, summarize:
- Output mimetype (e.g., `text/html`, `application/vnd.marimo+mimetype`, `image/png`)
- For `text/plain` or `text/html`: show a trimmed preview (first 200 chars)
- For charts/images: note "visual output (chart/image)"
- Any stdout or stderr messages

### Step 4 — Get variable and table state

Call `get_tables_and_variables` with `variable_names = []` (all variables).

Organize the results into two sections:

**Data Tables** (DataFrames, SQL result sets):
- Name, row count, column names and types

**Other Variables** (scalars, lists, dicts, models, etc.):
- Name, Python type, value preview (truncated if large)

### Step 5 — Present structured summary

Output a concise report with four sections:

```
## Notebook: <name> (<path>)
Session: <session_id>

### Cell Overview
<table from step 2>
Stale cells: <list>  |  Error cells: <list>

### Outputs Summary
<per-cell output summaries from step 3>

### Variables & Data
<tables from step 4>

### Notes
- <any unusual states, e.g., cycles, multiply-defined variables>
```

## Rules

- This skill is **read-only** — never edit source files.
- Batch all `get_cell_outputs` calls into one request with multiple cell IDs.
- Truncate large output strings to keep the summary readable (200 chars per cell).
- If the cell map has more than 20 cells, only fetch outputs for cells that have output or are in an error/stale state.
- When used as a prerequisite by another skill (e.g., `marimo-debug`, `marimo-data-explore`), return the structured data directly rather than printing a formatted report.

## Typical Use

```
User: "What is my analysis notebook currently doing?"

1. get_active_notebooks → "analysis.py", session "abc123"
2. get_lightweight_cell_map → 8 cells: 6 idle, 1 stale, 1 running
3. get_cell_outputs(cell_ids=[cells with output])
4. get_tables_and_variables(variable_names=[])

Report:
- 8 cells total; cell-6 is stale, cell-7 is still running
- cell-3 output: DataFrame with 1,024 rows (revenue by month)
- cell-5 output: bar chart (image/png)
- Variables: df_raw (DataFrame 10,000×12), model (sklearn Pipeline), threshold (float 0.75)
```
